#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use Getopt::Long;


&init();


($Lok,$norsRegion,$msg,$sec,$coils,$htm,$acc) =
    &isNors($window,$secCut,$accLen,$collagenCutoff,
	    $fileHssp,$filePhd,$filePhdHtm,$fileCoils);

if ( ! $Lok ) {
    print STDERR
	"sub isNors returns error: $msg\n";
    exit(1);
}

&writeHeader($fileOut,$sec);
if ( $opt_html ) {
    &writeNorsHtml($fileSeq,$fileOut,$norsRegion,$sec,$acc,$htm,$coils);
} else {
    &writeNorsTxt($fileSeq,$fileOut,$norsRegion,$sec,$acc,$htm,$coils);
}

open (SUM,">$fileSum") or die "cannot write to $fileSum:$!";
if ( $Lok == 1 ) {
    print SUM "1\n";
} else {
    print SUM "0\n";
}
close SUM;

exit;



sub init {
				# default options
    $opt_help = '';
    $opt_debug = 0;
    $opt_html = 0;

    $window = 70;			# the window of the non-struc. length
    $secCut = 12;			# the cutoff the SS percentage
    $accLen = 10;			# at least have continuous 10 exposed residue
    $collagenCutoff = 0.3;		# sequence identity to indicate a collagen

    $minAcc = 16;		# acc threshold for exposed residue

    $style_td1 = 'background:#bcd2ee;font-family:Times,Serif';
    
    $style_td2 = 'background:#ebebeb;font-family:Times,Serif';
    $style_td3 = 'background:#e0eee0;font-family:Times,Serif';
    #$style_td3 = 'background:black;font-family:Times,Serif';

    $Lok = GetOptions ('debug!' => \$opt_debug,
		       'win=i' => \$window,
		       'secCut=i' => \$secCut,
		       'accLen=i' => \$accLen,
		       'fileSeq=s' => \$fileSeq,
		       'fileHssp=s' => \$fileHssp,
		       'filePhd=s' => \$filePhd,
		       'filePhdHtm=s' => \$filePhdHtm,
		       'fileCoils=s' => \$fileCoils,
		       'fileSum=s' => \$fileSum,
		       'o=s' => \$fileOut,
		       'html!' => \$opt_html,
		       'help'  => \$opt_help,
		       );
    
    if ( ! $Lok ) {
	print STDERR "Invalid arguments found, -h or --help for help\n";
	exit(1);
    }
    
    $nameScr = $0;
    $nameScr =~ s/.*\///g;
    
    if ( $opt_help ) {
	print STDERR
	    "$nameScr: find NORS in sequence \n",
	    "Usage: $nameScr [options]  -fileSeq seq_file -fileHssp hssp_file  \n",
	"         -filePhd phd_file -filePhdHtm phdHtm_file -fileCoils coils_file\n",
	"         -o output_file\n",
	    "  Opt:  -help         print this help\n",
	    "        -html         print HTML output(default=0)\n",
	    "        -win          window size(default=$window)\n",
	    "        -secCut       max structure content(default=$secCut)\n",
	    "        -accLen       minimum consecutive exposed residues(default=$accLen)\n",
	    "        --(no)debug   print debug info(default=nodebug)\n";
	exit(1);
    }

    if ( ! $fileSeq ) {
	&exit_error_undefine('fileSeq');
    }
    if ( ! -f $fileSeq ) {
	&exit_error_missing('fileSeq');
    } 
    if ( ! $fileHssp ) {
	&exit_error_undefine('fileHssp');
    }
    if ( ! -f $fileHssp ) {
	&exit_error_missing('fileHssp');
    }
    if ( ! $filePhd ) {
	&exit_error_undefine('filePhd');
    }
    if ( ! -f $filePhd ) {
	&exit_error_missing('filePhd');
    }
    if ( ! $filePhdHtm ) {
	&exit_error_undefine('filePhdHtm');
    }
#    if ( ! -f $filePhdHtm ) {
#	&exit_error_missing('filePhdHtm');
#    }				# 
    if ( ! $fileCoils ) {
	&exit_error_undefine('fileCoils');
    }
    if ( ! -f $fileCoils ) {
	&exit_error_missing('fileCoils');
    }
    if ( ! $fileOut ) {
	&exit_error_undefine('fileOut');
    }
    if ( ! $fileSum ) {
	$fileSum = $fileOut.'_sum';
    }
    $window++ if ( $window % 2 != 0 );

				# end of option/sanity check
    
}




