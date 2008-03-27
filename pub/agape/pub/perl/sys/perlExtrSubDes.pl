#!/usr/bin/perl -w
##!/bin/env perl
##!/usr/bin/perl -w
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract sbr names, descriptions, and dependencies from perl program";
$[ =1 ;

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      'dirLib',  "/home/rost/perl/lib/",
      'req',     "lib-br.pl,lib-br5.pl,lib-ut.pl",
      'req',     "all5.pl,br.pl,comp.pl,file.pl,formats.pl,hssp.pl,molbio.pl,prot.pl,scr.pl,sys.pl",
      '', "",
      'verbose', 1,
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "use: \t '$scrName '\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'        'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",          "";
    printf "     \t %-15s  %-20s %-s\n","req",      "'scr1,scr2'","perl scripts to require/scan";
    printf "     \t %-15s  %-20s %-s\n","noScreen", "no value",   "no output written to screen";
    printf "     \t %-15s  %-20s %-s\n","dep",      "no value",   "write all dependencies in header";
    printf "     \t %-15s  %-20s %-s\n","build",    "no value",   "write new library with all SBRs";
    printf "     \t %-15s  %-20s %-s\n","nolib",    "no value",   "skip standard libs (perl/lib)";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}=~/^\d+$/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
$fhoutLoc="FHOUT";
$#fileIn=$#chainIn=0;
$LnoLib=$Ldep=$Lbuild=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=       $1;}
    elsif ($arg=~/^req=(.*)$/)            { $req=           $1;}
    elsif ($arg=~/^no[t]?scr[en]+$/i)     { $par{"verbose"}=0; }
    elsif ($arg=~/^dep/)                  { $Ldep=          1; }
    elsif ($arg=~/^nolib/i)               { $LnoLib=        1; }
    elsif ($arg=~/^build/)                { $Ldep=          1;
					    $Lbuild=        1; }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}

				# skip standard libraries
$par{"req"}=""                  if ($LnoLib);

				# add to previous
if (defined $req && $req=~/lib\-(br|ut)/) {
    $par{"req"}=$req;}
elsif (defined $req) {
    $par{"req"}=$req.",".$par{"req"};}
#$par{"req"}=""; #xx
				# first input file
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\/|\.pl//g;$fileOut="Doc-".$tmp.".txt";}

				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$#titleIn=0;
foreach $fileIn (@fileIn) {
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    $title=$fileIn; $title=~s/^.*\/|\.p[lm]//g;
    push(@titleIn,$title);
				# --------------------------------------------------
				# returns GLOBAL %rd:
				#    $rd{$title,"sbr"}='s1,s2'     : list of all subs
				#    $rd{$name}=       1|0         : ok ? 
				#    $rd{$name,"dep"}='c1,c2'      : list of subs called
				#    $rd{$name,"sys"}='x1,x2'      : list of system calls
				#    $rd{$name,"des"}='line'       : one line description
				#    $rd{$name,"hdr"}='header'     : separated by '\n'
				# --------------------------------------------------
    ($Lok,$msg)=
	&processProg($fileIn,$title,0);	# <---- note Lbuild = 0, here as no build for prog
    if (! $Lok) { print 
		      "*** ERROR $scrName: after processProg ($fileIn,$title)\n",
		      $msg,"\n";
		  die; } }

				# --------------------------------------------------
				# (2) read libraries and dependent file(s)
				# --------------------------------------------------
$#titleLib=0;
@fileLib=split(/,/,$par{"req"});
foreach $fileIn (@fileLib) {
				# first try adding directory
    if (! -e $fileIn && length($par{"dirLib"})>0) {
	$fileIn=$par{"dirLib"}.$fileIn; }

    if (! -e $fileIn){print "-*- WARN $scrName: no lib fileIn=$fileIn\n";
		      die;}
    print "--- $scrName: working on '$fileIn'\n";
    $title=$fileIn; $title=~s/^.*\/|\.p[lm]//g;
    push(@titleLib,$title);

    ($Lok,$msg)=
	&processProg($fileIn,$title,$Lbuild);
    if (! $Lok) { print 
		      "*** ERROR $scrName: after processProg (lib=$fileIn,$title)\n",
		      $msg,"\n";
		  die; } 
}

				# --------------------------------------------------
				# (3) write output
				# --------------------------------------------------
