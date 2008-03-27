#!/usr/sbin/perl -w
#
#  adds percentages to output from hoppFromDet.pl 
#       (hoppFromDet.pl Matrix-cross-hssp4698.dat res/detT-all.dat res/detF-all.dat)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   adds percentages to output from hoppFromDet.pl\n";
	      print"usage:  script Out-hopping.dat\n";
	      exit;}

$fileIn=$ARGV[1];$fhin="FHIN";$fhout="FHOUT";$fileOut="Out-".$fileIn;
				# ------------------------------
				# read hopp file
&open_file("$fhin", "$fileIn");$#rd=0;$#header=0;
while (<$fhin>) {$_=~s/\n//g;
		 if (/^\#/)  {push(@header,$_);
			      next;}
		 if (/^dist/){$header=$_; # get names
			      next;}
		 push(@rd,$_);}close($fhin);
				# ------------------------------
				# interpret names
$#tmp=0;$header=~s/^\s+|\s+$//g; # purge leading blanks
@col=split(/\s+/,$header);
foreach $it(1..$#col){$col=$col[$it];
		      $ptr{"$col"}=$it;	# store pointers
		      next if ($col !~ /^nTC/); # extract only columns with 'nTC*'
		      $tmp=$col;$tmp=~s/^nTC//g;$tmp=~s/\s//g;
		      push(@tmp,$tmp);}
@uniq=@tmp;			# store unique identifiers
				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
				# --------------------
foreach $header(@header){	# print header
    print $fhout "$header\n";}
				# --------------------
print $fhout "dist";		# print column names
foreach $uniq (@uniq){		# new ones
    print $fhout "\tp$uniq\tpC$uniq";}
foreach $it   (2..$#col){	# old ones
    print $fhout "\t$col[$it]";}
print $fhout "\n";
				# --------------------
				# now all rows
foreach $rd (@rd){
    $rd=~s/^\s*|\s*$//g;
    @tmp=split(/\t/,$rd);
    print $fhout $tmp[1];	# distance
    foreach $uniq (@uniq){
	print "xx try uniq=$uniq,\n";
				# simple percentage
	$kwdt="nT".$uniq;$kwdf="nF".$uniq;
	$ptrt=$ptr{"$kwdt"};$ptrf=$ptr{"$kwdf"};
	$tmp=$tmp[$ptrt]+$tmp[$ptrf];
	if ($tmp>0){$res=100*($tmp[$ptrt]/$tmp);}else{$res=0;}
	print $fhout "\t",$res;
				# cumulative percentage
	$kwdt="nTC".$uniq;$kwdf="nFC".$uniq;
	$ptrt=$ptr{"$kwdt"};$ptrf=$ptr{"$kwdf"};
	$tmp=$tmp[$ptrt]+$tmp[$ptrf];
	if ($tmp>0){$res=100*($tmp[$ptrt]/$tmp);}else{$res=0;}
	print $fhout "\t",$res;
    }
    foreach $it (2..$#tmp){
	print $fhout "\t",$tmp[$it];}
    print $fhout "\n";
}

close($fhout);

print "--- output in $fileOut\n";
exit;
