#!/usr/bin/perl -w
#----------------------------------------------------------------------
# extract_fssp_header
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	extract_fssp_header.pl list of fssp files
#
# task:		extract seq from fssp which have certain features (e.g. %id>x)
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			July,	        1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "extract_fssp_header";
$script_goal      = "extract seq from fssp which have certain features (e.g. %id>x)";
$script_input     = "list of fssp files";
$script_opt_ar[1] = "cut_off lower seq_id, 2nd arg or: low=";
$script_opt_ar[2] = "cut_off upper seq_id, 3rd arg or: up=";
$script_opt_ar[3] = "file_constraint     , 4th arg or: file=".
    "\n--- \t \t means pairs if match id (2nd seq) found in file ";

push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
@Date = split(' ',&ctime(time)) ; shift (@Date) ; 

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {
    &myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
    &myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
    for ($it=1; $it<=$#script_opt_ar; ++$it) {
	print"--- opt $it: \t $script_opt_ar[$it] \n"; 
    } &myprt_empty; 
    exit;
}

#----------------------------------------
# about script
#----------------------------------------
&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
for ($it=1; $it<=$#script_opt_ar; ++$it) {
    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
} &myprt_empty; 

#----------------------------------------
# read input
#----------------------------------------
$file_in	= $ARGV[1]; 	

				# ini
$lower_seqide= 0;$upper_seqide= 99;
$file_constr="unk";
				# read other input arguments
