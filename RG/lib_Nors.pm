package      lib_Nors;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(&isNors &writeNorsTxt &writeNorsHtml);

local $[ = 0;

sub isNors {
    my ($fileHssp,$filePhd,$filePhdHtm,$fileCoils) = @_;
    my ($window,$secCut,$accLen,$collagenCutoff);
    my ($maxLen,$beg,$orgDir,$seqDir,$hsspDir,$phdDir,$coilDir);
    my ($seq,$acc,$seqLen,$isCollagen,$msgCollagen,$end);
    my ($contentPhd,$ctPhdNsr,$nsrBeg,$nsrEnd,$ctNsr,$i,$nsrReg);

    if ( ! -f $fileHssp ) {
	return (0,"NULL","HSSP file $fileHssp not found");
    }
    if ( ! -f $filePhd ) {
	return (0,"NULL","PHD file $filePhd not found");
    }

    if ( ! -f $filePhdHtm ) {
	return (0,"NULL","HTM file $filePhdHtm not found");
    }				# 
    
    if ( ! -f $fileCoils ) {
	return (0,"NULL","COILS file $fileCoils not found");
    }				# 

    $window = 70;			# the window of the non-struc. length
    $secCut = 12;			# the cutoff the SS percentage
    $accLen = 10;			# at least have continuous 10 exposed residue
    $collagenCutoff = 0.3;		# sequence identity to indicate a collagen
    

    $maxLen = 0;
    $beg = $window/2;
			       
    ($sec,$acc) = &norsCheckPhd($filePhd);
    $seqLen = scalar @$sec;
    if ( $seqLen < $window ) {
	return (2,"NULL","seqLen=$seqLen, smaller than window size $window"); # 
    }

    ( $isCollagen,$msgCollagen ) =  &isCollagen($fileHssp,$collagenCutoff);
    if ( $isCollagen ) {
	return (2,"NULL", "is collagen homolog.");
    }

    $fileCoilsRaw = $fileCoils."_raw";
    $sec = &norsCheckCoils($sec,$fileCoils,$fileCoilsRaw);
    
    $fileNotHtm = $filePhdHtm;
    $fileNotHtm =~ s/\..*/.phdNotHtm/;
    $sec = &norsCheckHtm($sec,$filePhdHtm,$fileNotHtm);
    

    $end = $seqLen - $window/2;
    $maxLen = $end if ( $end > $maxLen );
    $contentPhd = &calcSecContent($sec,$window,$beg,$end);


    ($ctPhdNsr,$nsrBeg,$nsrEnd) = &hasNsrPhd($window,$secCut,$contentPhd,$beg,$end);
    if ( ! $ctPhdNsr ) {
	return(2,"NULL","no NORS after PHD");
    }
				 
    ($ctNsr,$nsrBeg,$nsrEnd) = &hasNsrAcc($accLen,$ctPhdNsr,$acc,$nsrBeg,$nsrEnd);
    #print STDERR "$org,$id,ctNst=$ctNsr\n";
    if (! $ctNsr ) {
	return(2,"NULL","no NORS after ACC");
    }

    #print STDERR "$org,$id,ctNst=$ctNsr\n";
    $nsrReg = "";
    for $i ( 1..$ctNsr ) {
	$nsrReg .= $nsrBeg->[$i].'-'.$nsrEnd->[$i].',';
    }
    $nsrReg =~ s/,$//g;
    return (1,$nsrReg,"ok");

}


sub calcSecContent {
    my $sbr = "calcSecContent";
    my ($sec,$window,$beg,$end) = @_;
    my ($ctStrut,$i,@contentPhd,$winEnd,$preWin,$current );

    $ctStrut = 0;
    for $i (1..$window) {	# 
	$ctStrut++ if ( $sec->[$i-1] ne 'l' );
    }
    $contentPhd[$beg] = $ctStrut/$window;
	
    for $i ( $beg+1..$end) {
	$winEnd = $i + $window/2;
	$preWin = $i - $window/2;
	    
	if ( $sec->[$winEnd-1] ne 'l' ) {
	    if ( $sec->[$preWin-1] ne 'l' ) {
		$current = $contentPhd[$i-1];
	    } else {
		$current = $contentPhd[$i-1] + 1/$window;
	    }
	} else {
	    if ( $sec->[$preWin-1] ne 'l' ) {
		$current = $contentPhd[$i-1] - 1/$window;
	    } else {
		$current = $contentPhd[$i-1];
	    }
	}
	$contentPhd[$i] = $current;   
    }
#    for $i ( $beg..$end ) {
#	printf "%.2f,",$contentPhd[$i];
#    }
#    print "\n";
    return [@contentPhd];
}



sub norsCheckCoils {
    my $sbr = "checkCoils";
    my ($secRef,$coilFile,$coilFileRaw) = @_;
    my $fhCoils = "COILS_$sbr";
    my ($ctCoil,@tmpCoil,$pos,$score);
    
    
    if ( -s $coilFile < 50 ) {	# no coils
	return $secRef;
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
	    if ( ! defined $sec->[$pos-1] ) {
		print $id."\t".$pos."\n"."@$sec\n";
		print "seqLen=$seqLen\n";
		die;
	    }
	    if ( $secRef->[$pos-1] eq 'l' ) { 
		$secRef->[$pos-1] = 'c';
	    }
	    $ctCoil++;
	}
    }
    close $fhCoils;
    if ( $ctCoil < 14 ) { # error
	warn "wrong parsing coil file??\nctCoils=$ctCoil\n";
    }

    return $secRef;
}