$#libNew=0;

&open_file("$fhoutLoc", ">$fileOut");

foreach $title (@titleIn) {	# loop over all programs

				# ------------------------------
				# write one line descriptions
    ($Lok,$msg,$tmpWrt)=
	&wrtDes($title);        if (! $Lok) { print "*** ERROR $scrName: after wrtDes ($title)\n",$msg,"\n";
					      die; } 
    print $fhoutLoc $tmpWrt;
    print $tmpWrt		if ($par{"verbose"});

				# --------------------------------------------------
				# list all subroutines called
				# 
				# returns GLOBAL %rd:
				#    $rd{$title,"lib"}='lib1,lib2' : all libs used by prog
				#    $rd{$title,$lib}= 's1,s2'     : all sbrs used in lib $lib
				# --------------------------------------------------
    ($Lok,$msg)=
	&wrtCall($title);       if (! $Lok) { print "*** ERROR $scrName: after wrtCall ($title)\n",$msg,"\n";
					      die; } 
    print $fhoutLoc $tmpWrt;
    print $tmpWrt		if ($par{"verbose"});

				# ------------------------------
				# write full descriptions
    ($Lok,$msg,$tmpWrt)=
	&wrtHdr($title,$Ldep);  if (! $Lok) { print "*** ERROR $scrName: after wrtHdr ($title)\n",$msg,"\n";
					      die; } 
    print $fhoutLoc $tmpWrt;
#    print $tmpWrt		if ($par{"verbose"});

    next if (! $Lbuild);
				# ------------------------------
				# generate new library with all!
    $fileLibBuild="NEW"."lib-".$title.".pl";

    ($Lok,$msg)=
	&newLib($title,$fileLibBuild); 
	                        if (! $Lok) { print "*** ERROR $scrName: after newLib ($title)\n",$msg,"\n";
					      die; } 
    push(@libNew,$fileLibBuild) if (-e $fileLibBuild);
}

close($fhoutLoc)                if ($fhoutLoc ne "STDOUT");

				# ------------------------------
$#tmp=0;			# potential errors
foreach $name (@name){
    push(@tmp,$name)            if (! defined $Lok{$name});}
if ($#tmp > 0){
    print "*** internal ? :";
    foreach $it (1..$#tmp) {
	print "\n","*** internal ? :" if (int($it/5) == ($it/5) );
	print $tmp[$it],","; }
    print "\n";
}

print "--- output in file=$fileOut\n" if (-e $fileOut);

if ($#libNew > 0){
    print "--- new libs=",join(',',@libNew),"\n";}

exit;

