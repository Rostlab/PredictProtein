#!/usr/bin/perl -w

#============================================================
# combine CHOP and CHOPnet to generate domain prediction
#===============================================================

use lib 'DIRLIB';
use Getopt::Long;
use Storable;
use Data::Dumper;
use File::Copy;
use libChopper;


&ini();
($id_from_seq,$seq_len,$seq) = &get_seq_info($opt{'file_in'});
if ( ! $opt{'id'} ) {
    $prot_id = $id_from_seq;
} else {
    $prot_id = $opt{'id'};
}

if ( ! $prot_id ) {
    print STDERR "*** ERROR: protein ID not defined, and can't be retrieved from the sequence\n";
    exit(1);
}

$protein->{'proteinID'} = $prot_id;
$protein->{'length'} = $seq_len;

if ( $seq_len < $opt{'min_seqlen'} ) {
    print STDERR 
	"*** WARNING: input protein length is shorter than $opt{'min_seqlen'},\n",
	"no prediction will be run, output single domain\n";
    %domain = ( 'domainStart' => 1,
		'domainEnd'  => $seq_len,
		'source' => 'NULL',
		);
    push @{$protein->{'domains'}},{%domain};
    &format_output($protein,$opt{'format_out'});
    exit(0);
}


$pred_chop = {};
if ( $opt{'runChop'} ) {
    $file_chop = $opt{dir_tmp}.$id.'.chop_storable';
    $file_chop_xml = $file_chop.'.xml';
    $opt_chop_str .= " -of storable ";
    $cmd_chop = "$scr_chop $opt_chop_str -i $opt{file_in} -o $file_chop -dirTmp $opt{dir_tmp}";
    
    if ( $opt{'debug'} ) {
	$cmd_chop .= " -debug ";
	print STDERR "-- running CHOP: $cmd_chop\n";
    }

    system $cmd_chop;
    if ( ! -s $file_chop ) {
	print STDERR 
	    "*** ERROR: after CHOP, output file $file_chop not found or empty, abort\n";
	exit(1);
    }
    $pred_chop = retrieve($file_chop);
}
push @toDelete,$file_chop,$file_chop_xml;

if ( ! %$pred_chop ) {
    %domain = ( 'domainStart' => 1,
		'domainEnd'  => $seq_len,
		'source' => 'NULL',
		);
    push @{$pred_chop->{'domains'}},{%domain};
}

				# running chopnet if necessary
