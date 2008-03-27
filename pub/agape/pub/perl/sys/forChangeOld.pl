#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="changes address and other old stuff in old FORTRAN programs";
#  
#
$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib("lib-ut.pl","lib-br.pl"){
    require $dir.$lib ||
	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *.f'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","lib",      "no value","if is lib:";
    printf "      %-15s  %-s\n","lib"," ",   "expects header with explanations";
    printf "      %-15s  %-s\n","lib","NOTE","put tags: 'HEADER lib', 'end HEADER lib'";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	$tmp= sprintf("      %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("      %-15s  %-20s %-s\n","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("      %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("      %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    die;}
				# initialise variables
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
$LisLib=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^lib$/)                 { $LisLib=1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if (! &is_list($fileIn)) {push(@fileTmp,$fileIn);
			      next;}
    ($Lok,$msg,$file,$tmp)=&fileListRd($fileIn); 
    if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
		 die; }
    @tmpf=split(/,/,$file); push(@fileTmp,@tmpf);
}@fileIn= @fileTmp; 

$#fileOut=0;
				# ------------------------------
				# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $title=$fileIn; $title=~s/^.*\/|\.f//g;
    print "--- $scrName: working on $title ($fileIn)\n";
				# --------------------------------------------------
				# returns GLOBAL %rd:
				#    $code{$name}, @name (names of all sbrs)
				# --------------------------------------------------
    ($Lok,$msg)=
	&processProgFor($fileIn,$title,$LisLib);
    if (! $Lok) { print 
		      "*** ERROR $scrName: after processProg ($fileIn,$title)\n",
		      $msg,"\n";
		  die; } 
    $fileOut=$fileIn; $fileOut=~s/^.*\///g; $fileOut="NEW".$fileOut;
    &open_file("$fhout",">$fileOut"); 
    foreach $name (@name){
	print $fhout $code{$name}; }
    close($fhout);
    push(@fileOut,$fileOut);
}

