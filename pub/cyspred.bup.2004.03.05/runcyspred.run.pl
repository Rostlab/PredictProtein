#!/usr/local/bin/perl -w

# This is perl version of original runcyspred.run
#                                       wind  Ent Hyd Charg Weight
#../bin/Profil ../FILE/<protp>. trainbox.p 11   1   0   0     0
#
package RunCyspred;

#sub voidSub{
#    $fileOne =  $ARGV[0]; # read from the command line
#    $fileTwo =  $ARGV[1]; # read from the command line
#    $fileThree =  $ARGV[2]; # read from the command line
    
#    if (!defined $fileOne ){
#	$msg = "**ERROR WebService::runCyspred Description: fasta file requierd\n";
#	return ($msg);
#    }
 #   else{
#	open (FHANDLE1, $fileOne) || die ("**ERROR WebService::runCyspred Description: Could not open $fileOne");
#	@fastaFile = <FHANDLE1>;
#	foreach $tmp(@fastaFile){
#	    $strFasta.=$tmp;
#	}
#	close FHANDLE2;
#    }
    
#    if (!defined $fileTwo ){
#	$msg =  "**ERROR WebService::runCyspred Description: hssp file requierd\n";
#	return ($msg)
#	}
#    else{
#	open (FHANDLE2, $fileTwo) || die ("**ERROR WebService::runCyspred Description: Could not open $fileTwo");
#	@hsspFile = <FHANDLE2>;
#	foreach $tmp(@hsspFile){
#	    $strHssp.=$tmp;
#	}
#	close FHANDLE2;
#    }
    

#    ($code, $msg) = 
#    runCyspred( $strFasta, $strHssp, $fileThree );
#	runCyspred( $fileOne, $fileTwo, $fileThree );
#    print $msg,"\n";
#}
sub runCyspred{
    my ( $inFasta, $inHssp, $outFileName ) = @_;
    

    open (FOUT,"/home/ppuser/cyspredWS.log");
    print FOUT "Line 50 $inFasta\n";

    return  (1,"***ERROR: RunCyspred::runCyspred Description: Fasta File missing")
	if (! defined $inFasta);

    return (1,"***ERROR: RunCyspred::runCyspred Description: Hssp File missing")
	if (! defined $inHssp) ;

    if (!defined $outFileName ){
	$fileOut = 'Results.out';
    }else{ 
	$fileOut=$outFileName;
    }
    print FOUT "Line 63\n";
    $CYSPREDIR = $ENV{"CYSPREDIR"} if (defined $ENV{"CYSPREDIR"}) ; 

    system "cp $inFasta ./1mia_";
    system "cp $inHssp ./1mia.hssp";
    system "echo '//' >> ./1mia.hssp";
    system "$CYSPREDIR/bin/mkNspi.pl ./1mia_ > ./1mia_.Nspi 2> ./num.cys";

    chomp($ctCys = `cat num.cys`);
    if ( $ctCys == 0 ) {		# No cys found in the sequence
	system "echo 'No cys in the sequence.' > $fileOut";
	unlink ("num.cys", "1mia_", "1mia.hssp", "1mia_.Nspi");
	open (FHANDLE, $fileOut);
	@fOut = <FHANDLE>;
	foreach $tmp(@fOut){print "$tmp";}
	return @fOut;
    }
    print FOUT "Line 63\n";
#net 0

    system "$CYSPREDIR/bin/Profil 1mia_ trainbox.p 11 1 0 0 1 >/dev/null";
    system "cp $CYSPREDIR/253_23_11/NETDEF.NET .";
    system "cp $CYSPREDIR/253_23_11/WEIGHT.BIN .";
    system "$CYSPREDIR/bin/net 0 >/dev/null";
    rename "scrittura", "net0.out";

#net 1

    system "$CYSPREDIR/bin/Profil 1mia_ trainbox.p 15 1 0 1 1 >/dev/null"; 
    system "cp $CYSPREDIR/375_25_15/NETDEF.NET .";
    system "cp $CYSPREDIR/375_25_15/WEIGHT.BIN .";
    system "$CYSPREDIR/bin/net 0 >/dev/null";
    rename "scrittura", "net1.out";

#net 2

    system "$CYSPREDIR/bin/Profil 1mia_ trainbox.p 17 0 0 0 1 >/dev/null";
    system "cp $CYSPREDIR/391_23_17/NETDEF.NET .";
    system "cp $CYSPREDIR/391_23_17/WEIGHT.BIN .";
    system "$CYSPREDIR/bin/net 0 >/dev/null";
    rename "scrittura", "net2.out";

#net 3

    system "$CYSPREDIR/bin/Profil 1mia_ trainbox.p 15 1 1 0 1 >/dev/null";
    system "cp $CYSPREDIR/660_44_15/NETDEF.NET .";
    system "cp $CYSPREDIR/660_44_15/WEIGHT.BIN .";
    system "$CYSPREDIR/bin/net 0 >/dev/null";
    rename "scrittura", "net3.out";

#net 4

    system "$CYSPREDIR/bin/Profil 1mia_ trainbox.p 15 1 1 1 1 >/dev/null";
    system "cp $CYSPREDIR/690_46_15/NETDEF.NET .";
    system "cp $CYSPREDIR/690_46_15/WEIGHT.BIN .";
    system "$CYSPREDIR/bin/net 0 >/dev/null";
    rename "./scrittura", "./net4.out";

# jury

    system "$CYSPREDIR/bin/juryR.pl ./1mia_.Nspi ./net*.out > $fileOut"; 

    print FOUT "Line 125\n";
    
    open (FHANDLE, $fileOut);
    @fOut = <FHANDLE>;
    close FHANDLE;
    foreach $tmp(@fOut){
	$res.=$tmp;
    }
    print FOUT "Line 133\n";
# delete everything
    system "rm -f ./1mia* ./net*.out ./NETDEF.NET ./WEIGHT.BIN ./trainbox.p ./fil-pes_ab.dat ./num.cys ./$fileOut";
    return $res;

}				