#===============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#===============================================================================
sub processProg {
    local($fileInLoc,$titleInLoc,$LbuildLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processProg                 reads the main programs
#       out GLOBAL:             $rd{} with
#                               $rd{$title,"sbr"}='s1,s2'  : list of all subs
#                               $rd{$name}=     1|0        : ok ? 
#                               $rd{$name,"dep"}='c1,c2'   : list of subs called
#                               $rd{$name,"sys"}='x1,x2'   : list of system calls
#                               $rd{$name,"des"}='line'    : one line description
#                               $rd{$name,"hdr"}='header'  : separated by '\n'
#
#                               $code{$name"}=               entire code for sbr name
# 
#       in:                     $fileInLoc  : program (e.g.: /home/rost/pub/phd.pl )
#       in:                     $title      : title   (e.g.: phd                   )
#       in:                     $Lbuild=1|0 : if = 1, store entire code as:
#                               $code{"name"} where name= subroutine name
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."processProg";$fhinLoc="FHIN_"."processProg";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def titleInLoc!"))         if (! defined $titleInLoc);
    return(&errSbr("not def LbuildLoc!"))          if (! defined $LbuildLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    
    $name=$des=$hdr=0;
    undef %Lok; $#sys=$#name=0; undef %tmp;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	$line=$_;
	$_=~s/\n//g;$rd=$_;
	next if ($rd=~/^\#\s*$/);                  # skip empty
	if ($rd=~/^\#===/){	                   # END of MAIN/previous sbr
	    next if (! $name);
	    $name=$des=$hdr=0;
	    next; }

	if (! $name &&		                   # is MAIN
	    ($rd=~/^\$\[\\s*=\s*1\s*\;/ || $rd=~/^\#\!\//)){
	    $name="MAIN"; 
	    $des=1; push(@name,$name);}            #    name of MAIN
	    
	if ($rd=~/^\s*sub\s+/){	                   # is subroutine
	    $rd=~s/\n//g; $rd=~s/\{.*$//g; $rd=~s/^\s*sub\s+(\S+)\s+.*$/$1/g;
	    $name=$rd; $des=1; push(@name,$name);  #    name of SBR

	    # ***********************
	    if ($LbuildLoc){                       #    ENTIRE CODE
		$code{$name}=$line; }
	    # ***********************

	    next; }

	# ***********************
	if (defined $name && $name && $LbuildLoc){ #    ENTIRE CODE
	    $code{$name}=""     if (! defined $code{$name}); 
	    $code{$name}.=$line; }
	# ***********************

	if ($name && $rd=~/^\#\s*$name/) {         # is description of subroutine
	    $rd=~s/\n//g;$rd=~s/^.*$name\s+//g;  $des=$rd;
	    $rd{"$name"}=      1; 
	    $rd{"$name","des"}=$des;
	    $des=0;
	    next; }
	$tmp= $rd; $tmp=~s/[\#\s]//g; $tmp2=length($tmp); $tmp=~s/\-//g;
	if ($name && ! $hdr && $rd=~/^\#\-/ &&     # start of header section
	    ($tmp2 > 20)){
	    $hdr=1;
	    next; }
	if ($name && $hdr && $rd=~/^\#\-/ &&       # end of header section
	    ($tmp2 > 20)){
	    $hdr=0;
	    next; }
	if ($name && $hdr &&$rd=~/^\#/) {          # is comment
	    $rd{"$name","hdr"}="" if (! defined $rd{"$name","hdr"});
	    $rd{"$name","hdr"}.="$rd"."\n";
	    next; }
				                   # is end of SBR (come here only if no description!)
	if (($name && $name ne "MAIN" && $rd=~/^\}/) ||
	    ($name && $name eq "MAIN" && $rd=~/^\#====/)) {
	    $rd=~s/\n//g;$rd=~s/^.*$name\s+//g;
	    if (! defined $rd{"$name"}) {          #    only if not in previous
		$rd{"$name"}=      1;
		$rd{"$name","des"}=$des; }
	    $name=0; $des=1; $hdr=0;
	    next; }
	if ($rd=~/system\(.+\)/){                  # grep system calls
	    $rd=~s/\n//g;$rd=~s/^.*system//g;$rd=~s/[\(\)\"\}\;]//g;
	    $rd{"$name","sys"}="" if (! defined $rd{"$name","sys"});
	    $rd{"$name","sys"}.="$rd".",";
	    next; }
	if ($rd=~/\&\w+/){	                   # store SBR calls
	    $rd=~s/^[\s\t]*//g;	# leading blanks
	    $rd=~s/\#.*$//g;	# comments
	    $rd=~s/\&\&/  /g;	# purge '&&'
	    $rd=~s/^[^\&]*//g;	# before
	    $rd=~s/\&([A-Z0-9a-z\-\_]+)[^\&]+/,$1/g; # delete (..)
	    $rd{"$name","dep"}="" if (! defined $rd{"$name","dep"});
				# avoid repeating it
	    if (! defined $tmp{"$name"."_"."$rd"}) {
		$tmp{"$name"."_"."$rd"}=1; 
		$rd{"$name","dep"}.="$rd".","; }
	    next; }
    } close($fhinLoc);
    undef %tmp;			# slim-is-in !
				# all subroutines in current file
    $rd{"$titleInLoc","sbr"}=join(',',@name); $rd{"$titleInLoc","sbr"}=~s/,*$//g;
    foreach $name (@name){
	if (defined $rd{"$name","sys"}){$rd{"$name","sys"}=~s/,,+/,/g;
					$rd{"$name","sys"}=~s/^,*|,*$//g; }
	if (defined $rd{"$name","dep"}){$rd{"$name","dep"}=~s/,,+/,/g;
					$rd{"$name","dep"}=~s/^,*|,*$//g; }
    }
    foreach $name (@name){
	$ptrName2prog{"$name"}=$titleInLoc; }

    return(1,"ok $sbrName");
}				# end of processProg

#===============================================================================
sub wrtDes {
    local($titleInLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDes                      writes one line description of all subroutines
#       in:                     $title (i.e. file)
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtDes";$fhinLoc="FHIN_"."wrtDes";
				# ------------------------------
				# prepare writing 
    $txt="internal subroutines:";
    $tmpWrt=         sprintf("\# \n\# %-77s\# \n","-" x 77);
    $tmpWrt.=        sprintf("\#   %-27s %-s\n"," ","-" x length($txt));
    $tmpWrt.=        sprintf("\#   %-27s %-s\n",$titleInLoc,$txt);
    $tmpWrt.=        sprintf("\#   %-27s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                "\# \n";

				# ------------------------------
				# current names
    @name=split(/,/,$rd{"$title","sbr"});

				# ------------------------------
				# loop over all subroutines
    foreach $name (@name) {
	$des="";
	$des=$rd{"$name","des"} if (defined $rd{"$name","des"});
	$tmpWrt.=    sprintf("\#   %-27s %-s\n",$name,$des);
    }
    return(1,"ok $sbrName",$tmpWrt);
}				# end of wrtDes

#===============================================================================
sub wrtCall {
    local($titleInLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtCall                     lists all external subroutines called by prog
#       in GLOBAL:              $rd{}, @titleLib
#       out GLOBAL:             $rd{} with
#                               $rd{$title,"lib"}='lib1,lib2' : all libs used by prog
#                               $rd{$title,$lib}= 's1,s2'     : all sbrs used in lib $lib
#       in:                     $title (i.e. file)
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtCall";$fhinLoc="FHIN_"."wrtCall";
				# ------------------------------
				# prepare writing 
    $txt=                       "external subroutines:";
    $tmpWrt=                    sprintf("\# \n\# %-77s\# \n","-" x 77);
    $tmpWrt.=                   sprintf("\#   %-27s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                   sprintf("\#   %-27s %-s\n",$titleInLoc,$txt);
    $tmpWrt.=                   sprintf("\#   %-27s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                   "\# \n";

				# ------------------------------
				# current names
    @name=split(/,/,$rd{"$titleInLoc","sbr"});
    undef %lib;			# $lib{lib-br}='x1,x2' lists all calls to lib-br
    undef %ok;			# $ok{sbr}=1           if SBR already somewhere
    $#libSbr=0;			# array with all sbrs called (also from lib 2 lib)
    $sys="";
    $#missing=0;		# subroutines that could not be related to any
				# library
    $#libLoc=0;			# libraries refered to
    undef %tmp;
				# ------------------------------
				# loop over all subroutines
    foreach $name (@name) {
				# no call ?
	next if (! defined $rd{"$name","dep"});
				# subroutines called
	@dep=split(/,/,$rd{"$name","dep"});
	foreach $dep (@dep) {
				# avoid duplication
	    next if (defined $ok{$dep});

				# all subroutines in libs
	    push(@libSbr,$dep);
	    $ok{$dep}=1;
				# unresolved !!
	    if (! defined $ptrName2prog{"$dep"}) {
		print "*** $sbrName missing pointer for dep=$dep,\n";
		push(@missing,$dep);
		next ; }

	    $lib=$ptrName2prog{"$dep"};
				# skip if calling itself, here
#	    next if ($lib eq $titleInLoc);
				# which libs are called?
	    $lib{$lib}=""       if (! defined $lib{$lib});
	    if (! defined $tmp{"$lib"."_"."$dep"}){
		$lib{$lib}.=$dep.","; } }
				# system calls
	$sys.=$rd{"$name","sys"}."," 
	    if (defined $rd{"$name","sys"});
    }
				# ------------------------------
				# calls from lib 2 lib
				# ------------------------------
    $Lok=0;
    while (! $Lok){
	$#tmp=0; $Lok=1;
	foreach $sbr (@libSbr) {
				# no call from there
	    next if (! defined $rd{"$sbr","dep"});
				# call from lib 2 lib
	    @sbrFromLib=split(/,/,$rd{"$sbr","dep"});
	    foreach $sbrFromLib (@sbrFromLib) {
		next if (defined $ok{$sbrFromLib});
				# new -> go back into loop!!!
		$ok{$sbrFromLib}=1;
		push(@tmp,$sbrFromLib);
				# from which lib ?
				# unresolved !!
		if (! defined $ptrName2prog{"$sbrFromLib"}) {
		    print "*** $sbrName missing pointer for lib:$sbr:$sbrFromLib\n";
		    push(@missing,$sbrFromLib);
		    next ; }
		$lib=$ptrName2prog{"$sbrFromLib"};
		$lib{$lib}=""   if (! defined $lib{$lib});
		$lib{$lib}.=$sbrFromLib.",";  }
	}
	$Lok=1                  if ($#tmp==0);
	push(@libSbr,@tmp); 
    }				# end of while

				# ------------------------------
				# write all
				# ------------------------------
    foreach $lib (@titleLib) {
	next if (! defined $lib{$lib});
	@sbr=split(/,/,$lib{$lib});
	@sbr=sort (@sbr);
	($Lok,$msg,$tmp)=
	    &array2wrt($lib,@sbr);
	return(&errSbrMsg("failed on array2wrt for lib=$lib",$msg)) if (! $Lok);
	next if (length($tmp)<2);
	push(@libLoc,$lib);
	$tmpWrt.=               $tmp; 
	$tmpWrt.=               "\# \n"; }
    if ($#libLoc > 0){
	$rd{"$titleInLoc","lib"}=join(',',@libLoc);
	foreach $lib (@libLoc){
	    $rd{"$titleInLoc","$lib"}=$lib{$lib}; }}

				# ------------------------------
				# system calls
				# ------------------------------
    @sys=split(/,/,$sys);
    @sys=sort (@sys);
    ($Lok,$msg,$tmp)=
	&array2wrtErr("system",@sys);
    return(&errSbrMsg("failed on array2wrt for system calls",$msg)) if (! $Lok);
    if (length($tmp) > 2) {
	$tmpWrt.=               $tmp; 
	$tmpWrt.=               "\# \n"; }
				# ------------------------------
				# unresolved ??
				# ------------------------------
    @missing=sort (@missing);
    ($Lok,$msg,$tmp)=
	&array2wrtErr("missing",@missing);
    return(&errSbrMsg("failed on array2wrt for missing calls",$msg)) if (! $Lok);
    if (length($tmp) > 2) {
	$tmpWrt.=               $tmp; 
	$tmpWrt.=               "\# \n"; }

    return(1,"ok $sbrName",$tmpWrt);
}				# end of wrtCall

#===============================================================================
sub array2wrt {
    local($titleInLoc2,@tmpIn) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   array2wrt                   writes list of sbrs
#       in:                     $title,@tmp=list
#       out:                    1|0,msg,$tmpWrt2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2="$tmp"."array2wrt";$fhinLoc="FHIN_"."array2wrt";

    $tmpWrt2="";

    $tmp=""; $#tmpLoc=0; 
    undef %tmpLoc;
    foreach $sbrLoc (@tmpIn) {
	next if (defined $tmpLoc{$sbrLoc});
	$tmpLoc{$sbrLoc}=1;
	if (length($tmp) > 50) { push(@tmpLoc,$tmp);
				 $tmp="";}
	$tmp.="$sbrLoc".","; }
    push(@tmpLoc,$tmp)          if (length($tmp)>5);

    if ($#tmpLoc > 0){		# skip as none found in this lib
	foreach $tmp(@tmpLoc){
	    $tmp=~s/^,*|,*$//g; }
				# write
	$tmpWrt2.=    sprintf("\#   %-27s %-s\n","call from ".$titleInLoc2.":",$tmpLoc[1]);
	foreach $it (2..$#tmpLoc) {
	    $tmpWrt2.=sprintf("\#   %-27s %-s\n"," ",$tmpLoc[$it]); 
	}
    }
    
    return(1,"ok $sbrName2",$tmpWrt2);
}				# end of array2wrt

#===============================================================================
sub array2wrtErr {
    local($titleInLoc2,@tmpIn) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   array2wrtErr                writes list of sbrs for errors
#       in:                     $title,@tmp=list
#       out:                    1|0,msg,$tmpWrt2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2="$tmp"."array2wrtErr";$fhinLoc="FHIN_"."array2wrtErr";

    $tmpWrt2=""; undef %tmp;

    $tmpWrt2.=    sprintf("\#   %-27s %-s\n","call from ".$titleInLoc2.":"," ");
    foreach $sbrLoc (@tmpIn) {	# write
	next if (defined $tmp{$sbrLoc});
	$tmp{$sbrLoc}=1;
	$tmpWrt2.=sprintf("\#   %-27s %-s\n"," ",$sbrLoc);
    }
    
    return(1,"ok $sbrName2",$tmpWrt2);
}				# end of array2wrtErr

#===============================================================================
sub wrtHdr {
    local($titleInLoc,$LdepLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHdr                      write full description section of SBRs + dependencies
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtHdr";$fhinLoc="FHIN_"."wrtHdr";

				# ------------------------------
				# prepare writing 
    $txt=                       "description of subroutines:";
    $tmpWrt=                    sprintf("\# \n\# %-77s\# \n","-" x 77);
    $tmpWrt.=                   sprintf("\#   %-27s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                   sprintf("\#   %-27s %-s\n",$titleInLoc,$txt);
    $tmpWrt.=                   sprintf("\#   %-27s %-s\n"," ","-" x length($txt));

				# ------------------------------
				# current names
    @name=split(/,/,$rd{"$titleInLoc","sbr"});

				# ------------------------------
				# loop over all subroutines
    foreach $name (@name) {
	$hdr="";
	$hdr=$rd{"$name","hdr"} if (defined $rd{"$name","hdr"});

	$des="";
	$des=$rd{"$name","des"} if (defined $rd{"$name","des"});

	$tmpWrt.=               sprintf("\#   %-27s %-s\n","-" x 26," ");
	$tmpWrt.=               sprintf("\#   %-27s %-s\n",$name,$des);
	$tmpWrt.=               $hdr; 

				# dependencies
	next if (! $LdepLoc);
	next if (! defined $rd{"$titleInLoc","lib"});
	@lib=split(/,/,$rd{"$titleInLoc","lib"});
	foreach $lib (@lib) {
	    next if (! defined $rd{"$titleInLoc","$lib"});
	    @sbr=split(/,/,$rd{"$titleInLoc","$lib"});
	    @sbr=sort (@sbr);
	    ($Lok,$msg,$tmp)=
		&array2wrtHdr($lib,@sbr);
	    return(&errSbrMsg("failed on array2wrtHdr for lib $lib, name=$name",$msg)) if (! $Lok);
	    if (length($tmp) > 2) {
		$tmpWrt.=       $tmp; } }}
	    
    return(1,"ok $sbrName",$tmpWrt);
}				# end of wrtHdr

#===============================================================================
sub array2wrtHdr {
    local($titleInLoc2,@tmpIn) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   array2wrtHdr                   writes list of sbrs
#       in:                     $title,@tmp=list
#       out:                    1|0,msg,$tmpWrt2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2="$tmp"."array2wrtHdr";$fhinLoc="FHIN_"."array2wrtHdr";

    $tmpWrt2="";

    $tmp=""; $#tmpLoc=0; 
    undef %tmpLoc;
    foreach $sbrLoc (@tmpIn) {
	next if (defined $tmpLoc{$sbrLoc});
	$tmpLoc{$sbrLoc}=1;
	if (length($tmp) > 50) { push(@tmpLoc,$tmp);
				 $tmp="";}
	$tmp.="$sbrLoc".","; }
    push(@tmpLoc,$tmp)          if (length($tmp)>5);

    if ($#tmpLoc > 0){		# skip as none found in this lib
	foreach $tmp(@tmpLoc){
	    $tmp=~s/^,*|,*$//g; }
				# write
	$tmpWrt2.=    sprintf("\#   %-27s %-s\n","    "."call ".$titleInLoc2.":",$tmpLoc[1]);
	foreach $it (2..$#tmpLoc) {
	    $tmpWrt2.=sprintf("\#   %-27s %-s\n"," ",$tmpLoc[$it]); 
	}
    }
    
    return(1,"ok $sbrName2",$tmpWrt2);
}				# end of array2wrtHdr

#===============================================================================
sub newLib {
    local($titleInLoc,$fileOutLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   newLib                      builds up the new lib
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."newLib";$fhoutLoc2="FHOUT_"."newLib";

				# ------------------------------
				# current names
    @name=split(/,/,$rd{"$titleInLoc","sbr"});

    $#all=0;
    undef %tmp;
				# ------------------------------
				# loop over all subroutines
    foreach $name (@name) {
	next if (! defined $rd{"$titleInLoc","lib"});
	@lib=split(/,/,$rd{"$titleInLoc","lib"});
	foreach $lib (@lib) {
	    next if (! defined $rd{"$titleInLoc","$lib"});
	    @sbr=split(/,/,$rd{"$titleInLoc","$lib"});
	    @sbr=sort (@sbr);
	    foreach $sbr (@sbr) {
		next if (defined $tmp{$sbr}); # avoid duplication
		push(@all,$sbr);
		$tmp{$sbr}=1; }}}

				# ------------------------------
				# open file
    &open_file("$fhoutLoc2", ">$fileOutLoc");
				# 
    print $fhoutLoc2
	"\n","\n",
	"#==============================================================================\n",
	"# library collected (begin) lll\n",
	"#==============================================================================\n",
	"\n","\n";
				# ------------------------------
				# sort alphabetically
    @allSorted=sort @all;
				# ------------------------------
				# all subroutines
    foreach $sbr (@allSorted) {
	print $fhoutLoc2 "\#","=" x 78,"\n";
	print $fhoutLoc2 $code{$sbr}; 
	print $fhoutLoc2 "\n";
    }
    print  $fhoutLoc2
	"\n","\n",
	"#==============================================================================\n",
	"# library collected (end)   lll\n",
	"#==============================================================================\n",
	"\n","\n";

    print $fhoutLoc2 "1\;\n";	# final ...
    close($fhoutLoc2);

    return(1,"ok $sbrName");
}				# end of newLib