sub norsCheckHtm {
    my $sbr = "checkHtm";
    my ($secRef,$htmFile,$fileNotHtm) = @_;
    my $fhHtm = "HTM_$sbr";
    my ($ctHtm,@htmBeg,@htmEnd);
    my (@tmpHtm,$htmReg,$i,$h);

    
    if ( -s $htmFile < 50 or -f $fileNotHtm ) {	# no HTM
	return $secRef;
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
	    die "wrong htm format??\n$org: $id\n$_\n";
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
	    if ( ! defined $sec->[$h-1] ) {
		die "$org,$id-- HTM out of bound at res No. $h\n";
	    }
	    if ( $secRef->[$h-1] eq 'l' ) {
		$secRef->[$h-1] = 'm';
	    }
	}
    }

    return $secRef;
}


sub norsCheckPhd {
    my $sbr = "checkPhd";
    my ($filePhd) = @_;
    my $fhPhd = "PHD_$sbr";
    my (@cols,$colPhdNo,$i,$colAccNo,@tmp,$strut,$acc,@sec,@acc);
    
    
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
	$strut = lc($tmp[$colPhdNo]);
	$acc = $tmp[$colAccNo];
	push @sec, $strut;
	push @acc, $acc;
	
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
	    if ( $acc->[$j-1] < 16 ) {
		if ( ! $isBuried ) {
		    $maxLenExp = $lenExp if ( $lenExp > $maxLenExp );
		}
		$lenExp = 0;
		$isBuried = 1;
	    } else {
		    #print $j.",";
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
    
    open (HSSP, $fileHssp) or die "cannot open $fileHssp:$!";
    while (<HSSP>) {
	if ( /^\#\# PROTEINS/ ) {
	    $hsspHeader = <HSSP>;
	    $posIde = index($hsspHeader,'%IDE');
	    if ( $hsspHeader =~ /\%WSIM/ ) { 
		$posSim = index($hsspHeader,'%WSIM');
	    } else {
		$posSim = index($hsspHeader,'%SIM');
	    }
	    last;
	}
    }
    while (<HSSP>) {
	if ( /^\#\# ALIGNMENTS/ ) {
	     last;
	 }
	if ( $_ !~ /^\s*\d+\s*:/ ) {
	    next;
	}
	
	$ide = substr($_,$posIde,5);
	$sim = substr($_,$posSim,5);
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
	
	if ( $_ =~ /collagen/i and $_ !~ /collagenase/i ) {
	    $msgCollagen .= "$fileHssp -- from hssp:\n$_";
	    last;
	}
    }
    close HSSP;
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


sub writeNorsHtml {
    my ( $fileSeq,$fileNors,$norsReg ) = @_;
    my $sbr = "writeNorsHtml";
    my $fhNors = "NORS_$sbr";
    my ($seqPerLine,$lineTitleLen,$formatLineTitle,$seq,$seqLen);
    my ($i,@nors,@norsReg,$reg,$beg,$end,$nors,$ctLine);
    my ($lineEnd,$lineBeg,$c);


    if ( $norsReg eq 'NULL' ) {
	return;
    }

    
    $seqPerLine = 50;
    $lineTitleLen = 7;
    $formatLineTitle = '%-'.$lineTitleLen."s";
    $seq = &readSeq($fileSeq);
    $seqLen = length $seq;
    $color = "blue";
    
    
    for $i ( 1..$seqLen ) {
	$nors[$i] = substr($seq,$i-1,1);;
    }
    @norsReg = split /,/,$norsReg;
    foreach $reg ( @norsReg ) {
	($beg,$end) = split /-/,$reg;
	for $i ( $beg..$end ) {
	    $nors[$i] = "<font color=$color>".$nors[$i]."</font>";
	}
    }

   
    open ($fhNors,">$fileNors") or die "cannot write to $fileNors:$!";
    print $fhNors 
	"<PRE>\n",
	"\n\n",
	"Sequence length : $seqLen\n", 
	"NORS region     : $norsReg\n\n";

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
				
				# print NORS prediction
	printf $fhNors $formatLineTitle,"NORS";
	foreach $c ( $lineBeg..$lineEnd ) {	
	    last if ( $c > $seqLen );
	    if ( ! defined $nors[$c] ) {
		print STDERR "xx NORS in $c not defined\n";
		die;
	    }
	    print $fhNors $nors[$c];
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
    my ( $fileSeq,$fileNors,$norsReg ) = @_;
    my $sbr = "writeNorsTxt";
    my $fhNors = "NORS_$sbr";
    my ($seqPerLine,$lineTitleLen,$formatLineTitle,$seq,$seqLen);
    my ($i,@nors,@norsReg,$reg,$beg,$end,$nors,$ctLine);
    my ($lineEnd,$lineBeg,$c);


    if ( $norsReg eq 'NULL' ) {
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
    }

    open ($fhNors,">$fileNors") or die "cannot write to $fileNors:$!";
    print $fhNors 
	"\n\n",
	"Sequence length : $seqLen\n", 
	"NORS region     : $norsReg\n\n";

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
    }
    print $fhNors "//\n";
    close $fhNors;
    return;
}


1;









