package      libChopper;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(get_seq_info hash2xml xml2casp xml2hash 
		xml2html_chop xml2html_chopper xml2txt_chop 
		xml2txt_chopper writeFragmentSeq);

use XML::DOM;
#use strict;

#========================================================
sub get_seq_info {
    my ($fileFasta) = @_;
    my ( $id,$seq,$seqLen );
    my ( $nameSub, $fhSeq_sub );
#--------------------------------------------------------

    $nameSub = 'get_seq_info';
    $fhSeq_sub = $nameSub."_SEQ";

    $seq = "";
    open ($fhSeq_sub,$fileFasta) or die "cannot open $fileFasta:$!";
    while (<$fhSeq_sub>) {
	chomp;
	if ( /^\s*\>/ ) {
	    $id = $_;
	    $id =~ s/^\s*\>\s*//g;
	    $id =~ s/\s+.*//g;
	    if ( $id =~ /\bgi\|(\d+)\|/i ) { # if we have a GI number
                $id = $1;
	    } elsif ( $id =~ /\|(\w+)$/ ) {
		$id =~ s/.*\|//g;
	    } else {		# we just take the file name
		$id = $fileFasta;
		$id =~ s/.*\///g;
		$id =~ s/\..*//g;
	    }
	    next;
	} 
	$seq .= $_;
    }
    close $fhSeq_sub;
    $seq =~ s/\s+//g;
    $seqLen = length $seq;
    return ($id,$seqLen,$seq);
}				# END of SUB get_seq_info



sub hash2xml {
    my ( $hash_ref, $file_out ) = @_;
    my $sbr = "hash2xml";
    my $fh = "XML_$sbr";
    my ( $domain,@tags,$t );

    open ($fh,">$file_out") or die "cannot write to $file_out:$!";
    print $fh
	"<?xml version=\"1.0\"?>\n",
	"<protein>\n",
	"<proteinID>$hash_ref->{'proteinID'}</proteinID>\n",
	"<length>$hash_ref->{'length'}</length>\n",
	"<domains>\n";
    foreach $domain ( @{$hash_ref->{'domains'}} ) {
	print $fh "<domain>\n";
	@tags = keys %$domain;
	foreach $t ( @tags ) {
	    next if ( $t eq 'status' );
	    next if ( ! defined $domain->{$t} );
	    print $fh "<$t>$domain->{$t}</$t>\n";
	}
	print $fh "</domain>\n";
    }
    print $fh 
	"</domains>\n",
	"</protein>\n";
    close $fh;
    return;
}



#===============================================================
sub writeFragmentSeq {
    my ( $fileOut,$seqName,$origin,$offset,$start,$end,$status,$seq ) = @_;
    my ( $fragLen,$seqFrag,$adjustedStart,$adjustedEnd );
    my ( $nameSub,$fhOut_sub );
#---------------------------------------------------------------

    $nameSub = 'writeFragmentSeq';
    $fragLen = $end - $start + 1;
    $seqFrag = substr($seq,$start-1,$fragLen);
    $adjustedStart = $start + $offset;
    $adjustedEnd = $end + $offset;

    $fhOut_sub = $nameSub.'_OUT';
    open ($fhOut_sub, ">$fileOut") or die "cannot write to $fileOut:$!";
    print $fhOut_sub
	">$seqName\t","$fragLen\t",
	"$origin\t","$adjustedStart-$adjustedEnd\t","$status\n",
	"$seqFrag\n";
    close $fhOut_sub;
    return;
}				# END of SUB writeFragmentSeq


sub xml2casp {
    my ( $file_xml,$seq,$file_casp ) = @_;
    my $sbr = "xml2casp";
    my $fh = "CASP_$sbr";
    my ($pred,$seq_len,@domains,$ct_domain,$dom,@dom_num,$i);
    
    $pred = &xml2hash($file_xml);
    return if ( ! $pred );
    $seq_len = length $seq;

    @domains = 
	sort { $a->{'domainStart'} <=> $b->{'domainStart'} } @{$pred->{'domains'}};

    $ct_domain = 0;
    foreach $dom ( @domains ) {
	if ( $dom->{'domainEnd'} > $seq_len ) {
	    print STDERR "*** ERROR: domain out of sequence length, domainEnd=$dom->{'domainEnd'},seqLen=$seq_len\n";
	    die;
	}
	$ct_domain++;
	for $i ( $dom->{'domainStart'}..$dom->{'domainEnd'} ) {
	    $dom_num[$i] = $ct_domain;
	}
    }

    if ( $file_casp ) {
	open ($fh,">$file_casp") or die "cannot write to $file_casp:$!";
    } else {
	$fh = "STDOUT";
    }
    print $fh
	"PFRMAT DP\n",
	"TARGET ",$pred->{'proteinID'},"\n",
	"AUTHOR 2799-6963-7913\n",
	"METHOD CHOP, CHOPnet\n",
	"MODEL  1\n";
    for $i ( 1..$seq_len ) {
	$dom_num[$i] = '-' if ( ! $dom_num[$i] );
	print $fh $i," ",substr($seq,$i-1,1)," ",$dom_num[$i],"\n";
    }
    print $fh "END\n";
    close $fh;
    return;
}
		      
    