sub isNors {
    my ($window,$secCut,$accLen,$collagenCutoff,
	$fileHssp,$filePhd,$filePhdHtm,$fileCoils) = @_;
    my ($maxLen,$beg,$orgDir,$seqDir,$hsspDir,$phdDir,$coilDir);
    my ($seq,$acc,$seqLen,$isCollagen,$msgCollagen,$end);
    my ($contentPhd,$ctPhdNsr,$nsrBeg,$nsrEnd,$ctNsr,$i,$nsrReg);


    $maxLen = 0;
    $beg = $window/2;
			       
    ($sec,$acc) = &norsCheckPhd($filePhd);
    $seqLen = scalar @$sec - 1;
    if ( $seqLen < $window ) {
	return (2,"NULL","seqLen=$seqLen, smaller than window size $window",$sec,undef,undef,$acc);
    }

    ( $isCollagen,$msgCollagen ) =  &isCollagen($fileHssp,$collagenCutoff);
    if ( $isCollagen ) {
	return (2,"NULL", "is collagen homolog.",$sec,undef,undef,$acc);
    }

    $fileCoilsRaw = $fileCoils."_raw";
    $coils = &norsCheckCoils($fileCoils,$fileCoilsRaw);
    
    $fileNotHtm = $filePhdHtm;
    $fileNotHtm =~ s/\..*/.phdNotHtm/;
    $htm = &norsCheckHtm($filePhdHtm,$fileNotHtm);
    
    $allSec = &getAllSec($seqLen,$sec,$coils,$htm);
    if ( $opt_debug ) {
	print STDERR "sec=\n";
	for $i (1..$seqLen) {
	    print STDERR 
		$allSec->[$i];
	}
	print STDERR "\n";
    }

    $end = $seqLen - $window/2;
    $maxLen = $end if ( $end > $maxLen );
    $contentPhd = &calcSecContent($allSec,$window,$beg,$end);


    ($ctPhdNsr,$nsrBeg,$nsrEnd) = &hasNsrPhd($window,$secCut,$contentPhd,$beg,$end);
    if ( ! $ctPhdNsr ) {
	return(2,"NULL","no NORS after PHD",$sec,$coils,$htm,$acc);
    }
				 
    ($ctNsr,$nsrBeg,$nsrEnd) = &hasNsrAcc($accLen,$ctPhdNsr,$acc,$nsrBeg,$nsrEnd);
    #print STDERR "$org,$id,ctNst=$ctNsr\n";
    if (! $ctNsr ) {
	return(2,"NULL","no NORS after ACC",$sec,$coils,$htm,$acc);
    }

    #print STDERR "$org,$id,ctNst=$ctNsr\n";
    $nsrReg = "";
    for $i ( 1..$ctNsr ) {
	$nsrReg .= $nsrBeg->[$i].'-'.$nsrEnd->[$i].',';
    }
    $nsrReg =~ s/,$//g;
    return (1,$nsrReg,"ok",$sec,$coils,$htm,$acc);

}


sub calcSecContent {
    my $sbr = "calcSecContent";
    my ($sec,$window,$beg,$end) = @_;
    my ($ctStrut,$i,@contentPhd,$winEnd,$preWin,$current );

    $ctStrut = 0;
    for $i (1..$window) {	# 
	$ctStrut++ if ( $sec->[$i]  );
    }
    $contentPhd[$beg] = $ctStrut/$window;
	
    for $i ( $beg+1..$end) {
	$winEnd = $i + $window/2;
	$preWin = $i - $window/2;
	    
	if ( $sec->[$winEnd]  ) {
	    if ( $sec->[$preWin]  ) {
		$current = $contentPhd[$i-1];
	    } else {
		$current = $contentPhd[$i-1] + 1/$window;
	    }
	} else {
	    if ( $sec->[$preWin] ) {
		if ( ! defined $contentPhd[$i-1] ) {
		    print STDERR "content for pos $i not defined.\n";
		    die;
		}
		$current = $contentPhd[$i-1] - 1/$window;
	    } else {
		$current = $contentPhd[$i-1];
	    }
	}
	$contentPhd[$i] = $current;   
    }
#   for $i ( $beg..$end ) {
#	printf "%.2f,",$contentPhd[$i];
#    }
#    print "\n";
    return [@contentPhd];
}

