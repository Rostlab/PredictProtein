#!/usr/local/bin/perl -w

# This is perl version of original runcyspred.run
#                                       wind  Ent Hyd Charg Weight
#../bin/Profil ../FILE/<protp>. trainbox.p 11   1   0   0     0
#
package RunCyspred;

#&runCyspred;
   
sub runCyspred{
    $[ =1; 
    $scr = $0;
    
    $CYSPREDIR = $ENV{"CYSPREDIR"} if (defined $ENV{"CYSPREDIR"}) ;

# reading in argument
    if ($#ARGV < 2) {
	print "$scr needs at least two arguments. quiting...\n";
	exit;
    } else {
	system "cp $ARGV[1] ./1mia_";
	system "cp $ARGV[2] ./1mia.hssp";
    }
    if ($#ARGV >= 3) {
	$fileOut = $ARGV[3];
    } else {
	$fileOut = 'Results.out';
    }

    print $ARGV[1]."\n";
    print $ARGV[2]."\n";
    print $ARGV[3]."\n";
    system "echo '//' >> ./1mia.hssp";
    system "$CYSPREDIR/bin/mkNspi.pl ./1mia_ > ./1mia_.Nspi 2> ./num.cys";

    chomp($ctCys = `cat num.cys`);
    if ( $ctCys == 0 ) {		# No cys found in the sequence
	system "echo 'No cys in the sequence.' > $fileOut";
	unlink ("num.cys", "1mia_", "1mia.hssp", "1mia_.Nspi");
	open (FHANDLE, $fileOut);
	@fOut = <FHANDLE>;
#	foreach $tmp(@fOut){print "$tmp";}
#	return 1;
	return @fOut;
#exit;
    }



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

# delete everything
    
    system "rm -f ./1mia* ./net*.out ./NETDEF.NET ./WEIGHT.BIN ./trainbox.p ./fil-pes_ab.dat ./num.cys";
    open (FHANDLE, $fileOut);
    @fOut = <FHANDLE>;
#    return 1;
    return @fOut;
}				
#exit;
				# 
1;

