#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

package subx;

INIT: {
}

#===============================================================================
sub subx {
#-------------------------------------------------------------------------------
#   subx                   package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0



    @ARGV=@_;			# pass from calling


				# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   {$dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)     {$ARCH=$1;}
	elsif ($arg=~/PWD=(.*)$/)      {$PWD=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }

    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 


    return(1,"ok $sbrName");
}				# end of subx