sub xml2hash {
    my ( $file_xml ) = @_;
    my ( $protein,$domain,$child,%domain_hash );
    return undef if( ! -s $file_xml or ! -r $file_xml );

    my $parser = XML::DOM::Parser->new();
    my $doc = $parser->parsefile($file_xml);
    $protein->{'proteinID'} = 
	$doc->getElementsByTagName('proteinID')->item(0)->getFirstChild->getNodeValue;
    $protein->{'length'} = 
	$doc->getElementsByTagName('length')->item(0)->getFirstChild->getNodeValue;
    

    foreach $domain ($doc->getElementsByTagName('domain')){
	undef %domain_hash;
	foreach $child ( $domain->getChildNodes ) {
	    next if ( $child->getNodeType != 1 );
	    #next if ( $child->getFirstChild->getNodeType != 3 );
	    $domain_hash{$child->getNodeName} = $child->getFirstChild->getNodeValue;
	}
	push @{$protein->{'domains'}},{%domain_hash};
    }
    $doc->dispose;		# clean up memory
    return $protein;
}

sub xml2html_chop {
    my ( $file_xml,$file_out ) = @_;
    my $sbr = "xml2html_chop";
    my $fh = "OUT_$sbr";
    my ($pred,@domains,$dom,$dom_region,$eValue,$homo,$region);    
    my ( $ct_entry, $style_th, $style_tr,$style_tr1,$style_tr2);
    my ( $host_srs,$cgi_srs,$database,$pdb_id,$srs_url,$homo_link );

    $pred = &xml2hash($file_xml);
    return if ( ! $pred );

    $style_th = 'background:#bcd2ee;font-family:Times,Serif';
    $style_tr1 = 'background:#d9d9d9;font-family:Times,Serif';
    $style_tr2 = 'background:#cccccc;font-family:Times,Serif';
    $host_srs = 'http://walnut.bioc.columbia.edu/';
    $cgi_srs = 'srs7bin/cgi-bin/wgetz';


    @domains = 
	sort { $a->{'domainStart'} <=> $b->{'domainStart'} } @{$pred->{'domains'}};

    if ( $file_out ) {
	open ($fh,">$file_out") or die "cannot write to $file_out:$!";
    } else {
	$fh = "STDOUT";
    }
    
    print $fh
#	    "<PRE>\n",$quote_txt,"</PRE>\n",
	"Query : $pred->{'proteinID'}<BR>\n",
	"Length: $pred->{'length'}<BR>\n";
    
    print $fh
            "<P>\n",
            "<TABLE CELLPADDING=2>\n",
	    "<TR VALIGN=TOP style='$style_th'>\n",
	    "\t<TD>Domains &nbsp;&nbsp;</TD>\n",
	    "\t<TD>Homologue(region) &nbsp;&nbsp;</TD>\n",
	    "\t<TD>E value &nbsp;&nbsp;</TD>\n",
	    "\t<TD>Method &nbsp;&nbsp;</TD>\n",
	    "\t<TD>Database &nbsp;&nbsp;</TD>\n",
	    "\t</TR>\n";

    $ct_entry = 0;		# 
    foreach $dom ( @domains ) {
	$dom_region = $dom->{'domainStart'}.'-'.$dom->{'domainEnd'};

	if ( $dom->{'homoEvalue'} eq 'NULL' ) {
	    $eValue = '&nbsp';
	} else {
	    $eValue =  $dom->{'homoEvalue'};
	}
	if ( $dom->{'homoName'} eq 'NULL' ) {
	    $homo = '&nbsp';
	} else {
	    $homo = $dom->{'homoName'};
	}
	if ( $dom->{'homoRegion'} ) {
	    $region = '('.$dom->{'homoRegion'}.')';
	} 

	$ct_entry++;
	if ( $ct_entry % 2 == 1 ) {
	    $style_tr = $style_tr1;
	} else {
	    $style_tr = $style_tr2;
	}

	$database = $dom->{'homoDB'};

	    			# build SRS link
	if ( $database =~ /prism/i ) {
	    $pdb_id = substr($homo,0,4);
	    $srs_url = $host_srs.$cgi_srs."?-newId+-e+[PDB-id:'$pdb_id']";
	    $homo_link = "<A HREF=\"$srs_url\" TARGET=_blank >$homo</A>$region";
	} elsif ( $database =~ /pfam/i ) {
	    $srs_url = $host_srs.$cgi_srs."?-newId+-e+[PFAMA-AccNumber:'$homo']";
	    $homo_link = "<A HREF=\"$srs_url\" TARGET=_blank>$homo</A>$region";
	} elsif ( $database =~ /swiss/i ) {
	    $srs_url = $host_srs.$cgi_srs."?-newId+-e+[swissprot:'$homo']";
	    $homo_link = "<A HREF=\"$srs_url\" TARGET=_blank>$homo</A>$region";
	} else {
	    $homo_link = $homo;
	}

	print $fh
	    "<TR VALIGN=TOP style='$style_tr'>\n",
	    "\t<TD>",$dom_region,"</TD>\n",
	    "\t<TD>$homo_link</TD>\n",
	    "\t<TD>$eValue</TD>\n",
	    "\t<TD>",$dom->{'homoMethod'},"</TD>\n",
	    "\t<TD>",$dom->{'homoDB'},"</TD>\n",
	    "</TR>\n";
    }
    print $fh "</TABLE>\n";
    close $fh;

    return;
}

