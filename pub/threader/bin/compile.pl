#!/bin/env perl
##!/usr/local/bin/perl -w
#
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compile PHD FORTRAN tools programs (convert_seq, filter_hssp)";
#$scrGoal="compile PHD FORTRAN tools programs (convert_seq, filter_hssp, maxhom ?)";
#  
#

$[ =1 ;
$dirMake=        "mat/";
				# for PHD 
$fileMake{"convert"}="make_convert_seq.ARCH";
$fileMake{"filter"}= "make_filter_hssp.ARCH";
				# for TOPITS
$fileMake{"metr2st"}="make_metr2st_make.ARCH";
				# for MaxHom
$fileMake{"maxhom"}= "make_maxhom.ARCH";
$fileMake{"profile"}="make_profile_make.ARCH";

$exe{"convert"}=     "convert_seq.".  "ARCH";
$exe{"filter"}=      "filter_hssp.".  "ARCH";

$exe{"metr2st"}=     "metr2st_make.". "ARCH";

$exe{"maxhom"}=      "maxhom.".       "ARCH";
$exe{"profile"}=     "profile_make.". "ARCH";

$LnotMaxhome=        1;
#$LnotMaxhome=        0;

@all=("convert","filter","metr2st","maxhom","profile");

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName <auto|filter|convert|metr2st|maxhom|profile>'\n";
    print  "opt:                (pass the following arguments like '$scrName arg=val')\n";
				#      'keyword'   'value'    'description'
    printf "    %-12s=%-10s %-22s %-s\n","." x 10,  "." x 10, "." x 15,   "." x 20;
    printf "    %-12s=%-10s %-22s %-s\n","keyword",  "value", "default",  "explanation";
    printf "    %-12s=%-10s %-22s %-s\n","." x 10,  "." x 10, "." x 15,   "." x 20;
    printf "    %-12s=%-10s %-22s %-s\n","ARCH",     "ALPHA",    "",        
                                                          "system arch: SGI64|SGI32|SGI5|ALPHA|SUNMP";
    printf "    %-12s=%-10s %-22s %-s\n","dir",      "mat",$dirMake,        "directory with make file";

    foreach $kwd (@all){
        next if ($LnotMaxhom && $kwd eq "maxhom");
	printf "    %-12s=%-10s %-22s %-s\n","exe_".$kwd,"x",  $exe{$kwd},     "name of executable"; }
    foreach $kwd (@all){
        next if ($LnotMaxhom && $kwd eq "maxhom");
	printf "    %-12s=%-10s %-22s %-s\n","make_".$kwd,"x", $fileMake{$kwd},"make file";}
    foreach $kwd (@all){
        next if ($LnotMaxhom && $kwd eq "maxhom");
	printf "    %-12s %-10s %-22s %-s\n",$kwd,       "no value",  "1","compiles $kwd";}
    exit;
}

foreach $kwd (@all) {
    $do{$kwd}=0;}
$Lopted=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1] && $arg =~ /^(auto|do)$/);
    if    ($arg=~/^ARCH=(.*)$/i)          { $ARCH=$1;}
    elsif ($arg=~/^make_(.*)=(.*)$/)      { $fileMake{$1}=$2;}
    elsif ($arg=~/^exe_(.*)=(.*)$/)       { $exe{$1}=$2;}
    elsif ($arg=~/^conv(ert)?$/)          { $do{"convert"}=1; $Lopted=1;}
    elsif ($arg=~/^fil(ter)?$/)           { $do{"filter"}= 1; $Lopted=1;}
    elsif ($arg=~/^metr(2st)?$/)          { $do{"metr2st"}=1; $Lopted=1;}

    elsif ($arg=~/^max(hom)?$/)           { $do{"maxhom"}= 1; $Lopted=1;}
    elsif ($arg=~/^prof(ile)?$/)          { $do{"profile"}=1; $Lopted=1;}
    
    elsif ($arg=~/^dir=(.*)$/)            { $dirMake=$1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}

    else { print "*** ERROR $scrName: wrong command line arg '$arg'\n"; 
	   die;}}

$ARCH= $ARCH || $ENV{'ARCH'};

