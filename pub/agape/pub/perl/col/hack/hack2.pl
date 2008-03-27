#!/usr/sbin/perl -w
#
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
$#id1=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {next if (/^idSeq/);
		 $_=~s/\n//g;
		 @tmp=split(/\t/,$_);
		 next if ($#tmp<2);
		 $tmp[1]=~s/\s//g;$tmp[2]=~s/\s//g;$tmp[2]=~s/_.//g;
		 if (!defined $id2{$tmp[1]}){
		     push(@id1,$tmp[1]);
		     $id2{$tmp[1]}="$tmp[2],";}
		 else {
		     $id2{$tmp[1]}.="$tmp[2],";}}close($fhin);

$fileTmp="x".$$.".tmp";
foreach $id1(@id1){
#    last if ($id1=~/1h/);	# xx
    $id2{$id1}=~s/^,|,$//g;
    @tmp=split(/,/,$id2{$id1});%ok=0;$#id2=0;$id2="";
    foreach $tmp(@tmp){if (! defined $ok{$tmp}){push(@id2,$tmp);$id2.="$tmp,";
						$ok{$tmp}=1;}}
    $id2=~s/,$//g;
    $tmp="$id1,$id2";
    if (-e $fileTmp){system("\\rm $fileTmp");}
				# call hack
    $#prt=0;
    push(@prt,"--- now system \t 'fssp-grep-tab2.pl $tmp >> $fileTmp'\n");
    system("fssp-grep-tab2.pl $tmp >> $fileTmp");

    &open_file("$fhin", "$fileTmp");
    $fssp="";%ok=0;
    while (<$fhin>) {$_=~s/\n//;
		     @tmp=split(/\s+/,$_);
		     $tmp[2]=~s/-//g;$tmp[2]=~s/\s//g;
		     if (! defined $ok{$tmp[2]}){
			 push(@prt,"--- grep: 1=$tmp[1], 2=$tmp[2],\n");
			 $fssp.="$tmp[2] ";$ok{$tmp[2]}=1;}}close($fhin);
    push(@prt,"--- now system \t 'fssp-merge-families.pl $fssp >> $fileTmp'\n");
    if (-e $fileTmp){system("\\rm $fileTmp");}
    system("fssp-merge-families.pl $fssp >> $fileTmp");

    &open_file("$fhin", "$fileTmp");
    $#tmp=0;
    while (<$fhin>) {$_=~s/\n//;push(@tmp,$_);
		     if ($_=~/^cross/){
			 $tmp=$_;$tmp=~s/^cross\s+//g;$tmp=~s/\s//g;
			 if (length($tmp)>3){$Lok=1;}else{$Lok=0;}}}close($fhin);
    if ($Lok){
	foreach $prt(@prt){
	    print"$prt";}
	foreach $tmp(@tmp){
	    print"$tmp\n";}
	print "--- \n";
	print "--- repeat for above: $fssp\n";
	print "-" x 80, "\n";}
#    else {
#	&myprt_array("\n","xxx else",@tmp,"xx end");}
}


# &open_file("$fhout",">$fileOut"); close($fhout);

exit;
