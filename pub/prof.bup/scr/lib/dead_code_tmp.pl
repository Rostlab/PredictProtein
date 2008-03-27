#!/usr/bin/perl
#				# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    if (0){
	print "\nxx "."-" x 50 ,"\n","xx before :\n","xx "."-" x 50 ,"\n";
	foreach $itres (1..$hssp{"numres"}){
	    printf "%3d ",$itres;
	    # profiles
	    $sum=0;
	    foreach $aa (@aa){
		printf "%3d",$hssp{"prof",$aa,$itres};
		$sum+=$hssp{"prof",$aa,$itres};
	    }
	    print " s=$sum\n";
	}
    }
				# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx




				# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    if (0){			# xx
	print "xx "."-" x 50 ,"\n","xx after :\n","xx "."-" x 50 ,"\n";
	foreach $itres (1..$hssp{"numres"}){
	    printf "%3d ",$itres;
	    # profiles
	    $sum=0;
	    foreach $aa (@aa){
		printf "%3d",$hssp{"prof",$aa,$itres};
		$sum+=$hssp{"prof",$aa,$itres};
	    }
	    print " s=$sum\n";
	}
#	die;
    }
				# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    if (1){			# xx
	print "\nxx\n";
	foreach $itres (1..$hssp{"numres"}){
	    printf "xx %3d %-s  : ",$itres,$hssp{"seq",$itres};
	    foreach $tmpAA (@aa){
		printf "%3d",$hssp{"prof",$tmpAA,$itres};
	    }print "\n";}
#	die;
    }




	    if (0){
		printf "xx %3d %-s  : ",$itres,$prot{"seq",$itres};
		foreach $tmpAA (@aa){
		    printf "%3d",$prot{$tmpAA,$itres};
		}print "\n";}