sub exit_error_undefine {
    my ($arg) = @_;
    print STDERR 
	"*** '$arg' not defined\n",
	"Usage: $nameScr [options]  -fileSeq seq_file -fileHssp hssp_file  \n",
	"         -filePhd phd_file -filePhdHtm phdHtm_file -fileCoils coils_file\n",
	"         -o output_file\n",
        "Try $nameScr --help for more information\n";
    exit(1);
}

sub exit_error_missing {
    my ($arg) = @_;
    print STDERR 
	"Input file '$arg' not found, exiting..\n";
    exit(1);
}

sub getAllSec {
    my ($seqLen,$sec,$coils,$htm) = @_;
    my ( $i, $allSec );

    for $i ( 1..$seqLen ) {
	if ( $sec->[$i] =~ /[he]/i or $coils->[$i] or $htm->[$i] ) {
	    $allSec->[$i] = 1;
	} else {
	    $allSec->[$i] = 0;
	}
    }
    return $allSec;
}
    

sub norsCheckCoils {
    my $sbr = "checkCoils";
    my ($coilFile,$coilFileRaw) = @_;
    my $fhCoils = "COILS_$sbr";
    my ($ctCoil,@tmpCoil,$pos,$score,$coilsRef);
    
    
    if ( -s $coilFile < 50 ) {	# no coils
	return undef;
    }

    open ( $fhCoils, $coilFileRaw ) or die "cannot open $coilFileRaw:$!";
    $ctCoil = 0;
    while ( <$fhCoils> ) {
	s/^\s+//g;
	s/\s+$//g;
	if ( $_ !~ /^\d+/ ) {
	    next;
	}
	
	@tmpCoil = split /\s+/;
	$pos = $tmpCoil[0];
	$score = $tmpCoil[4];
	if ( $score >= 0.9 ) {
	    $coilsRef->[$pos] = 1;
	    $ctCoil++;
	}
    }
    close $fhCoils;
    if ( $ctCoil < 14 ) { # error
	warn "wrong parsing coil file??\nctCoils=$ctCoil\n";
    }

    return $coilsRef;
}



sub norsCheckHtm {
    my $sbr = "checkHtm";
    my ($htmFile,$fileNotHtm) = @_;
    my $fhHtm = "HTM_$sbr";
    my ($ctHtm,@htmBeg,@htmEnd);
    my (@tmpHtm,$htmReg,$i,$h);

    
    if ( ! -f $htmFile or (-s $htmFile) < 50 or -f $fileNotHtm ) {	# no HTM
	return undef;
    }
				# phdHtm
    open ( $fhHtm, $htmFile ) or die "cannot open $htmFile:$!";
    $ctHtm = 0;
    undef @htmBeg;
    undef @htmEnd;
    while ( <$fhHtm> ) {
	if ( $_ !~ /^\#/ ) {
	    last;
	}
	if ( $_ !~ /^\# MODEL_DAT/ ) {
	    next;
	}
	
	@tmpHtm = split /,/;
	$htmReg = $tmpHtm[-1];
	$htmReg =~ s/\s+//g;
	if ( $htmReg !~ /^\d+-\d+$/ ) {
	    die "wrong htm format??\n$_\n";
	}
	
	$ctHtm++;
	($htmBeg[$ctHtm], $htmEnd[$ctHtm] ) = split /-/, $htmReg;
    }
    close $fhHtm;
    if ( $ctHtm == 0 ) {
	warn "wrong parsin htm file??\nctHtm=$ctHtm\n";
    }
	    
    for ( $i = 1; $i <= $ctHtm; $i++ ) {
	for ( $h = $htmBeg[$i]; $h <= $htmEnd[$i]; $h++ ) {
	    $htmRef->[$h] = 1;
	}
    }

    return $htmRef;
}