$dirMake.="/"                   if ($dirMake !~/\// && length($dirMake)>=1);

if (! defined $ARCH) {
    $ansr=
	&get_in_keyboardLoc("ARCH","",$scrName);
    $ARCH=$ansr; }

if ($ARCH !~ /ALPHA|SGI(64|32|5)|SUNMP|SUN4SOL/){
    print "--- $scrName: ARCH must be either of the following :\n";
    print "--- "." " x length($scrName)." ALPHA|SGI64|SGI32|SGI5|SUNMP|SUN4SOL\n";
    $ansr=
	&get_in_keyboardLoc("ARCH","",$scrName);
    $ARCH=$ansr; }

if ($ARCH !~ /ALPHA|SGI(64|32|5)|SUNMP|SUN4SOL/){
    print "*** ERROR $scrName: ARCH really must be either of the following :\n";
    print "***       "." " x length($scrName)." ALPHA|SGI64|SGI32|SGI5|SUNMP|SUN4SOL\n";
    die; }

				# default: do all 3 compilations
if (! $Lopted){
    foreach $kwd (@all){
        next if ($LnotMaxhom && $kwd eq "maxhom");
	$do{$kwd}=1;}}

foreach $kwd (@all) {
    next if (! $do{$kwd});

    $fileMake{$kwd}=~s/ARCH/$ARCH/           if ($fileMake{$kwd} =~ /ARCH/);
    $fileMake{$kwd}=$dirMake.$fileMake{$kwd} if ($fileMake{$kwd} !~ /$dirMake/);
    
    $fileMake=$fileMake{$kwd};

    undef $exeOut;
    if (defined $exe{$kwd}) {
	$exeOut= $exe{$kwd};
	$exeOut=~s/ARCH/$ARCH/               if ($exeOut=~/ARCH/);}

    $exeDef= "convert_seq.". $ARCH           if ($kwd eq "convert");
    $exeDef= "filter_hssp.". $ARCH           if ($kwd eq "filter");
    $exeDef= "maxhom."     . $ARCH           if ($kwd eq "maxhom"); 
    $exeDef= "metr2st_make.".$ARCH           if ($kwd eq "metr2st"); 
    $exeDef= "profile_make.".$ARCH           if ($kwd eq "profile"); 

				# local copy of make file
    $fileMakeTmp="make_".$kwd."_tmp_".$$.".".$ARCH;

    print "--- $scrName: system '\\cp $fileMake $fileMakeTmp '\n";
    system("\\cp $fileMake $fileMakeTmp");

				# compile
    print "--- $scrName: system 'make -f $fileMakeTmp'\n";
    system("make -f $fileMakeTmp");

    if (-e $exeDef && defined $exeOut && ($exeDef ne $exeOut)) {
	print "--- $scrName: system '\\mv $exeDef $exeOut'\n";
	system("\\mv $exeDef $exeOut"); 
	$exeDef=$exeOut; }

    print "--- $scrName: expected executable: $exeDef\n" if (-e $exeDef);
    if (! -e $exeDef) {
	print "*** ERROR $scrName: never made '$exeDef'\n";
	print "***       keyword assigned to executable?? check code!\n";}

    unlink($fileMakeTmp);

}


exit;


#===============================================================================
sub get_in_keyboardLoc {
    local($des,$def,$pre,$Lmirror)=@_;local($txt);
#--------------------------------------------------------------------------------
#   get_in_keyboardLoc             gets info from keyboard
#       in:                     $des :    keyword to get
#       in:                     $def :    default settings
#       in:                     $pre :    text string beginning screen output
#                                         default '--- '
#       in:                     $Lmirror: if true, the default is mirrored
#       out:                    $val : value obtained
#--------------------------------------------------------------------------------
    $pre= "---"                 if (! defined $pre);
    $Lmirror=0                  if (! defined $Lmirror || ! $Lmirror);
    $txt="";			# ini
    printf "%-s %-s\n",          $pre,"-" x (79 - length($pre));
    printf "%-s %-15s:%-s\n",    $pre,"type value for",$des; 
    if (defined $def){
	printf "%-s %-15s:%-s\n",$pre,"type RETURN to enter value, or to keep default";
	printf "%-s %-15s>%-s\n",$pre,"default value",$def;}
    else {
	printf "%-s %-15s>%-s\n",$pre,"type RETURN to enter value"; }

    $txt=$def                    if ($Lmirror);	# mirror it
    printf "%-s %-15s>%-s",      $pre,"type",$txt; 

    while(<STDIN>){
	$txt.=$_;
	last if ($_=~/\n/);}     $txt=~s/^\s+|\s+$//g;
    $txt=$def                   if (length($txt) < 1);
    printf "%-s %-15s>%-s\n",    $pre,"--> you chose",$txt;
    return ($txt);
}				# end of get_in_keyboardLoc