sub xml2html_chopper {
    my ( $file_xml,$file_out ) = @_;
    my $sbr = "xml2html_chopper";
    my $fh = "OUT_$sbr";
    my ($pred,@domains,$dom,$dom_region);    
    my ( $ct_entry, $has_chop,$style_th, $style_tr,$style_tr1,$style_tr2);
    my ( $host_srs,$cgi_srs,$database,$pdb_id,$srs_url,$homo_link );
    my ( $homo, $region );

    $pred = &xml2hash($file_xml);
    return if ( ! $pred );

    $style_th = 'background:#bcd2ee;font-family:Times,Serif';
    $style_tr1 = 'background:#d9d9d9;font-family:Times,Serif';
    $style_tr2 = 'background:#cccccc;font-family:Times,Serif';
    $host_srs = 'http://walnut.bioc.columbia.edu/';
    $cgi_srs = 'srs7bin/cgi-bin/wgetz';

    @domains = 
	sort { $a->{'domainStart'} <=> $b->{'domainStart'} } @{$pred->{'domains'}};

    $has_chop = 0;
    foreach $dom ( @domains ) {
	if ( $dom->{'homoDB'} and $dom->{'homoDB'} ne 'NULL' ) {
	    $has_chop = 1;
	    last;
	}
    }

    if ( $file_out ) {
	open ($fh,">$file_out") or die "cannot write to $file_out:$!";
    } else {
	$fh = "STDOUT";
    }
    
    print $fh
	"Query : $pred->{'proteinID'}<BR>\n",
	"Length: $pred->{'length'}<BR>\n";
    
    print $fh
	"<P>\n",
	"<TABLE CELLPADDING=2>\n",
	"<TR VALIGN=TOP style='$style_th'>\n",
	"\t<TD>Domains &nbsp;&nbsp;</TD>\n",
	"\t<TD>Method &nbsp;&nbsp;</TD>\n";

    print $fh "\t<TD>Homologue(region) &nbsp;&nbsp;</TD>\n" if ( $has_chop );
    print $fh "\t</TR>\n";

    $ct_entry = 0;		# 
    foreach $dom ( @domains ) {
	$dom_region = $dom->{'domainStart'}.'-'.$dom->{'domainEnd'};

	if ( ! $dom->{'homoName'} or $dom->{'homoName'} eq 'NULL' ) {
	    $homo = '&nbsp';
	} else {
	    $homo = $dom->{'homoName'};
	}
	if ( $dom->{'homoRegion'} ) {
	    $region = '('.$dom->{'homoRegion'}.')';
	} 

	$ct_entry++;
	if ( $ct_entry % 2 == 1 ) {
	    $style_tr = $style_tr1;
	} else {
	    $style_tr = $style_tr2;
	}

	if ( $dom->{'homoDB'} and $dom->{'homoDB'} ne 'NULL' ) {
	    $database = $dom->{'homoDB'};

	    			# build SRS link
	    if ( $database =~ /prism/i ) {
		$pdb_id = substr($homo,0,4);
		$srs_url = $host_srs.$cgi_srs."?-newId+-e+[PDB-id:'$pdb_id']";
		$homo_link = "<A HREF=\"$srs_url\" TARGET=_blank >$homo</A>$region";
	    } elsif ( $database =~ /pfam/i ) {
		$srs_url = $host_srs.$cgi_srs."?-newId+-e+[PFAMA-AccNumber:'$homo']";
		$homo_link = "<A HREF=\"$srs_url\" TARGET=_blank>$homo</A>$region";
	    } elsif ( $database =~ /swiss/i ) {
		$srs_url = $host_srs.$cgi_srs."?-newId+-e+[swissprot:'$homo']";
		$homo_link = "<A HREF=\"$srs_url\" TARGET=_blank>$homo</A>$region";
	    } else {
		$homo_link = $homo;
	    }
	} else {
	    $homo_link = '&nbsp;';
	}

	print $fh
	    "<TR VALIGN=TOP style='$style_tr'>\n",
	    "\t<TD>",$dom_region,"</TD>\n",
	    "\t<TD>",$dom->{'source'},"</TD>\n";

	print $fh "\t<TD>$homo_link</TD>\n" if ( $has_chop );
	print $fh "</TR>\n";
    }
    print $fh "</TABLE>\n";
    close $fh;

    return;
}

