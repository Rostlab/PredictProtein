#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="greps regular expression in *.pl, returns sbr where it occurred";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV < 2){		# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName expression prog*pl'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
    printf "      %-15s  %-20s %-s\n","set",      "no value","checks where the variable is defined";
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
    
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";

$#fileIn=$#chainIn=0;
$Ldefined=0;
$reg=$ARGV[1];
				# ------------------------------
foreach $arg (@ARGV){		# read command line
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^set$/)                 { $Ldefined=1;}
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

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $fileOut="Out-grep.tmp"; }
$LisFortran=0;
				# ------------------------------
$found="";			# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    $fileTmp=$fileIn;$fileTmp=~s/^.*\/|\.p[lm]$|\.f//g;
    $LisFortran=1               if ($fileIn =~/\.f/);
    while (<$fhin>) {
	$_=~s/\n//g; $rd=$_;
	next if ($_=~/^[\s\t]*\#/);	# skip comments
				# note: 2nd for fortran
	if ($rd=~/^sub (.*)\s*\{/ || $rd=~/^[\s\t]+SUBROUTINE (\S+)/){ 
	    $name=$1;		# sbr name
	    next; } 
				# continue expression ?
	if ($LtakeNext && ! $LisFortran){
	    $rd=~s/^[\s\t]*|[\s\t]*$//g;
	    $found.=$fileTmp."xx,xx".$name."xx,xx"."     ".$rd."\n"; 
	    $LtakeNext=0        if ($rd =~ /\;/);
	    next; }
	if ($rd=~/$reg/){	# pattern found
	    next if ($Ldefined && $rd !~ /$reg.?[^\;]*=/);	# restrict search to definition?
	    $LtakeNext=1 if ($rd !~/\;/);
	    $rd=~s/^[\s\t]*|[\s\t]*$//g;
	    $found.=$fileTmp."xx,xx".$name."xx,xx".$rd."\n"; 
	    next;} 
    }
    close($fhin);
}
				# ------------------------------
				# (2) process lines
				# ------------------------------
@found=split(/\n/,$found);
$#file=$#name=$#line=0;$max=0;
foreach $found (@found){
    ($file,$name,$line)=split(/xx,xx/,$found);
    $max=length($name)          if ($max < length($name));
    push(@file,$file);push(@name,$name);push(@line,$line); }
$format="%-".$max."s";
				# ------------------------------
				# build up
				# ------------------------------
$tmpWrt= "";
foreach $it (1..$#line){
    $tmpWrt.=sprintf("%-s:",     $file[$it]) if ($#fileIn>1);
    $tmpWrt.=sprintf("$format: %-s\n",
		     $name[$it],$line[$it]);
}
				# ------------------------------
				# (3) write output
				# ------------------------------
&open_file("$fhout",">$fileOut"); 
print $fhout $tmpWrt;
close($fhout);

print $tmpWrt;
print "--- output in $fileOut\n" if (-e $fileOut);
exit;

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

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

