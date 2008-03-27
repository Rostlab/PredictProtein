#!/usr/bin/perl -w
##!/bin/env perl
##!/usr/bin/perl -w
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract sbr names, descriptions, and dependencies from FORTRAN program";
$[ =1 ;

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      'req',     "/home/rost/for/lib-comp.f,/home/rost/for/lib-prot.f,/home/rost/for/lib-unix.f",
#      'req',     "",
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
    printf "     \t %-15s  %-20s %-s\n","req",      "'scr1,scr2'","FORTRAN lib to require/scan";
    printf "     \t %-15s  %-20s %-s\n","req",      "0",          "-> NO require";
    printf "     \t %-15s  %-20s %-s\n","noScreen", "no value",   "no output written to screen";
    printf "     \t %-15s  %-20s %-s\n","dep",      "no value",   "write all dependencies in header";
    printf "     \t %-15s  %-20s %-s\n","build",    "no value",   "write new library with all SBRs";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    next if ($kwd=~/^\s*$/);
	    if    ($par{"$kwd"}=~/^\d+$/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
$fhoutLoc="FHOUT";
$#fileIn=0;
$Ldep=$Lbuild=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^req=(.*)$/)            { $req=$1;}
    elsif ($arg=~/^no[t]?scr[en]+$/i)     { $par{"verbose"}=0;}
    elsif ($arg=~/^dep/)                  { $Ldep=1;}
    elsif ($arg=~/^build/)                { $Ldep=1;
					    $Lbuild=1; }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

				# add to previous
if (defined $req && $req){
    $par{"req"}=$req;}
				# first input file
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\/|\.f//g;$fileOut="Doc-".$tmp;}

				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$#titleIn=0;
foreach $fileIn (@fileIn) {
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $title=$fileIn; $title=~s/^.*\/|\.f//g;
    print "--- $scrName: working on $title ($fileIn)\n";
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
	&processProgFor($fileIn,$title,0); # <---- note Lbuild = 0, here as no build for prog
    if (! $Lok) { print 
		      "*** ERROR $scrName: after processProg ($fileIn,$title)\n",
		      $msg,"\n";
		  die; } }

				# --------------------------------------------------
				# (2) read libraries and dependent file(s)
				# --------------------------------------------------
$#titleLib=0;
if (defined $req && $req){
    @fileLib=split(/,/,$par{"req"});
    foreach $fileIn (@fileLib) {
        if (! -e $fileIn){print "-*- WARN $scrName: no lib fileIn=$fileIn\n";
                          next;}
        $title=$fileIn; $title=~s/^.*\/|\.f//g;
        print "--- $scrName: working on $title ($fileIn)\n";
        push(@titleLib,$title);
        
	($Lok,$msg)=
	    &processProgFor($fileIn,$title,$Lbuild);
	if (! $Lok) { print 
			  "*** ERROR $scrName: after processProg (lib=$fileIn,$title)\n",
			  $msg,"\n";
		      die; } 
    }}

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
				# returns GLOBAL %rd:
				#    $rd{$title,"lib"}='lib1,lib2' : all libs used by prog
				#    $rd{$title,$lib}= 's1,s2'     : all sbrs used in lib $lib
				# --------------------------------------------------
    ($Lok,$msg)=
	&wrtCall($title);       if (! $Lok) { print "*** ERROR $scrName: after wrtCall ($title)\n",$msg,"\n";
					      die; } 
    print $fhoutLoc $tmpWrt;
    print $tmpWrt		if ($par{"verbose"});

    next if (! $Lbuild);
				# ------------------------------
				# generate new library with all!
    $fileLibBuild="NEW"."lib-".$title.".f";
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
sub processProgFor {
    local($fileInLoc,$titleInLoc,$LbuildLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processProgFor              reads the main programs
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
    $sbrName="$tmp"."processProgFor";$fhinLoc="FHIN_"."processProgFor";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    
    $name=$des=$hdr=0;
    undef %Lok; $#name=$#type=0; undef %tmp;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	$line=$_;
	$_=~s/\n//g;$rd=$_;
	next if ($rd=~/^\*\*\*\*\* end of /); # will be added explicitly
                                # skip empty comments...
        if ($rd=~/^[C\*]/) {
            next if ($rd=~/^[\*C]\s*$/         ||
                     $rd=~/^[C\*]\s+\**\s*\*$/ ||
                     $rd=~/^[C\*]\s+\-*\s*\*$/ ||
                     $rd=~/^[C\*]\s+\-*\s*\*$/ ||
                     $rd=~/^[C\*]\s+execution of subr/ 
                     ); }

                                # END of MAIN/previous sbr
	if ($rd=~/^[\s\t]+END[\s\t]*$/){
	    next if (! $name);
	    if ($LbuildLoc){                  #    ENTIRE CODE
		$code{$name}.=$line; }
	    $name=$des=$hdr=0;
            $#hdr=0;
	    next; }
                                # is MAIN
	if (! $name && $rd=~/^[\s\t]+PROGRAM ([^\(]*)/i){
	    $name="MAIN"; 
	    $des=1; push(@name,$name);}            #    name of MAIN
                                # is SUBROUTINE | FUNCTION
        $tmp=$rd;
        $tmp=~s/^([\s\t]+)(INTEGER|REAL|LOGICAL|CHARACTER\*\d*)\s*/$1/;
	if ($tmp=~/^[\s\t]+?(SUBROUTINE|FUNCTION)\s+([^\(]+)/i){
            $type=$1; $name=$2; $des=1; 
            $name=~tr/[a-z]/[A-Z]/; # all capitals
            $comments=""; $comments.=join("\n",@hdr)."\n" if ($#hdr>0);
            push(@name,$name); push(@type,$type); push(@hdr,$comments);

	    # ***********************
	    if ($LbuildLoc){                       #    ENTIRE CODE
		$code{$name}="";
		$code{$name}.=$comments if (defined $comments);
		$code{$name}.=$line; 
            }
	    # ***********************

	    next; }
                                # is description of subroutine
        if (! $name && $rd=~/^[\*C]/){
            push(@hdr,$rd);
            next;}

	# ***********************
	if ($name && $LbuildLoc){                  #    ENTIRE CODE
	    $code{$name}.=$line; }
	# ***********************

        next if ($rd=~/^[C\*]/); # skip comments

                                # store SBR calls
	if ($rd=~/CALL ([^\(]*)/){ # 
            $call=$1;
            $call=~tr/[a-z]/[A-Z]/; # all capitals
	    $rd{"$name","dep"}="" if (! defined $rd{"$name","dep"});
				# avoid repeating it
	    if (! defined $tmp{"$name"."_"."$call"}) {
		$tmp{"$name"."_"."$call"}=1; 
		$rd{"$name","dep"}.="$call".","; }
	    next; }
    } close($fhinLoc);
    undef %tmp;			# slim-is-in !

				# all subroutines in current file
    $rd{"$titleInLoc","sbr"}=join(',',@name); $rd{"$titleInLoc","sbr"}=~s/,*$//g;
    foreach $name (@name){
	if (defined $rd{"$name","dep"}){$rd{"$name","dep"}=~s/,,+/,/g;
					$rd{"$name","dep"}=~s/^,*|,*$//g; }
        else                           {$rd{"$name","dep"}="";}
#        print "xx name=$name, dep=",$rd{"$name","dep"},"\n";
    }

    foreach $name (@name){
	$ptrName2prog{"$name"}=$titleInLoc; 
    }
    return(1,"ok $sbrName");
}				# end of processProgFor

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
    $tmpWrt=         sprintf("\* \n\* %-70s\* \n","-" x 70);
    $tmpWrt.=        sprintf("\*      %-20s %-s\n"," ","-" x length($txt));
    $tmpWrt.=        sprintf("\*      %-20s %-s\n",$titleInLoc,$txt);
    $tmpWrt.=        sprintf("\*      %-20s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                "\* \n";

				# ------------------------------
				# current names
    @name=split(/,/,$rd{"$title","sbr"});

				# ------------------------------
				# loop over all subroutines
    foreach $name (@name) {
	$des="";
        $des=$rd{"$name","dep"} if (defined $rd{"$name","dep"});
                                # chop into strings shorter than 50
        @des=split(/,/,$des); $tmp1="";
        foreach $des (@des) { $tmp=$tmp1.$des.","; $tmp=~s/^.*\n//g;
                              if (length($tmp) > 40){
                                  $tmp1.="\n"; }
                              $tmp1.=$des.","; } $tmp1=~s/,*$//g;
        @des=split(/\n/,$tmp1); 
	if (! defined $des[1] || length($des[1])<3 || ! $des[1] || $des[1]=~/^\s+$/) {
            $tmpWrt.=sprintf("*      %-20s .. %-s\n",$name,"self-content"); }
        else {
            $tmpWrt.=sprintf("*      %-20s -> %-s\n",$name,$des[1]); }
        foreach $it (2..$#des) {
            $tmpWrt.=sprintf("*      %-20s -> %-s\n","",$des[$it]); }
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
    $tmpWrt=                    sprintf("\* \n\* %-70s\* \n","-" x 70);
    $tmpWrt.=                   sprintf("\*   %-20s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                   sprintf("\*   %-20s %-s\n",$titleInLoc,$txt);
    $tmpWrt.=                   sprintf("\*   %-20s %-s\n"," ","-" x length($txt));
    $tmpWrt.=                   "\* \n";

				# ------------------------------
				# current names
    @name=split(/,/,$rd{"$titleInLoc","sbr"});
    undef %lib;			# $lib{lib-br}='x1,x2' lists all calls to lib-br
    undef %ok;			# $ok{sbr}=1           if SBR already somewhere
    $#libSbr=0;			# array with all sbrs called (also from lib 2 lib)
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
	@sbr=split(/,/,$lib{$lib});
	@sbr=sort (@sbr);
	($Lok,$msg,$tmp)=
	    &array2wrt($lib,@sbr);
	return(&errSbrMsg("failed on array2wrt for lib=$lib",$msg)) if (! $Lok);
	next if (length($tmp)<2);
	push(@libLoc,$lib);
	$tmpWrt.=               $tmp; 
	$tmpWrt.=               "\* \n"; }
    if ($#libLoc > 0){
	$rd{"$titleInLoc","lib"}=join(',',@libLoc);
	foreach $lib (@libLoc){
	    $rd{"$titleInLoc","$lib"}=$lib{$lib}; }}

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
	if (length($tmp) > 35) { push(@tmpLoc,$tmp);
				 $tmp="";}
	$tmp.="$sbrLoc".","; }
    push(@tmpLoc,$tmp)          if (length($tmp)>5);

    if ($#tmpLoc > 0){		# skip as none found in this lib
	foreach $tmp(@tmpLoc){
	    $tmp=~s/^,*|,*$//g; }
				# write
	$tmpWrt2.=    sprintf("*   %-20s %-s\n","call from ".$titleInLoc2.":",$tmpLoc[1]);
	foreach $it (2..$#tmpLoc) {
	    $tmpWrt2.=sprintf("*   %-20s %-s\n"," ",$tmpLoc[$it]); 
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

    $tmpWrt2.=    sprintf("*   %-20s %-s\n","call from ".$titleInLoc2.":"," ");
    foreach $sbrLoc (@tmpIn) {	# write
	next if (defined $tmp{$sbrLoc});
	$tmp{$sbrLoc}=1;
	$tmpWrt2.=sprintf("*   %-20s %-s\n"," ",$sbrLoc);
    }
    
    return(1,"ok $sbrName2",$tmpWrt2);
}				# end of array2wrtErr

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

    @allSort=sort (@all);
				# ------------------------------
				# all subroutines
    foreach $sbr (@allSort) {
#	print $fhoutLoc2 "*","-" x 70,"*","\n";
#        print $fhoutLoc2 "***** $sbr\n";
#	print $fhoutLoc2 "*","-" x 70,"*","\n";
	print $fhoutLoc2 $code{$sbr}; 
	print $fhoutLoc2 "***** end of $sbr\n";
	print $fhoutLoc2 "\n";
    }
    close($fhoutLoc2);

    return(1,"ok $sbrName");
}				# end of newLib