sub xml2txt_chop {
    my ( $file_xml,$file_out ) = @_;
    my $sbr = "xml2txt";
    my $fh = "OUT_$sbr";
    my ($pred,@domains,$space,$bar,$format,$dom,$dom_region,$homo,$method);


    $pred = &xml2hash($file_xml);
    return if ( ! $pred );

    @domains = 
	sort { $a->{'domainStart'} <=> $b->{'domainStart'} } @{$pred->{'domains'}};


    $space = ' ';
    $bar = "-";
    $format = "%-10s%3s%-20s%3s%-10s%3s%-20s\n";

    if ( $file_out ) {
	open ($fh,">$file_out") or die "cannot write to $file_out:$!";
    } else {
	$fh = "STDOUT";
    }
    print $fh
	"# Query  : $pred->{'proteinID'}\n",
	"# Length : $pred->{'length'}\n";

    printf $fh
	$format,
	"Domains",$space,"Homologue(region)",$space,
	"E_value",$space,"Method";

    printf $fh
	$format,
	$bar x10,$space,$bar x20,$space,
	$bar x10,$space,$bar x20;


    foreach $dom ( @domains ) {
	$dom_region = $dom->{'domainStart'}.'-'.$dom->{'domainEnd'};
	$homo = $dom->{'homoName'};
	$homo .= '('.$dom->{'homoRegion'}.')' if ( $dom->{'homoRegion'} );
	$method = $dom->{'homoMethod'};
	$method .= '/'.$dom->{'homoDB'} if ( $dom->{'homoDB'} );
	printf $fh 
	    $format,
	    $dom_region,$space,
	    $homo,$space,
	    $dom->{'homoEvalue'},$space,
	    $method;
    }

    print $fh "//\n";
    close $fh;
    return;
}
		      
sub xml2txt_chopper {
    my ( $file_xml,$file_out ) = @_;
    my $sbr = "xml2txt_chopper";
    my $fh = "OUT_$sbr";
    my ($pred,@domains,$has_chop,$space,$bar,$format_chop,$format_chopnet);
    my ($dom,$dom_region,$homo,$method);


    $pred = &xml2hash($file_xml);
    return if ( ! $pred );

    @domains = 
	sort { $a->{'domainStart'} <=> $b->{'domainStart'} } @{$pred->{'domains'}};

    $has_chop = 0;
    foreach $dom ( @domains ) {
	if ( $dom->{'homoDB'} and $dom->{'homoDB'} ne 'NULL' ) {
	    $has_chop = 1;
	    last;
	}
    }

    $space = ' ';
    $bar = "-";
    $format_chop = "%-10s%3s%-10s%3s%-20s\n";
    $format_chopnet = "%-10s%3s%-10s\n";

    if ( $file_out ) {
	open ($fh,">$file_out") or die "cannot write to $file_out:$!";
    } else {
	$fh = "STDOUT";
    }
    print $fh
	"# Query  : $pred->{'proteinID'}\n",
	"# Length : $pred->{'length'}\n";

    if ( $has_chop ) {
	printf $fh
	    $format_chop,
	    "Domains",$space,"Method",$space,"Homologue(region)";
    } else {
	printf $fh $format_chopnet,"Domains",$space,"Method";
    }
    
    if ( $has_chop ) {
	printf $fh $format_chop,$bar x10,$space,$bar x10,$space,$bar x20;
    } else {
	printf $fh $format_chopnet,$bar x10,$space,$bar x10;
    }


    foreach $dom ( @domains ) {
	$dom_region = $dom->{'domainStart'}.'-'.$dom->{'domainEnd'};
	if ( $dom->{'source'} eq 'CHOP' ) {
	    $homo = $dom->{homoDB}.":".$dom->{'homoName'};
	    $homo .= '('.$dom->{'homoRegion'}.')' if ( $dom->{'homoRegion'} );
	} else {
	    $homo = '';
	}
	
	$method = $dom->{'source'};
	if ( $dom->{'source'} eq 'CHOP' ) {
	    printf $fh $format_chop,$dom_region,$space,$method,$space,$homo;
	} else {
	    printf $fh $format_chopnet,$dom_region,$space,$method;
	}
    }

    print $fh "//\n";
    close $fh;
    return;
}
		      


1;