foreach $it (2..$#ARGV){
    if    ($ARGV[$it]=~/low=/) {$lower_seqide=$ARGV[$it];$lower_seqide=~s/low=//g;}
    elsif ($ARGV[$it]=~/up=/)  {$upper_seqide=$ARGV[$it];$upper_seqide=~s/up=//g;}
    elsif ($ARGV[$it]=~/file=/){$file_constr=$ARGV[$it];$file_constr=~s/file=//g;}
    elsif ($it==2)             {$lower_seqide=$ARGV[$it]}
    elsif ($it==3)             {$upper_seqide=$ARGV[$it];}
    elsif ($it==4)             {$file_constr=$ARGV[$it];}
}

&myprt_txt("file in: \t \t $file_in"); 
&myprt_txt("lower seqide:     \t $lower_seqide");
&myprt_txt("upper seqide:     \t $upper_seqide");
&myprt_txt("constraint search:\t $file_constr");

#------------------------------
# defaults
#------------------------------

$dir_fssp="/data/fssp/"; $ext_fssp="_dali.fssp";
$Lheader=1;
@des=("IDE","LALI","STRID1","STRID2","RMSD");

$file_out="Out_"."$file_in"; $file_out=~s/\.list//g; 
$file_out.="_"."$lower_seqide"."-"."$upper_seqide"; 

$file_outgr=$file_out; $file_outgr=~s/Out/Gr/;
$file_hist=$file_out; $file_hist=~s/Out/Hist/;
$file_histocc=$file_out; $file_histocc=~s/Out/Hist_occ/;
$file_idok=$file_out; $file_idok=~s/Out/Out_ok/;
$file_idnot=$file_out; $file_idnot=~s/Out/Out_not/;
$fhout="FHOUT";$fhoutgr="FHOUT_GR";$fhhist="FHOUT_HIST";$fhhistocc="FHOUT_HISTOCC";
$fhidok="FHOUT_IDOK";$fhidnot="FHOUT_IDNOT";
$fhin_constr="FHIN_CONSTR";

if (-e $file_constr) {$file_outgr.="_constr";
		      $file_hist.="_constr";
		      $file_histocc.="_constr";
		      $file_idok.="_constr";
		      $file_idnot.="_constr";
		      $file_out.="_constr";}
				# unique ending
$file_outgr.=".c";$file_hist.=".c";$file_histocc.=".c";
$file_idok.=".c";$file_idnot.=".c"; $file_out.=".c";

&myprt_txt("file out:  \t \t $file_out");
&myprt_txt("file graph:\t \t $file_outgr");
&myprt_txt("file hist: \t \t $file_hist");
if (-e $file_constr){
    &myprt_txt("file hist occ:  \t $file_histocc"); }
&myprt_txt("file id ok:\t \t $file_idok");
&myprt_txt("file id not:  \t $file_idnot");
&myprt_empty;

#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); exit; }

#----------------------------------------
# read list
#----------------------------------------
&open_file("FILE_INLIST", "$file_in");
&open_file("$fhout", ">$file_out");
&open_file("$fhoutgr", ">$file_outgr");

				# read the constraints
$#id_constr=0;
if (-e $file_constr){ 
    &open_file("$fhin_constr", "$file_constr");
    while(<$fhin_constr>){$_=~s/\n|\s//g;
			  if (length($_)<1){next;}
			  $_=~s/.*\/|\..*//g;
			  push(@id_constr,$_);
		      }close($fhin_constr);}
    

foreach $i ($lower_seqide..$upper_seqide){$histo{$i}=0;} # initialise histogram counts
$ctprot=0; $ctprotok=0; $cthits=0;

$#idrd=$#idok=$#idnot=0;
undef %flag;
while ( <FILE_INLIST> ) {
    $tmp=$_;$tmp=~s/\s|\n//g;
    if (length($tmp)>1) {
	++$ctprot;
	if (length($tmp)==4) {
	    $file_infssp="$dir_fssp"."$tmp"."$ext_fssp";
	} elsif (length($tmp)==5) {
	    $file_infssp="$dir_fssp"."$tmp"."$ext_fssp";
	} elsif ($tmp=~/^\/data/) {
	    $file_infssp=$tmp;
	} else {
	    print "*** ERROR: length wrong for:$tmp|\n"; exit;
	}
	if (-e $file_infssp) {
	    $tmpid=$file_infssp;$tmpid=~s/.*\/|\.fssp.*//g;
	    push(@idrd,$tmpid);
	    printf "file:%-28s seq id > %3d for:\n",$file_infssp, $lower_seqide;
	    print $fhout "file:$file_infssp\n";
	    &open_file("FILE_INFSSP", "$file_infssp");

	    while ( <FILE_INFSSP> ) { last if (/^\#\# PROTEINS|^\#\# SUMMARY/); }
	    $#arprint=0;
	    while ( <FILE_INFSSP> ) {
		$_=~s/^\s*//g;
		last if ( (length($_)<2) || (/^\#\# ALI/) ) ;
		if ( (/^NR\./) && ($Lheader) ) { 
		    $tmp1=substr($_,1,66); push(@arprint,$tmp1);
		    @tmp=split(/\s+/,$_);
		    $it=0;
		    foreach $tmp (@tmp){
			++$it;
			foreach $des (@des) {if ($tmp =~ /$des/) { $pos{"$des"}=$it; last; }}
		    }
		    if ($cthits==0){
			foreach$des(@des){if($des eq $des[$#des]){print $fhoutgr "$des\n";}
					  else {                  print $fhoutgr "$des\t";}}}
		} else {
		    @tmp=split(/\s+/,$_);
		    foreach $des (@des) {
			$tmp=$pos{"$des"};
			$rd{"$des"}=$tmp[$tmp];$rd{"$des"}=~s/\s//g;}
		    $flag=0;
		    if ( ($rd{"IDE"}>=$lower_seqide)&&($rd{"IDE"}<=$upper_seqide) ) {$flag=1;}
		    if ($flag && ($#id_constr>0)) {
			$flag=0;
			foreach $id_constr(@id_constr){
			    $tmpid2=substr($rd{"STRID2"},1,4);
			    if ($id_constr=~/$tmpid2/){$flag=1;last;}}}
		    if ($flag) {
			if (!defined $flag{"$tmpid"}){
			    ++$ctprotok;
			    $histocc{$tmpid}=0;	# initialise histo of Noccurrence
			    push(@idok,$tmpid);$flag{"$tmpid"}=1;}
			$tmp1=substr($_,1,66); push(@arprint,$tmp1);
			foreach$des(@des){if($des eq $des[$#des]){print $fhoutgr $rd{"$des"},"\n";}
					   else {                 print $fhoutgr $rd{"$des"},"\t";}}
			++$cthits;
			$tmp=$rd{"IDE"};
			++$histo{$tmp};
			++$histocc{$tmpid};
		    }}
	    }
	    close(FILE_INFSSP);
	    if (!defined $flag{"$tmpid"}){push(@idnot,$tmpid);}
	} else { print "$file_infssp missing\n";}
#       ------------------------------
#       print
#       ------------------------------
	if ($#arprint >1) {
	    foreach $i (@arprint) { print "$i\n"; print $fhout "$i\n"; }
	}
    }
}
print "# statistics:        sequence id $lower_seqide-$upper_seqide\n";
print "# number of proteins searched:   $ctprot\n";
print "# number of proteins with hits:  $ctprotok\n";
print "# number of hits found in total: $cthits\n";

print $fhout "# statistics:        sequence id $lower_seqide-$upper_seqide\n";
print $fhout "# number of proteins searched:   $ctprot\n";
print $fhout "# number of proteins with hits:  $ctprotok\n";
print $fhout "# number of hits found in total: $cthits\n";

close(FILE_INLIST); close($fhout); close($fhoutgr);

&open_file("$fhhist", ">$file_hist");
printf $fhhist "%4s\t%10s\n","\%ide","number of pairs";
foreach $i ($lower_seqide..$upper_seqide){
    printf $fhhist "%4d\t%10d\n","$i",$histo{$i};
}
close($fhhist);

&open_file("$fhhistocc", ">$file_histocc");
printf $fhhistocc "%4s\t%-10s\t%5s","no","id guide","N found";
if ($#id_constr>0){printf $fhhistocc "\t%7s\n","pchance";}else{printf $fhhistocc"\n";}
$ct=$ctran=$pran=0;
foreach $it (1..$#idok){
    $id1=$idok[$it];
				# print
    printf $fhhistocc "%4d\t%-10s\t%5d","$it",$id1,$histocc{$id1}; 
    if ($#id_constr>0){		# compute likelihood
	$pran=$histocc{$id1}/$#id_constr;
	printf $fhhistocc "\t%7.4f\n",$pran;}
    else{printf $fhhistocc "\n";}

    $ct+=$histocc{$id1};
    $ctran+=$pran;
}
$it=$#idok;
printf $fhhistocc "%4d\t%-10s\t%5d","$it","sum",$ct;
				# probability
if ($#id_constr>0){printf $fhhistocc "\t%7.4f\n",($ctran/$it);}else{printf $fhhist "\n";}
close($fhhistocc);

&open_file("$fhidok", ">$file_idok");
&open_file("$fhidnot", ">$file_idnot");
print "--- id's of files with hits: \n";
foreach$id(@idok){print $fhidok "$id\n";
		  print "$id, ";}print"\n";
print "--- id's of files with no hits: \n";
foreach$id(@idnot){print $fhidnot "$id\n";
		  print "$id, ";}print"\n";
close($fhidok);close($fhidnot);
exit;
