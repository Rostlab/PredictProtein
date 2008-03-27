#!/usr/bin/perl -w
##!/usr/bin/perl
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
#  backup of OS2 onto tape (/dev/tape)
#
$[ =1 ;

				# help
if ($#ARGV<1){
    print "goal:    backup of OS2 onto tape (/dev/tape)\n";
    print "usage:   script auto\n";
    print "options: \n";
    print "         dir=x       (directories to bup 'dir1,dir2')\n";
    print "         dev=x       (default file, alternative tape=/dev/tape, dat=/dev/dat)\n";
    print "         namx=x      (maximal number of files in one go: SGI specific)\n";
    exit;}
$Lauto=0;
foreach $_(@ARGV){if   ($_=~/^dir=(.*)$/) {$dir=$1;}
		  elsif($_=~/^dev=(.*)$/) {$dev=$1;}
		  elsif($_=~/^auto/)      {$Lauto=1;}
		  elsif($_=~/^nmax=(.*)$/){$par{"nmax"}=$1;}
		  else {print"*** wrong command line arg '$_'\n";
			die;}}

if ($Lauto){$dir= "/home/rost/bin".",";
	    $dir.="/home/rost/etc".",";

	    if (1){
		$dir.="/home/rost/for".",";
		$dir.="/home/rost/max".",";
		$dir.="/home/rost/mis".",";
		$dir.="/home/rost/nn".",";
		$dir.="/home/rost/perl".",";
		$dir.="/home/rost/phd".",";
		$dir.="/home/rost/pub".",";
		$dir.="/home/rost/w/newlist".",";
		$dir.="/home/rost/w/res-phdnew".",";
#		$dir.="/home/rost/topits".",";
#		$dir.="/home/rost/w/gene".",";
#		$dir.="/home/rost/w/loci".",";
	    }
	}
else { die("*** either use 'auto' or provide dir to bup 'dir1,dir2'\n") if (! defined $dir);}
    
$dir=~s/^,|,$|\s//g;
@dir=split(/,/,$dir);

$dev="/dev/tape"    if (  defined $dev && $dev eq "tape");
$dev="/dev/dat"     if (  defined $dev && $dev eq "dat");
$dev="/dev/tape"    if (! defined $dev);

$cmdTar="tar -cvf $dev ";

$par{"nmax"}=1000;
$par{"nmax"}=500;

$#file=0;
foreach $dir (@dir){
    push(@file,&fileLsAll($dir));	# list all files (should be local after chdir)
}

				# ------------------------------
				# do the tar
$numRepeat=1+int($#file/$par{"nmax"});
$cmdTarRepeat=$cmdTar;$cmdTarRepeat=~s/\-c/\-r/;


foreach $it (1..$numRepeat){
    $itBeg=1 + ($it-1) * $par{"nmax"};
    $itEnd=$itBeg + $par{"nmax"} - 1; 
    $itEnd=$#file               if ($#file < $itEnd);

    $tmp=join(' ',@file[$itBeg..$itEnd]);

    if ($it == 1 ){		# first time: generate tar
        print "--- $cmdTar  (files $itBeg - $itEnd)\n";
        system("$cmdTar $tmp");
    }
    else {                      # then: append
        print "--- $cmdTarRepeat (files $itBeg - $itEnd)\n";
        system("$cmdTarRepeat $tmp");
    }
}
				# ------------------------------
				# verify reading
@tmp=`tar -tf $dev`;

print "--- output in $fileTar\n";
print "--- verify found ",$#tmp," files, expected was: ",$#file,"\n";

$file="VERIFY-bup-OS2.tmp"; 
open("FHOUT",">$file");foreach $tmp(@tmp){$tmp=~s/\n|\r//g;print FHOUT "$tmp\n";}close(FHOUT);
print "--- output from verify into $file\n";
exit;


#==========================================================================================
sub fileLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   dirLsAll                    will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    return(0) if (! -d $dirLoc);		# directory empty
    $sbrName="dirLsAll";$fhinLoc="FHIN"."$sbrName";$#tmp=0;
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g;
		       if (-e $_){
			   push(@tmp,$_);}}close($fhinLoc);
    return(@tmp);
}				# end of dirLsAll

