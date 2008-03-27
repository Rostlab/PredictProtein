#!/usr/sbin/perl -w
#
#  applies 'triangle' to pairs of identifiers:
#     A = B, B = C and C != A, then correction: C = A
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   applies 'triangle' to pairs of identifiers:\n";
	      print"           A = B, B = C and C != A, then correction: C = A\n";
	      print"usage:  script file-true \n";
	      print"format:      idA   idA1,idA2,idA3, ...)\n";
	      print"             idB   idB1,id!2,idB3, ...)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");
$#id=0;
while (<$fhin>) {
    $_=~s/\n//g;$_=~s/^\s*|\s*$//g;
    @tmp=split(/\s+/,$_);
    if    ($#tmp>1) {$id=$tmp[1];$list=$tmp[2];
		     push(@id,$id);$ali{$id}=$list;}
    elsif ($#tmp==1){$id=$tmp[1];$list="$id";
		     push(@id,$id);$ali{$id}=$list;}
}
close($fhin);
				# insert all into all
&open_file("$fhout",">$fileOut"); 

foreach $id1 (@id){
    $tmp2=$ali{$id1};$tmp2=~s/^,*|,*$//g;
    @id2=split(/,/,$tmp2);
    undef %tmp; $#newId2=0;
    foreach $id2 (@id2){	# split direct
	if (! defined $tmp{$id2}){
	    $tmp{$id2}=1;push(@newId2,$id2);

	    next if ( ! defined $ali{$id2});
	    $tmp3=$ali{$id2};$tmp3=~s/^,*|,*$//g;
	    @id3=split(/,/,$tmp3);
#	    $Lok=0;
	    foreach $id3 (@id3){ # split in-direct
				# only if not chain
		next if (length($id3)>4);
		if (! defined $tmp{$id3}){
#		    $add.="$id3,";$Lok=1;
		    $tmp{$id3}=1;push(@newId2,$id3);}
	    }
#	    print "add from $id2\n" if ($Lok);
	}
    }
    $new="";@tmp=sort @newId2;@newId2=@tmp;
    foreach $id2 (@newId2){
	$new.="$id2,";}
    $new=~s/,*$//g;
    print $fhout "$id1\t$new\n";
#    print  "$id\t$new\n";
#    print  "   \t$add\n";
    print "xx id1=$id1, old=",$#id2,", new=",$#newId2,"\n";
}

close($fhout);

print "--- output in $fileOut\n";
exit;
