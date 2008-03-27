#!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/pub/bin/perl4 -w
##!/usr/pub/bin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
$[ =1 ;

$ARCH=$ENV{'ARCH'}; 
if (! defined $ARCH){ $ARCH=$ENV{'CPUARC'};}
if (! defined $ARCH){ $ARCH="SGI64";}

if ($#ARGV<1){print"goal:     convert hssp format to msf\n";
	      print"usage:    'script file.hssp'\n";
	      print"option:   'fileMsf=x' : name of output file (default file.msf)\n";
	      print"option:   'expand'    : deletions of HSSP will be filled (default not)\n";
	      print"option:   'ARCH=x' x=SGI64, or x=ALPHA (default $ARCH)\n";
	      print"option:   'exe=convert_seq' (default taken from /usr/pub/bin/molbio)\n";
	      exit;}

$fileMsf="unk";$Lexpand=0;
				# read command line
$file_in=  $ARGV[1];
foreach$arg(@ARGV){
    if   ($arg =~/^fileMsf=/){$arg=~s/^fileMsf=|\s//g;$fileMsf=$arg;}
    elsif($arg eq "expand")  {$Lexpand=1;}
    elsif($arg =~/ARCH=/)    {$arg=~s/^ARCH=|\s//g;$ARCH=$arg;}
    elsif($arg =~/exe.*=/)   {$arg=~s/^exe=|\s//g;$exe_convert_seq=$arg;}
}

if (! defined $exe_convert_seq){
    $exe_convert_seq=     "/home/rost/pub/phd/bin/convert_seq.$ARCH";}

$form_out= "M";
if ($fileMsf eq "unk"){
    $fileMsf=$file_in;$fileMsf=~s/^.*\///g;$fileMsf=~s/\.hssp/\.msf/;}
if ($Lexpand){
    $anExpand="Y";}else{$anExpand="N";}
$an=       "N";
$command=  "";

				# run it
eval "\$command=\"$exe_convert_seq,$file_in,$form_out,$an,$fileMsf,$anExpand,$an,\"";
&run_program("$command" ,"LOGFILE","die");
exit;

#======================================================================
sub run_program {
    local ($cmd, $log_file, $action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    if ((! defined $Lverb)||$Lverb){print "--- running command: \t $cmdtmp"; }
    if (defined $action){print"do='$action'";}print"\n" ;

    open (TMP_CMD, "|$cmdtmp") || ( do {
	if ( $log_file ) {print $log_file "Can't run command: $cmdtmp\n" ;}
	warn "Can't run command: '$cmdtmp'\n" ;
	if (defined $action){
	    exec $action ;}
    } );
    foreach $command (@out_command) {
# delete end of line, and spaces in front and at the end of the string
	$command =~ s/\n// ;
	$command =~ s/^ *//g ;
	$command =~ s/ *$//g ; 
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;
}