$ct_frag_net = 0;
foreach $domain_chop ( @{$pred_chop->{'domains'}} ) {
    if ( $domain_chop->{'homoDB'} and 
	 $domain_chop->{'homoDB'} =~ /pfam|prism|scop|cath/i ) {
	$domain_chop->{'source'} = 'CHOP';
	print $fh_err "i) domain from CHOP(pfam/prism), skip..\n";
	push  @{$protein->{'domains'}},$domain_chop;
	next;
    }
    if ( $domain_chop->{'homoDB'} and
	 $domain_chop->{'homoDB'} =~ /swiss/i ) {
	$domain_chop->{'source'} = 'CHOP';
    } else {
	$domain_chop->{'source'} = 'NULL';
    }

    $domain_beg = $domain_chop->{"domainStart"};
    $domain_end = $domain_chop->{"domainEnd"};
    $domain_len = $domain_end - $domain_beg + 1;

    if ( ! $opt{'runChopnet'} or $domain_len < $opt{'minLenChopnet'} ) {	
	push  @{$protein->{'domains'}},$domain_chop;
	next;
    }
    
    $ct_frag_net++;
    $seqName = $id."_$ct_frag_net";
    $fileSeqTmp = $opt{'dir_tmp'}.$seqName.'.f';
    &writeFragmentSeq($fileSeqTmp,$seqName,$prot_id,0,$domain_beg,$domain_end,'unchecked',$seq);    
    $file_seq = $opt{'dir_tmp'}.$seqName.'.f';
    $file_blast = $opt{'dir_tmp'}.$seqName.'.blast';
    $file_saf = $opt{'dir_tmp'}.$seqName.'.saf';
    $file_hssp = $opt{'dir_tmp'}.$seqName.'.hssp';
    $file_prof = $opt{'dir_tmp'}.$seqName.'.rdbProf';
    push @toDelete,$file_seq,$file_blast,$file_saf,$file_hssp,$file_prof;
    
    ($Lok,$err_msg) = &do_blast($file_seq,$file_blast,$file_saf);
    if ( ! $Lok ) {
	print STDERR "*** ERROR running blast: $err_msg\n";
	exit(1);
    }

    ($Lok,$err_msg) = &do_hssp($file_saf,$file_hssp);
     if ( ! $Lok ) {
	 print STDERR "*** ERROR generating HSSP: $err_msg\n";
	exit(1);
    }

    ($Lok,$err_msg) = &do_prof($file_hssp,$file_prof);
     if ( ! $Lok ) {
	 print STDERR "*** ERROR running PROF: $err_msg\n";
	 exit(1);
    }

    				# running CHOPnet
    $file_chopnet = $opt{'dir_tmp'}.$seqName.'.chopnet';
    $file_chopnet_xml = $file_chopnet.'.xml';
    $cmd_chopnet = "$scr_chopnet -hssp $file_hssp -prof $file_prof -of storable -o $file_chopnet";
    
    if ( $opt{'debug'} ) {
	print STDERR "--running CHOPnet: $cmd_chopnet\n";
    }
    print $fh_err "--running CHOPnet: $cmd_chopnet\n";
    system $cmd_chopnet;

    if ( ! -s $file_chopnet ) {	# error
	print STDERR "*** ERROR: chopnet on $file_seq returns nothing.\n";
	push  @{$protein->{'domains'}},$domain_chop;
	next;
    }
    push @toDelete,$file_chopnet,$file_chopnet_xml;

    $pred_chopnet = retrieve($file_chopnet);
    $domains_chopnet = $pred_chopnet->{'domains'};
    				# chopnet return single domain
    if ( scalar @$domains_chopnet == 1 ) {
	$domain_chop->{'source'} = 'CHOPnet';
	push  @{$protein->{'domains'}},$domain_chop;
	next;
    }
    				# multi-domain prediction from chopnet, calculate offset
    $offset = $domain_beg - 1;
    foreach $domain_chopnet ( @$domains_chopnet ) {
	$domain_chopnet->{'domainStart'} += $offset;
	$domain_chopnet->{'domainEnd'} += $offset;
	push @{$protein->{'domains'}},$domain_chopnet;
    }
}


&format_output($protein,$opt{'file_out'},$opt{'format_out'});


				# clean up
close $fh_err;

if ( ! $opt{'debug'} ) {
    foreach $f ( @toDelete ) {
	unlink $f if ( -f $f );
    }
}



exit;


