#!/bin/env perl4
##!/usr/pub/bin/perl -w
##!/usr/bin/perl -w
##!/usr/pub/bin/perl -w
#----------------------------------------------------------------------
# change_all_files
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	change_all_files.pl old_regexp new_regexp search_dir
#
# task:		echange regexp in all files
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			October,        1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "change_all_files";
$script_goal      = "echange regexp in all files";
$script_input     = "old_regexp new_regexp search_dir, or: old new dir file";
$script_opt_ar[1] = "file=file_names";
$script_opt_ar[1] = "dir_path";

#require "/home/rost/perl/lib-ut.pl"; 
require "find.pl";

$PWD=$ENV{'PWD'};		# get path

#----------------------------------------
# about script
#----------------------------------------
&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
for ($it=1; $it<=$#script_opt_ar; ++$it) {
    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
} &myprt_empty; 
if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { exit; }

#----------------------------------------
# read input
#----------------------------------------
$LFILE=0;$#search_list=0;
if ($#ARGV <2) { 
    print "*** arguments old_regexp new_regexp directory (optional)\n";
    print "*** note:  'script old new *' will only list local files!\n";
    exit;}

$old_regexp = $ARGV[1];
$new_regexp = $ARGV[2];
if ( ($#ARGV>2) && (-d $ARGV[3]) ) {
    $search_dir = $ARGV[3]; $search_dir=&complete_dir($search_dir);}
else{
    $search_dir=$PWD;       $search_dir=&complete_dir($search_dir);}
    
if ( ($#ARGV>3) && ($ARGV[3] ne "*") ) {
    if ($ARGV[4]=~/file=/){
	$LFILE=1;$search_file=$ARGV[4]}
    else {
	$LFILE=1;$search_file="x_".$$.".tmp";
	if ($search_dir =~ /$PWD/){
	    $itbeg=3;}
	else {
	    $itbeg=4;}
	foreach $it ($itbeg .. $#ARGV){ 
	    $_=$ARGV[$it];
	    $_=~s/\n|\s//g; $tmp="$search_dir"."$_";
	    if (! -d $tmp){
		push(@search_list,$tmp);}}}}
#------------------------------
# defaults
#------------------------------

#------------------------------------------------------------
# search for all files with regexp
#------------------------------------------------------------
print "--- now searching for\n";
print "--- \t old_regexp= $old_regexp\n";
print "--- \t new_regexp= $new_regexp\n";
print "--- \t search_dir= $search_dir\n";
if ($LFILE){
    print "--- \t search_file=$search_file\n";}
print "--- \t other input:\n";
foreach $_(@ARGV){print "$_,";}print"\n";

$flist="".$$.".tmp";
$flist_old="".$$.".list";

if (!$LFILE) {
#    system("find $search_dir -type f -print | xargs grep $old_regexp >> $flist");
    system("find $search_dir -print >> $flist"); }
else {
    $flist=$search_file; 
    if ($#search_list>0){
	&open_file("FHLIST", ">$flist"); 
	foreach $_(@search_list){
	    if ( ($_ !~ /\.z|\.gz|\.tar/) && ($_ ne $flist) && (! -d $_) ) {
		if ($_ =~ /$search_dir/) {
		    $tmp=$_;}
		else {
		    $tmp="$search_dir"."$_";}
		print FHLIST "$tmp\n";}}
	close(FHLIST);}}

#------------------------------------------------------------
# search for all files with regexp
#------------------------------------------------------------
print "--- reading the list of files \t $flist\n";
&open_file("FHLIST", "$flist"); &open_file("FHLISTOLD", ">$flist_old");
while(<FHLIST>) {
    print "--- \t reading '$_'\n";
    $file=$_;
    $file=~s/([^:]*):.*\n/$1/;$file=~s/\n|\s//g;
    if ( ($file!~/$flist/) && ($file!~/change_all_files.pl/) &&
	 ($file!~/\.z|\.gz|\.tar/) ) {
	print "now working on:$file,\n";
	$file_old="$file" . "_xxxOLD";
	system("\\cp $file $file_old");
	print FHLISTOLD "$file_old\n";
	&open_file("FHIN","$file_old");
	&open_file("FHOUT",">$file");
	$Lfound=0;
	while(<FHIN>) {
	    $tmp=$_;
	    if ($tmp !~ $old_regexp) {
		print FHOUT $tmp; }
	    else {
		$tmp=~s/$old_regexp/$new_regexp/g;
		$Lfound=1;
		print FHOUT $tmp; } }
	close(FHIN);close(FHOUT);
	if (! $Lfound){		# move back again, if regexp not found!
	    print "-*- NO (!) changes for '$file', thus move back\n";
	    system("\\mv $file_old $file");}
    }
}
close(FHLIST);close(FHLISTOLD);
exit;
system("\\rm $flist");
exit;

print "x.x now cat\n";
system("cat x.tmp");
exit;
foreach $i (<@files>) {
    $j=$i;$j=~s/(.*):.*/$1/;
    print "$j\n";
}
#system("find . -type f -print | xargs grep 'copper1'");
exit;


$|=1;

&find('/home/rost/perl');

&wanted(); 

exit;

sub wanted {
    print "x.x:$_\n";
    exit;
    system("grep 'copper1'");
    exit;
}


#======================================================================
sub myprt_array { local($sep,@A)=@_;$[=1;local($a);
		  foreach $a(@A){print"$a$sep";}print"\n";}

#======================================================================
sub myprt_line { print "-" x 70, "\n", "--- \n"; }

#======================================================================
sub myprt_empty { print "--- \n"; }

#======================================================================
sub myprt_txt { local ($string) = @_; print "--- $string \n"; }

#==========================================================================
sub complete_dir { local($dir)=@_; $[=1 ; $dir=~s/\s|\n//g; 
		   if ( (length($dir)>1)&&($dir!~/\/$/) ) {$dir.="/";} 
		   $DIR=$dir;return $dir; }
#======================================================================
sub open_file {
    local ($file_handle, $file_name, $log_file) = @_ ;
    local ($temp_name) ;

    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
       print "*** \t INFO: file $temp_name does not exist; create it\n" ;
       open ($file_handle, ">$temp_name") || ( do {
             warn "***\t Can't create new file: $temp_name\n" ;
             if ( $log_file ) {
                print $log_file "***\t Can't create new file: $temp_name\n" ;
             }
       } );
       close ("$file_handle") ;
    }
  
    open ($file_handle, "$file_name") || ( do {
             warn "*** \t Can't open file '$file_name'\n" ;
             if ( $log_file ) {
                print $log_file "*** \t Can't create new file '$file_name'\n" ;
             }
             return(0);
       } );
}