print "--- output in file:  $fileOut[1]\n" if ($#fileOut==1);
print "--- output in files: ",join(',',@fileOut,"\n") if ($#fileOut>1);

exit;

#===============================================================================
sub processProgFor {
    local($fileInLoc,$titleInLoc,$LisLibLoc) = @_ ;
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
#       in:                     $LisLib=1|0 : if = 1, expect header in file with descriptions
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
    undef %Lok; $#name=$#nameHdr=$#type=0; undef %tmp;
    undef %code; undef %date;
                                # ------------------------------
                                # digest header for libs
                                # ------------------------------
    if ($LisLibLoc){
        $Lhdr=$name=0;
        while (<$fhinLoc>) {
            $_=~s/\n//g;$rd=$_;
            if ($rd=~/^\* HEADER/i){ $Lhdr=1;
                                     next;}
            last if ($rd=~/^\* end HEADER/i);
            next if (! $Lhdr);
                                # skip empty comments...
            next if ($rd=~/^[\*C]\s*$/           ||
                     $rd=~/^[\*C]\*+\*$/         ||
                     $rd=~/^[\*C]\-+.*\-\s*\**$/ ||
                     $rd=~/^[C\*]\s+\**\s*\*$/   ||
                     $rd=~/^[C\*]\s+\-*\s*\*$/   ||
                     $rd=~/^[C\*]\s+\-*\s*\*$/   ||
                     $rd=~/^[C\*]\-\-\-*[\*\-]$/ ||
                     $rd=~/^[C\*]\s+execution of subr/ 
                     ); 
            next if ($rd=~/(CHARACTER|INTEGER|REAL)\s*FUNCTIONS/i ||
                     $rd=~/subroutines treating/ );

                                # new description
            if ($rd=~/^[\*C]\-\-\-+ \s*(\S+.*)$/){
                $name=$1;
                $name=~s/^(INTEGER|CHARACTER|REAL) FUNCTION\s*\([^\)]\)\s*//ig;
                $name=~s/^FUNCTION\s+\([^\)]+\)\s*//ig;
                $name=~s/^(INTEGER|CHARACTER|REAL) FUNCTION\s*//g;
                $name=~s/(\S+)\s*(.*)$/$1/;
                push(@nameHdr,$name); 
                $des{"$name","arg"}=$2; 
                $des{"$name","arg"}=~s/[\s\*]*$//g; $des{"$name","arg"}=~s/^\(|\)$//g;
                $des{"$name","des"}="";
                next; }
                                # continue new des
            if ($name){
                $tmp=$rd; $tmp=~s/^[\*C]\s*|\s*[\*C]?\s*$//g;
                $des{"$name","des"}.=$tmp."\n"; }} }

				# ------------------------------
                                # remaining: real CODE!!
				# ------------------------------
    $name=$date=0;
    while (<$fhinLoc>) {
	$line=$_;
	$_=~s/\n//g;$rd=$_;
                                # skip empty comments...
        if ($rd=~/^[C\*]/) {
            next if ($rd=~/^[\*C]\s*$/         ||
                     $rd=~/^[C\*]\s+\**\s*\*$/ ||
                     $rd=~/^[C\*]\s+\-*\s*\*$/ ||
                     $rd=~/^[C\*]\s+execution of subr/ 
                     ); }

                                # END of MAIN/previous sbr
	if ($rd=~/^[\s\t]+END[\s\t]*$/){
	    next if (! $name);
            $code{$name}.=$line; 
	    $name=$des=$hdr=$date=0;
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
            $type=$1;
	    if (! defined $2){ print "*** ERROR $sbrName: not defined name\n";
			       print "*** line=$line";
			       die; }
            $name=$2; 
            $name=~tr/[a-z]/[A-Z]/; # all capitals
	    $des=1; 
            $comments=""; $comments.=join("\n",@hdr)."\n" if ($#hdr>0);
            push(@name,$name); push(@type,$type); push(@hdr,$comments);

	    # ***********************
	    $code{$name}="";
            $code{$name}.=$comments if (defined $comments);
	    $code{$name}.="*"."-" x 70 . "*\n" if ($code{$name} !~ /\-\-\*\n$/);
	    $date{$name}=$date  if (defined $date && $date);
            $code{$name}.=$line; 
	    # ***********************

	    next; }
                                # is description of subroutine
        if (! $name && $rd=~/^[\*C]/){
				# skip from header
	    next if ($rd=~/^[\*C]\s*\*\*\*+/   || 
                     $rd=~/^[C\*]\s*\-*\s*\*$/ ||
		     $rd=~/^[\*C].*definition of/); 
	    if ($rd=~/burkhard rost\s*([A-Za-z]*).*(19\d+)/i) {
		$date= substr($1,1,3).",".$2;
		next; }
	    if ($rd=~/changed\s*:?\s*([A-Za-z]*).*(19\d+)/) {
		$date=""        if (! defined $date);
		$date.="\n".substr($1,1,3).",".$2;
		next; }
	    next if ($rd=~/^[C\*][\s\t]+EMBL/         ||
		     $rd=~/^[C\*][\s\t]+Meyerhof/i    ||
		     $rd=~/^[C\*][\s\t]+D\-69/i);
		     
            push(@hdr,$rd);
            next;}

	next if (! defined $name || ! $name);

	# ***********************
	$code{$name}=""         if (! defined $code{$name});
	$code{$name}.=$line;
	# ***********************
    } close($fhinLoc);
    undef %tmp;			# slim-is-in !

				# all subroutines in current file
    $rd{"$titleInLoc","sbr"}=join(',',@name); $rd{"$titleInLoc","sbr"}=~s/,*$//g;

				# --------------------------------------------------
				# new code
				# --------------------------------------------------

    $before= "***** ". "-" x 66 ."\n";
    foreach $it (1..$#name){
				# ------------------------------
                                # before subroutine/function
				# ------------------------------
        $name=$name[$it];
#	print "xx $name\n";     next;                   # xx
        

        if ($type[$it] =~ /FUNC/i){ 
            $build=$before."***** FCT ".$name."\n".$before;}
        else {
            $build=$before."***** SUB ".$name."\n".$before; }

				# ------------------------------
                                # header for libs
				# ------------------------------
        if ($LisLibLoc){
	    $build.=    "C---- \n";
            $build.=    "C---- "."NAME : ".$name."\n";
	    $des{"$name","arg"}=" " if (! defined $des{"$name","arg"});
            $build.=    "C---- "."ARG  : ".$des{"$name","arg"}."\n";

                                # chop into strings shorter than 50
	    $des{"$name","des"}=" " if (! defined $des{"$name","des"});
	    @des=split(/\n/,$des{"$name","des"}); $tmp1="";
	    foreach $des (@des) { 
		$tmp=$tmp1.$des." ";
				# split into words
		if (length($tmp) > 50){
		    @word=split(/\s+/,$des);
		    $tmp2="";
		    foreach $word (@word){
			$tmp=$tmp2."$word "; $tmp=~s/^.*\n//g;
			$tmp2.="\n" if (length($tmp) > 55);
			$tmp2.="$word "; }
		    $tmp1.="$tmp2\n";}
		else {
		    $tmp1.=$des." "; } }
	    @des=split(/\n/,$tmp1); 
	    foreach $des (@des) {
		$build.="C---- "."DES  : ".$des."\n"; } 
	    $build.=    "C---- \n";
	}
				# ------------------------------
				# add address /date
				# ------------------------------
	$build.="*"."-" x 70 . "*\n";

	$build.=        sprintf("*     %-25s %-3s,%7s %-4s %6s %-11s    *\n",
                                "Burkhard Rost","Aug"," ","1998"," ","version 1.0");
	$build.=        sprintf("*     %-25s %-38s *\n",
                                "EMBL\/LION","http:\/\/www\.embl-heidelberg\.de\/\~rost\/");
	$build.=        sprintf("*     %-25s %-38s *\n",
                                "D-69012 Heidelberg","rost\@embl-heidelberg\.de");
	if (0 && defined $date{$name}){	# xx
#	    print "xx $name date=",$date{$name},"\n";
            @date=split(/\n/,$date{$name});
            $ct=0;
            foreach $date (@date){
                ($month,$year)=split(/,/,$date); ++$ct;
                $build.=sprintf("*     %25s %-3s,%7s %-4s %6s %-11s    *\n",
                                "changed:",     $month," ",$year," ","version 0.".$ct);} }
        $build.=        sprintf("*     %25s %-3s,%7s %-4s %6s %-11s    *\n",
                                "changed:",     "Aug"," ","1998"," ","version 1.0");
	$build.="*"."-" x 70 . "*\n";

				# ------------------------------
				# add to code
				# ------------------------------
	if (length($build)>1){
	    $code{$name}=
		$build.
		    $code{$name}; }
				# final line
	$code{$name}.="***** end of $name\n"."\n";
    }

    return(1,"ok $sbrName");
}				# end of processProgFor