#==========================================================
sub ini {	
#-----------------------------------------------------------
# initialization: set global variables, get command line options
#-----------------------------------------------------------


#    $dir_scr = $0;
#    $dir_scr =~ s/[^\/]+$//g;
    $dir_package = 'DIRPACKAGE';
    $dir_package .= '/' if ( $dir_package !~ /\/$/ );
    if ( ! -d $dir_package ) {
	print STDERR "package home directory not found, please check installation\n";
	exit(1);
    }

    $dir_scr = $dir_package.'scr/';
    $dir_etc = $dir_package.'etc/';

    $scr_chop = $dir_scr."chop.pl";
    $scr_chopnet = $dir_scr."chopnet.pl";

				# default options
    $opt{'help'} = 0;
    $opt{'debug'} = 0;
    $opt{'verbose'} = 1;

    $opt{'runChop'} = 1;
    $opt{'runChopnet'} = 1;
    $opt{'minLenChopnet'} = 100;
    $opt{'dir_tmp'} = './';
    $opt{'format_out'} = 'xml';
    $opt{'keepxml'} = 1;

    %opt_chop = ();

    $file_config = $dir_etc.'chopper.config';
    &read_config($file_config,\%opt,\%opt_chop);
    $opt_chop_str = &opt_hash2str(\%opt_chop);

    $Lok = GetOptions ('debug!' => \$opt{'debug'},
		       'i=s' => \$opt{'file_in'},
		       'o=s' => \$opt{'file_out'},
		       'of=s' => \$opt{'format_out'},
		       'keepxml!' => \$opt{'keepxml'},
		       'id=s' => \$opt{'id'}, # name of the protein
		       'dirTmp=s' => \$opt{'dir_tmp'},
		       'chop!' => \$opt{'runChop'},
		       'chopnet!' => \$opt{'runChopnet'}, 
		       'minLenChopnet=i' => \$opt{'minLenChopnet'},
		       'printconf' => \$opt_printconfig,
		       'help'  => \$opt{'help'},
		       );

    if ( ! $Lok ) {
	print STDERR "*** ERROR: Invalid arguments found, -h for help\n";
	&usage();
	exit(1);
    }
    
    if ( $opt{'help'} ) {
	&usage();
	exit(1);
    }


    if ( $opt_printconfig ) {
	&print_config();
	exit;
    }

    if ( ! $opt{'file_in'} or ! $opt{'file_out'} ) {
	print STDERR
	    "*** ERROR: input file or output file not specified\n";
	&usage();
	exit(1);
    }

    if ( ! -f $opt{'file_in'} ) {
	print STDERR
	    "*** ERROR: input file '$opt{file_in}' not found, exiting..\n";
	&usage();
	exit(1);
    }

    @file_exe = qw(scrBlast scrProf scrCopf scrHsspFilter);
    foreach $exe ( @file_exe ) {
	if ( ! -s $opt{$exe} or ! -x $opt{$exe} ) {
	    print STDERR "*** ERROR: $exe file $opt{$exe} not found or not executable, exiting..\n";
	    &usage();
	    exit(1);
	}
    }
    
				# end of option/sanity check



    if ( defined $ENV{'HOSTNAME'} ) {
	$hostName = $ENV{'HOSTNAME'};
	$hostName =~ s/\..*//g;
    } else {
	$hostName = 'host';
    }
    $jobId = $hostName."-".$$;
    $id = "TEMP-CHOPPER-$jobId";



    				# error files
    $file_err = $opt{'dir_tmp'}.$id.'.trace';
    $fh_err = "CHOPPER_ERR";
    open ($fh_err,">$file_err") or die "cannot write to $file_err:$!";
    $file_err_app = $opt{'dir_tmp'}.$id.'.err_app'; # error file for all external app
    push @toDelete,$file_err,$file_err_app;

    if ( $opt_printconfig ) {
	&print_config();
	exit;
    }

    return;
}


sub do_blast {
    my ( $file_seq,$file_blast,$file_saf ) = @_;
    my ($cmd,$err_msg);

    $cmd = $opt{"scrBlast"}. " $file_seq fileOut=$file_blast saf=$file_saf nonice ".
	"> $file_err_app 2>&1 ";
    if ( $opt{'debug'} ) {
	print STDERR "--running blast: $cmd\n";
    }
    print $fh_err "--running blast: $cmd\n";
    system $cmd;
    if ( ! -s $file_blast or ! -s $file_saf ) {
	$err_msg ="after Blast, $file_blast or $file_saf not found\n";
	return (0,$err_msg);
    }
	
    return (1,"");
}

sub do_hssp {
    my ($file_saf,$file_hssp ) = @_;
    my ($file_hssp_raw,$cmd_copf,$cmd_filter,$err_msg);

    $file_hssp_raw = $file_hssp.'_raw';
    $cmd_copf = $opt{"scrCopf"}. " $file_saf hssp fileOut=$file_hssp_raw > $file_err_app 2>& 1";
    if ( $opt{'debug'} ) {
	print STDERR "--running COPF: $cmd_copf\n";
    }
    print $fh_err "--running COPF: $cmd_copf\n";

    system $cmd_copf;
    if ( ! -s $file_hssp_raw ) {
	$err_msg ="after Copf, $file_hssp_raw not found\n";
	return (0,$err_msg);
    }

    $cmd_filter = $opt{'scrHsspFilter'}. " red=80 $file_hssp_raw fileOut=$file_hssp".
	" > $file_err_app 2>& 1";
    if ( $opt{'debug'} ) {
	print STDERR "--running hssp_filter: $cmd_filter\n";
    }
    print $fh_err "--running hssp_filter: $cmd_filter\n";
    
    system $cmd_filter;
    if ( ! -s $file_hssp ) {
	$err_msg ="after hssp_filter, $file_hssp not found\n";
	return (0,$err_msg);
    }
    
    push @toDelete,$file_hssp_raw;
    return (1,"");
}

