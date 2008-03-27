# Copyright (c) 1997-1999  Nigel P. Brown, Christophe Leroy. $Id: SRS.pm,v 1.10 1999/03/01 11:57:50 nbrown Exp $

###########################################################################
package Bio::SRS;

@ISA       = qw(Exporter);
@EXPORT    = qw(srsLink);
@EXPORT_OK = ();

use vars qw($Type);

$Type = 1;    #this SRS

BEGIN {
    if (-r '/homes/genequiz/GQACCESS/WORK/lib/GQBrowse/Link.pm') {
	#make genequiz shut up
	no strict; local $^W=0; 
	require "/homes/genequiz/GQACCESS/WORK/lib/GQBrowse/Link.pm";
	my $x = ($gq_www_env::TRUE || $gq_www_env::FALSE || $gq_www_env::def_sum_col_filt);
    }
}

#pre-SRS5 URLs:
# $url_srs2 = 'http://www.embl-heidelberg.de/srs/srsc';
#    'trembl'     => "$url_srs2?[trembl-id:&ID]",
#    'tremblnew'  => "$url_srs2?[tremblnew-id:&ID]|([trembl-id:&ID]![trembl-id:&ID]<tremblnew)",
# $url_srs3 = 'http://www.infobiogen.fr/srs/cgi-bin/srsc';
#    'genbank'    => "$url_srs3?[genbank-acc:&AC]",
#    'genbnew'    => "$url_srs3?[genbanknew-acc:&AC]|[genbank-acc:&AC]",
# $url_srs4 = 'http://www.sanger.ac.uk:80/srs/srsc';
#    'worm'       => "$url_srs4?[wormpep-id:&ID]",

my $url_srs1 = 'http://srs6.ebi.ac.uk/srs6bin/cgi-bin/wgetz';
my $url_srs2 = 'http://srs6.ebi.ac.uk/srs6bin/cgi-bin/wgetz';
my $url_srs3 = 'http://www.infobiogen.fr/srs5bin/cgi-bin/wgetz';
my $url_srs4 = 'http://www.sanger.ac.uk/srs5bin/cgi-bin/wgetz';

my %SRSMAP = 
    (
     
     # Protein databases	       
     'swissprot'  => "$url_srs1?-e+[swissprot-id:&ID]",
     'swissnew'   => "$url_srs1?-e+[swissnew-id:&ID]|[swissprot-id:&ID]",
     'pdb'        => "$url_srs1?-e+[pdb-acc:&AC]",
     'pir'        => "$url_srs1?-e+[pir-id:&ID]",
     'trembl'     => "$url_srs2?-e+[swall-id:&ID]",
     'tremblnew'  => "$url_srs2?-e+[tremblnew-id:&ID]|([trembl-id:&ID]![trembl-id:&ID]<tremblnew)",
     'wormpep'    => "$url_srs4?-e+[wormpep-id:&ID]",
     'sptrembl'   => "$url_srs1?-e+[sptrembl-id:&ID]",
     'remtrembl'  => "$url_srs1?-e+[remtrembl-id:&ID]",
     
     # Nucleotide databases
     'embl'       => "$url_srs1?-e+[embl-id:&ID]",
     'emnew'      => "$url_srs1?-e+[emblnew-id:&ID]|[embl-id:&ID]",
     'genbank'    => "$url_srs3?-e+[genbank-acc:&AC]",
     'genbnew'    => "$url_srs3?-e+[genbanknew-acc:&AC]|[genbank-acc:&AC]",
     'dbest'      => "$url_srs1?-e+[dbest-id:&ID]",
     
     # Profile databases
     'prosite'    => "$url_srs1?-e+[prosite-acc:&AC]",
     'blocks'     => "$url_srs1?-e+[blocks-acc:&AC]",
    );

#aliases added to SRSMAP: only use one level of referencing!
$SRSMAP{'sw'}       = \$SRSMAP{'swissprot'};
$SRSMAP{'swiss'}    = \$SRSMAP{'swissprot'};
$SRSMAP{'gp'}       = \$SRSMAP{'genbank'};
$SRSMAP{'gpnew'}    = \$SRSMAP{'genbnew'};
$SRSMAP{'pironly'}  = \$SRSMAP{'pir'};
$SRSMAP{'worm'}     = \$SRSMAP{'wormpep'};

#TREMBL subsets?

#EMBL subsets
$SRSMAP{'em_ba'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_in'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_om'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_or'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_ov'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_ph'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_pl'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_ro'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_sy'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_un'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_vi'}    = \$SRSMAP{'embl'};
$SRSMAP{'em_est1'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est2'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est3'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est4'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est5'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est6'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est7'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est8'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est9'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_est10'} = \$SRSMAP{'embl'};
$SRSMAP{'em_est11'} = \$SRSMAP{'embl'};
$SRSMAP{'em_est12'} = \$SRSMAP{'embl'};
$SRSMAP{'em_est13'} = \$SRSMAP{'embl'};
$SRSMAP{'em_fun'}   = \$SRSMAP{'embl'};
$SRSMAP{'em_gss'}   = \$SRSMAP{'embl'};
$SRSMAP{'em_htg'}   = \$SRSMAP{'embl'};
$SRSMAP{'em_hum1'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_hum2'}  = \$SRSMAP{'embl'};
$SRSMAP{'em_pat'}   = \$SRSMAP{'embl'};
$SRSMAP{'em_sts'}   = \$SRSMAP{'embl'};

sub srsLink {
    my ($db,$ac,$id,$link);

    #Type == 0 (no SRS)
    return ''    unless $Type;
    
    #Type == 2 (GeneQuiz SRS)
    if ($Type == 2 and $_[0] =~ /\|/) {
	$link = "GQBrowse::Link::srsLink(\$_[0])";
	$link = eval $link;
	return ''       if $@;              #failed: function undefined
	return $link    if defined $link;   #failed: value undefined
	return '';
    }

    #Type eq 1  (this SRS)
    my @tmp = ();
    
    if ($_[0] =~ /^[^|:]+\|/) {
	#NCBI/genequiz style names: db|ac|id
	@tmp = split(/\|/, $_[0]);
	($db, $ac, $id) = ($tmp[0], $tmp[1], $tmp[2]);

	if ($ac =~ /^(\S+):\S+/) {
	    #SEGS style name:range
	    $ac = $id = $1;
	}

    } elsif ($_[0] =~ /^[^|:]+\:/) {
	#EBI/GCG style names: db:id
	@tmp = split(/:/, $_[0]);
	($db, $ac, $id) = ($tmp[0], $tmp[1], $tmp[1]);
    } else {
	#nothing to link afterall
	($db, $ac, $id) = ('', '', '');
    }
    
    #just make sure they're all defined
    $db = ''    unless defined $db;
    $ac = ''    unless defined $ac;
    $id = ''    unless defined $id;

    $db = lc $db;

    if (defined $SRSMAP{$db}) {
	$link = $SRSMAP{$db};
	$link = $$link    if ref $link;
    } else {
	return '';
    }

    $link =~ s/\&AC/$ac/g;
    $link =~ s/\&ID/$id/g;

    #warn "$db,$ac,$id  ->  $link\n";

    return $link;
}


###########################################################################
1;