sub norsCheckPhd {
    my $sbr = "checkPhd";
    my ($filePhd) = @_;
    my $fhPhd = "PHD_$sbr";
    my (@cols,$colPhdNo,$i,$colAccNo,@tmp,$strut,$acc,$pos,@sec,@acc);
    
    
    open ( $fhPhd, $filePhd ) or die "cannot open $filePhd:$!";
    while ( <$fhPhd> ) {	 
	next if ( /^\#/ ) ;     
	s/^\s+|\s+$//g;
	if ( /^No/ ) {
	    @cols= split /\t/;
	    for $i ( 0..$#cols ) {
		if ( $cols[$i] eq "PHEL" ) {
		    $colPhdNo = $i;
		} elsif ( $cols[$i] eq "PREL" ) { # accessibility
		    $colAccNo = $i;
		}
	    }
	    if (! defined $colPhdNo or ! defined $colAccNo ) {
		die "column name not found in $_\n"; 
	    }		# 
	}
	
	if ( $_ !~ /^\d+\s+/ ) { 
	    next;
	}			 
	@tmp = split /\s+/;
	$pos = $tmp[0];
	$strut = lc($tmp[$colPhdNo]);
	$acc = $tmp[$colAccNo];
	$sec[$pos] = $strut;
	if ( $acc > $minAcc ) {
	    $acc[$pos] = 1;
	} else {
	    $acc[$pos] = 0;
	}
    }			       
    close $fhPhd;
    return ([@sec],[@acc]);
}



sub hasNsrAcc {
    my ($accLen,$ctPhdNsr,$acc,$phdNsrBeg,$phdNsrEnd) = @_;
    my ($ctNsrAcc,$i,$nsrBeg,$nsrEnd,$isBuried,$lenExp,$maxLenExp);
    my ($j,$accNsrBeg,$accNsrEnd);

    $ctNsrAcc=0;

    for $i ( 1..$ctPhdNsr ) {
	$nsrBeg = $phdNsrBeg->[$i];
	$nsrEnd = $phdNsrEnd->[$i];
	$isBuried = 1;
	$lenExp = 0;
	$maxLenExp=0;
	
	for $j ( $nsrBeg..$nsrEnd ) {
	    if ( ! $acc->[$j] ) {
		if ( ! $isBuried ) {
		    $maxLenExp = $lenExp if ( $lenExp > $maxLenExp );
		}
		$lenExp = 0;
		$isBuried = 1;
	    } else {
		$isBuried = 0;
		$lenExp++;
		$maxLenExp = $lenExp if ( $lenExp > $maxLenExp );
	    }
	}
	
	if ( $maxLenExp >= $accLen ) {
	    $ctNsrAcc++;
	    $accNsrBeg->[$ctNsrAcc] = $phdNsrBeg->[$i];
	    $accNsrEnd->[$ctNsrAcc] = $phdNsrEnd->[$i];
	}
    }
    if ( $ctNsrAcc ) {
	return ($ctNsrAcc,$accNsrBeg,$accNsrEnd);
    } else {
	return 0;
    }
}


	

sub hasNsrPhd {
    my $sbr = "isNsrPhd";
    my ($window,$secCut,$contentPhd,$beg,$end) = @_;
    my ($isNsrPhd,$ctPhdNsr,$i,@phdNsrEnd,@phdNsrBeg);

    undef @phdNsrBeg;
    undef @phdNsrEnd;

    $isNsrPhd = 0;
    $ctPhdNsr = 0;
    for $i ( $beg..$end) {
	if ( $contentPhd->[$i] <= $secCut/100 ) {
	    if ( ! $isNsrPhd ) {
		$isNsrPhd = 1;
		if ( $ctPhdNsr > 0 and  $phdNsrEnd[$ctPhdNsr] < ($i - $window/2)) {
		    $ctPhdNsr++;
		    $phdNsrBeg[$ctPhdNsr] = $i - $window/2 + 1;
		}
		if ( $ctPhdNsr == 0 ) {
		    $ctPhdNsr++;
		    $phdNsrBeg[$ctPhdNsr] = $i - $window/2 + 1;
		}
	    } 
	    $phdNsrEnd[$ctPhdNsr] = $i + $window/2;
	} else {		# 
	    $isNsrPhd = 0;
	}
    }
    if ( $ctPhdNsr ) {
	return ($ctPhdNsr,[@phdNsrBeg],[@phdNsrEnd]);
    } else {
	return 0;
    }

    
}


sub isCollagen {
    my ($fileHssp,$collagenCutoff) = @_;
    my $sbr = "isCollage";
    my ($msgCollagen,$posIde,$posSim,$ide,$sim );
    my ($hsspHeader);
    
 
    if ( ! -e $fileHssp ) {
	warn "$fileHssp not found.\n";
	return (0,"");
    }
    
    $fhHssp = "HSSP_$sbr";
    open ($fhHssp, $fileHssp) or die "cannot open $fileHssp:$!";
    while ($tmpLine=<$fhHssp>) {
	if ( $tmpLine =~ /^\#\# PROTEINS/ ) {
	    $hsspHeader = <$fhHssp>;
	    $posIde = index($hsspHeader,'%IDE');
	    if ( $hsspHeader =~ /\%WSIM/ ) { 
		$posSim = index($hsspHeader,'%WSIM');
	    } else {
		$posSim = index($hsspHeader,'%SIM');
	    }
	    last;
	}
    }
    while ($tmpLine=<$fhHssp>) {
	if ( $tmpLine =~ /^\#\# ALIGNMENTS/ ) {
	     last;
	 }
	if ( $tmpLine !~ /^\s*\d+\s*:/ ) {
	    next;
	}
	
	$ide = substr($tmpLine,$posIde,5);
	$sim = substr($tmpLine,$posSim,5);
	$ide =~ s/\s+//g;
	$sim =~ s/\s+//g;
	
#	print STDERR "xx ide=$ide, sim=$sim\n";

	if ( $ide !~ /\d/ or $sim !~ /\d/ ) {
	    print STDERR 
		"ide=$ide,sim=$sim\n",
		"$fileHssp: wrong parsing hssp?\n$_\n$tmpLine\n";
	    die;
	}
	
	if ( $ide > 1 or $sim > 1 ) {
	    die "$fileHssp: wrong parsing hssp?\n$_\nide=$ide,sim=$sim\n";
	}
	
	if ( $ide < $collagenCutoff and $sim < $collagenCutoff ) {
	    last;
	}
	
	if ( $tmpLine =~ /collagen/i and $tmpLine !~ /collagenase/i ) {
	    $msgCollagen .= "$fileHssp -- from hssp:\n$tmpLine";
	    last;
	}
    }
    close $fhHssp;
    if ( $msgCollagen ) {
	return (1,$msgCollagen);
    } else {
	return (0,"");
    }
}


sub readSeq {
    my ( $fileIn ) = @_;
    my $sbr = "readSeq";
    my $fhIn = "SEQ_$sbr";
    open ( $fhIn,$fileIn ) or die "cannot open $fileIn:$!";
    my $seq = "";
    while ( <$fhIn> ) {
	next if ( /^\s*\>/ );
	chomp;
	$seq .= $_;
    }
    close $fhIn;

    $seq =~ s/\W+//g;
    $seq =~ s/\d+//g;
    
    return $seq;
}


sub writeHeader {
    my ( $fileNors,$secRef) = @_;
    my ( @secType,$seqLen,$sec,%ct,$s,%percSec,$fhOut );
    @secType = qw(H E L);
    $seqLen = scalar (@$secRef) -1 ;
    for $i ( 1..$seqLen ) {
	$sec = $secRef->[$i];
	$sec = uc $sec;
	$ct{$sec}++;
    }
    foreach $s ( @secType ) {
	$ct{$s} = 0 if ( ! defined $ct{$s} );
	$percSec{$s} = $ct{$s}/$seqLen*100;
	#print "xx ",$percSec{$s},"\n";
    }

    unlink $fileNors if ( -f $fileNors ); # remove old files
    open ($fhOut,">$fileNors") or die "cannot write to $fileNors:$!";
    if ( $opt_html ) {
	print $fhOut
	    "<P>\n",
	    "<TABLE CELLPADDING=2>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Sequence length</TD>\n ",
	    "<TD style='$style_td2' > $seqLen </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Secondary structure</TD>\n ";
	printf $fhOut 
	    "<TD style='$style_td2' > Helix=%.1f%%, Strand=%.1f%%, Loop=%.1f%% </TD></TR>\n",
	     $percSec{'H'},$percSec{'E'},$percSec{'L'};
	print $fhOut
	    "<TR VALIGN=TOP> <TD BGCOLOR='#ffffff'></TD>\n ",
	    "<TD BGCOLOR='#ffffff' >&nbsp</TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>window size</TD>\n",
	    "<TD style='$style_td2' > $window </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Structure content cutoff</TD>\n",
	    "<TD style='$style_td2' > $secCut% </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Minimum consecutive exposed residues</TD>\n",
	    "<TD style='$style_td2' > $accLen </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD BGCOLOR='#ffffff'></TD>\n ",
	    "<TD BGCOLOR='#ffffff' >&nbsp</TD></TR>\n";
    } else {
	print $fhOut
	    "\n\n",
	    "Sequence length     : $seqLen\n";
	printf $fhOut
	    "Secondary structure : Helix=%.1f%%, Strand=%.1f%%, Loop=%.1f%%\n\n",
	    $percSec{'H'},$percSec{'E'},$percSec{'L'};
	print $fhOut
	    "window size         : $window\n",
	    "Structure content cutoff: $secCut%\n",
	    "Minimum consecutive exposed residues: $accLen\n\n";
    }
    				# legend
    if ( $opt_html ) {
	print $fhOut
	    			# colors: #cccccc, #ebebeb #e0eee0
	    "<P>\n",
	 #   "<TABLE CELLPADDING=2>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>NORS</TD>\n ",
	    "<TD style='$style_td2' > N=NORS region </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Secondary structure</TD>\n ",
	    "<TD style='$style_td2' > H=helix, E=strand, ' '=loop </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Coiled-coil region</TD>\n ",
	    "<TD style='$style_td2'> c=coils </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Transmembrane helix</TD>\n ",
	    "<TD style='$style_td2'> m=transmembrane helix </TD></TR>\n",
	    "<TR VALIGN=TOP> <TD style='$style_td1'>Solvent accessibility</TD>\n ",
	    "<TD style='$style_td2'> e=exposed, ' '=buried </TD></TR>\n",
	    "</TABLE>\n";
    } else {
	print $fhOut 
	    "NORS                 : n=NORS region\n",
	    "Secondary structure  : h=helix, e=strand, l=loop\n",
	    "Transmembrane helix  : m=transmembrane helix\n",
	    "Solvent accessibility: e=exposed, b=buried\n";
	    
    }

    
    close $fhOut;
    return;
}


sub writeNorsHtml {
    my ( $fileSeq,$fileNors,$norsReg,$sec,$acc,$htm,$coils ) = @_;
    my $sbr = "writeNorsHtml";
    my $fhNors = "NORS_$sbr";
    my ($seqPerLine,$lineTitleLen,$formatLineTitle,$seq,$seqLen);
    my ($i,@nors,@norsReg,$reg,$beg,$end,$nors,$ctLine);
    my ($lineEnd,$lineBeg,$c);

    $norsReg = 'None' if ( $norsReg eq 'NULL' );
    open ($fhNors,">>$fileNors") or die "cannot write to $fileNors:$!";
    print $fhNors
	"<P>\n",
	"<TABLE CELLPADDING=2>\n",
	"<TR VALIGN=TOP> <TD style='$style_td1'>NORS region predicted: </TD>\n ",
	"<TD style='$style_td3' > $norsReg </TD></TR>\n",
	"</TABLE>\n";

    if ( $norsReg eq 'None' ) {
	print $fhNors "<P>\n";
	close $fhNors;
	return;
    }
    
    
    $seqPerLine = 50;
    $lineTitleLen = 7;
    $formatLineTitle = '%-'.$lineTitleLen."s";
    $seq = &readSeq($fileSeq);
    $seqLen = length $seq;
    $color = "blue";


    for $i ( 1..$seqLen ) {
	$nors[$i] = '.';
    }
    @norsReg = split /,/,$norsReg;
    foreach $reg ( @norsReg ) {
	($beg,$end) = split /-/,$reg;
	for $i ( $beg..$end ) {
	    $norsStr[$i] = "<font color=$color>".'N'."</font>";
	}
    }

    $nors = "";
    for $i ( 1..$seqLen ) {
	if ( $sec->[$i] eq 'h' ) {
	    $secStr[$i] = "<font color=red>".'H'."</font>";
	} elsif ( $sec->[$i] eq 'e' ) {
	    $secStr[$i] = "<font color=green>".'E'."</font>";
	} else {
	    $secStr[$i] = " ";
	}

	if ( $acc->[$i] ) {
	    $accStr[$i] = "<font color=green>".'e'."</font>";
	} else {
	    $accStr[$i] = ' ';
	}

	if ( $htm->[$i] ) {
	    $htmStr[$i] = "<font color=green>".'M'."</font>";;
	} else {
	    $htmStr[$i] = ' ';
	}

	if ( $coils->[$i] ) {
	    $coilsStr[$i] = "<font color=green>".'c'."</font>";
	} else {
	    $coilsStr[$i] = ' ';
	}
    }

    for $i ( 1..$seqLen ) {
	$seq[$i] = substr($seq,$i-1,1);
    }

    if ( $seqLen % 50 == 0 ) {
	$ctLine = $seqLen/$seqPerLine;
    } else {
	$ctLine = $seqLen/$seqPerLine + 1;
    }

    print $fhNors "<PRE>\n";
    foreach $i ( 1..$ctLine ) {
	$lineEnd = $seqPerLine * $i;
	$lineBeg = $lineEnd - $seqPerLine + 1;

				# print sequence number index
	printf $fhNors $formatLineTitle,"";
	foreach $c ( $lineBeg..$lineEnd ) {
	    if ( $c == $lineEnd ) {
		print $fhNors $lineEnd/10,"\n";
		last;
	    }
	    if ( $c % 10 == 0 ) {
		print $fhNors ":";
	    } elsif ( $c % 5 == 0 ) {
		print $fhNors ".";
	    } else {
		print $fhNors " ";
	    }
	}
				
				# print sequence
	printf $fhNors $formatLineTitle,"SEQ";
	foreach $c ( $lineBeg..$lineEnd ) {
	    last if ( $c > $seqLen );
	    print $fhNors $seq[$c];
	}
	print $fhNors "\n";

				# print sequence
	printf $fhNors $formatLineTitle,"NORS";
	foreach $c ( $lineBeg..$lineEnd ) {
	    last if ( $c > $seqLen );
	    if ( ! defined $norsStr[$c] ) {
		$norsStr[$c] = " ";
	    }
	    print $fhNors $norsStr[$c];
	}
	print $fhNors "\n";
	
				# print sequence
	printf $fhNors $formatLineTitle,"SEC";
	foreach $c ( $lineBeg..$lineEnd ) {
	    last if ( $c > $seqLen );
	    print $fhNors $secStr[$c];
	}
	print $fhNors "\n";
				# print sequence
	printf $fhNors $formatLineTitle,"COILS";
	foreach $c ( $lineBeg..$lineEnd ) {
	    last if ( $c > $seqLen );
	    print $fhNors $coilsStr[$c];
	}
	print $fhNors "\n";

				# print HTM
	printf $fhNors $formatLineTitle,"HTM";
	foreach $c ( $lineBeg..$lineEnd ) {
	    last if ( $c > $seqLen );
	    print $fhNors $htmStr[$c];
	}
	print $fhNors "\n";

				# print sequence
	printf $fhNors $formatLineTitle,"ACC";
	foreach $c ( $lineBeg..$lineEnd ) {
	    last if ( $c > $seqLen );
	    print $fhNors $accStr[$c];
	}
	print $fhNors "\n";

    }
    print $fhNors 
	"//\n",
	"</PRE>\n";
    close $fhNors;
    return;
}


sub writeNorsTxt {
    my ( $fileSeq,$fileNors,$norsReg,$sec,$acc,$htm,$coils ) = @_;
    my $sbr = "writeNorsTxt";
    my $fhNors = "NORS_$sbr";
    my ($seqPerLine,$lineTitleLen,$formatLineTitle,$seq,$seqLen);
    my ($i,@nors,@norsReg,$reg,$beg,$end,$nors,$ctLine);
    my ($lineEnd,$lineBeg,$c);


    $norsReg = 'None' if ( $norsReg eq 'NULL' );
    open ($fhNors,">>$fileNors") or die "cannot write to $fileNors:$!";
    print $fhNors "\n\nNORS region          : $norsReg\n\n";
    if ( $norsReg eq 'None' ) {
	print $fhNors "//\n";
	close $fhNors;
	return;
    }

    $seqPerLine = 50;
    $lineTitleLen = 7;
    $formatLineTitle = '%-'.$lineTitleLen."s";
    $seq = &readSeq($fileSeq);
    $seqLen = length $seq;
    
    for $i ( 1..$seqLen ) {
	$nors[$i] = '.';
    }
    @norsReg = split /,/,$norsReg;
    foreach $reg ( @norsReg ) {
	($beg,$end) = split /-/,$reg;
	for $i ( $beg..$end ) {
	    $nors[$i] = 'n';
	}
    }

    $nors = "";
    for $i ( 1..$seqLen ) {
	$nors .= $nors[$i];
	$secStr .= $sec->[$i];

	if ( $acc->[$i] ) {
	    $accStr .= 'e';
	} else {
	    $accStr .= 'b';
	}

	if ( $htm->[$i] ) {
	    $htmStr .= 'm';
	} else {
	    $htmStr .= '.';
	}

	if ( $coils->[$i] ) {
	    $coilsStr .= 'c';
	} else {
	    $coilsStr .= '.';
	}

    }

	
    

    if ( $seqLen % 50 == 0 ) {
	$ctLine = $seqLen/$seqPerLine;
    } else {
	$ctLine = $seqLen/$seqPerLine + 1;
    }
    foreach $i ( 1..$ctLine ) {
	$lineEnd = $seqPerLine * $i;
	$lineBeg = $lineEnd - $seqPerLine + 1;

				# print sequence number index
	printf $fhNors $formatLineTitle,"";
	foreach $c ( $lineBeg..$lineEnd ) {
	    if ( $c == $lineEnd ) {
		print $fhNors $lineEnd/10,"\n";
		last;
	    }
	    if ( $c % 10 == 0 ) {
		print $fhNors ":";
	    } elsif ( $c % 5 == 0 ) {
		print $fhNors ".";
	    } else {
		print $fhNors " ";
	    }
	}
				# print sequence
	printf $fhNors $formatLineTitle,"seq";
	print $fhNors substr($seq,$lineBeg-1,$seqPerLine),"\n";
				# print NORS prediction
	printf $fhNors $formatLineTitle,"NORS";
	print $fhNors substr($nors,$lineBeg-1,$seqPerLine),"\n";

				# print NORS prediction
	printf $fhNors $formatLineTitle,"SEC";
	print $fhNors substr($secStr,$lineBeg-1,$seqPerLine),"\n";
				# print NORS prediction
	printf $fhNors $formatLineTitle,"COILS";
	print $fhNors substr($coilsStr,$lineBeg-1,$seqPerLine),"\n";
		# print NORS prediction
	printf $fhNors $formatLineTitle,"HTM";
	print $fhNors substr($htmStr,$lineBeg-1,$seqPerLine),"\n";
		# print NORS prediction
	printf $fhNors $formatLineTitle,"ACC";
	print $fhNors substr($accStr,$lineBeg-1,$seqPerLine),"\n";
	
    }
    print $fhNors "//\n";
    close $fhNors;
    return;
}