sub do_prof {
    my ($file_hssp,$file_prof ) = @_;
    my ($cmd,$err_msg);

    $cmd = $opt{"scrProf"}. " $file_hssp both nonice fileOut=$file_prof >$file_err_app 2>&1 ";
    if ( $opt{'debug'} ) {
	print STDERR "--running prof: $cmd\n";
    }
    print $fh_err "--running prof: $cmd\n";

    system $cmd;
    if ( ! -s $file_prof ) {
	$err_msg ="after prof, $file_prof not found\n";
	return (0,$err_msg);
    }

    return (1,"");
}


sub format_output {
    my ($pred,$file_out,$format_out) = @_;
    my ( $file_xml );
				# always output XML
    $file_xml = $file_out.'.xml';
    &hash2xml($protein,$file_xml);

    if ( $format_out eq 'xml' ) {
	move ($file_xml,$file_out) or die "cannot move $file_xml to $file_out:$!";
    } elsif ( $format_out eq 'casp' ) {
	&xml2casp($file_xml,$seq,$file_out);
    } elsif ( $format_out eq 'txt' ) {
	&xml2txt_chopper($file_xml,$file_out);
    } elsif ( $format_out eq 'html' ) {
	&xml2html_chopper($file_xml,$file_out);
    }

    if ( ! $opt{'keepxml'} ) {
	push @toDelete, $file_xml;
    }
}

sub opt_hash2str {
    my ( $hash_ref ) = @_;
    my ( $opt_str,$o );

    $opt_str = "";
    foreach $o ( keys %$hash_ref ) {
	if ( $hash_ref->{$o} =~ /^true$/i ) {
	    $opt_str = " -$o ";
	} else {
	    $opt_str = " -$o ".$hash_ref->{$o};
	}
    }
    return $opt_str;
}


sub print_config {
    my ( @options, $o );

    @options = keys %opt;
    if ( @options ) {
	print STDERR "Options for chopper package:\n";
	foreach $o ( @options ) {
	    next if ( ! defined $opt{$o} );
	    print STDERR "  $o=",$opt{$o},"\n";
	}
    }
    @options = keys %opt_chop;
    if ( @options ) {
	print STDERR "Options for CHOP:\n";
	foreach $o ( @options ) {
	    next if ( ! defined $opt_chop{$o} );
	    print STDERR "  $o=",$opt_chop{$o},"\n";
	}
    }
    
    return;
}
	
sub read_config {
    my ( $file, $opt_ref,$opt_chop_ref,$opt_chopnet_ref ) = @_;
    my $sbr = "read_config";
    my $fh = "IN_$sbr";

    if ( ! $file or ! -s $file ) {
	print STDERR "*** ERROR: configuration file $file not specified or empty\n";
	exit(1);
    }

    open ($fh,$file) or die "cannot open $file:$!";
    while ($line = <$fh>) {
	next if ( $line =~ /^\#/ );
	next if ( $line !~ /\w+/ );
	$line =~ s/\#.*//g;
	$line =~ s/\s+//g;
	if ( $line =~ /(\w+)=(.*)/ ) {
	    ($opt,$value) = ($1,$2);
	    if ( $opt =~ /^CHOP_(\w+)/ ) {
		$opt_chop_ref->{$1} = $value;
	    } elsif ( $opt =~ /^CHOPNET_(\w+)/ ) {
		$opt_chopnet_ref->{$1} = $value;
	    } else {
		$opt_ref->{$opt} = $value;
	    }
	}
    }
    close $fh;
    return;
    
}


sub usage {
    $name_scr = $0;
    $name_scr =~ s/.*\///g;

    print STDERR
	"$name_scr: running CHOP and CHOPnet for domain prediction \n",
	"Usage: $name_scr [options] -i in_file -o out_file\n",
	"  Opt:  -h            print this help\n",
	"        -i <file>     input file (REQUIRED)\n",
	"        -o <file>     output file (REQUIRED)\n",
	"        -of <string>  format of the output (xml|casp|txt|html), default=xml\n",
	"        -keepxml      always keep XML output (default=TRUE)\n",
	"        -id <string>  identifier of input protein (default: taken from input fasta)\n",
	"        -(no)chop     run CHOP prediction (default=TRUE)\n",
	"        -(no)chopnet  run CHOPnet prediction (default=TRUE)\n",
	"        -(no)debug    print debug info(default=nodebug)\n", # 
	"        -printconf    print all current options and exit\n";
}
