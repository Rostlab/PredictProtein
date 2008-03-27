#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="mirrors summary from Tableqils files";
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
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "use: \t '$scrName Tableqils*'\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","many",    "no value", "writes 'syn-' file for each input";
    printf "     \t %-15s  %-20s %-s\n","noClass", "no value","skip class (content) stuff";
    printf "     \t %-15s  %-20s %-s\n","noCorr",  "no value","skip matthews correlation";
    printf "     \t %-15s  %-20s %-s\n","noSet",   "no value","skip per-protein average";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}!~/\D/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}!~/[0-9\.]/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
$LdoClass=   1;			# do include statistics on class, content
$LdoCorr=    1;			# do include Matthews correlation
$LdoSetAve=  1;			# do include averages over many proteins
$Lmany=      0;			# mirror file name (if = 1)


				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^many$/)                { $Lmany=1;}
    elsif ($arg=~/^no[Cc]lass$/)          { $LdoClass=0; }
    elsif ($arg=~/^no[Cc]orr?$/)          { $LdoCorr=0; }
    elsif ($arg=~/^no[Ss]et[ave]*$/)      { $LdoSetAve=0; }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
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
if    (! defined $fileOut && $#fileIn==1){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/Tableqils[\-\_]//g;$fileOut="syn-".$tmp;}
elsif (! defined $fileOut){
    $fileOut="Syn-many.tmp"; }

				# ------------------------------
				# build up
				# ------------------------------
$argSyn="";
$argSyn.="noClass,"             if (! $LdoClass);
$argSyn.="noCorr,"              if (! $LdoCorr);
$argSyn.="noSetAve,"            if (! $LdoSetAve);
$argSyn=~s/,*$//;

				# ------------------------------
				# (1) read file(s)
$#wrt=$#name=0;			# ------------------------------
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";

    ($Lok,$msg,$wrt)=
	&evalsecTableqils2syn($fileIn,$argSyn);

    if (! $Lok) { print "*** ERROR $scrName: failed reading table for $fileIn\n",$msg,"\n";
		  exit; }
    $tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/Tableqils[\-\_]//g;
    push(@wrt,$wrt); push(@name,$tmp);
				# ------------------------------
				# intermediate out
    if ($Lmany) {
	$fileOutLoc="syn-".$tmp;
	&open_file("$fhout",">$fileOutLoc"); 
	print $fhout $wrt;
	close($fhout); }
}
				# ------------------------------
$max=0;				# get longest name
if ($#fileIn>1){
    foreach $it (1..$#wrt){
	$max=length($name[$it]) if (length($name[$it]) > $max); }
    $form="%-".$max."s".":";  }
				# ------------------------------
				# (3) write output
				# ------------------------------
&open_file("$fhout",">$fileOut"); 
$#syn=0;
foreach $it (1..$#wrt){
    @wrtSin=split(/\n/,$wrt[$it]);
    $tmp=""; $tmp.=" " x $max ." "  if ($max>0);
    $tmp.="--- "."-" x 60 . "\n";   push(@syn,$tmp);
    foreach $wrtSin (@wrtSin){
	if ($#fileIn>1){
	    $wrt= sprintf ("$form%-s\n",$name[$it],$wrtSin); }
	else {
	    $wrt= sprintf ("%-s\n",$wrtSin); }
	print $fhout $wrt;
				# final synopsis
	push(@syn,$wrt)         if ($wrtSin =~/^\s*SYN/); }
}

foreach $syn (@syn){		# final synopsis
    print $fhout $syn; 
}
close($fhout);

foreach $syn (@syn){		# final synopsis : screen
    print $syn; 
}

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
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

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
sub evalsecTableqils2syn {
    local($fileInLoc,$optLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   evalsecTableqils2syn        greps the final summary from TABLEQILS (xevalsec.f)
#       in:                     $fileInLoc
#       in:                     $optLoc='noClass|noSetAve|noCorr'
#       out:                    1|0,msg, $tmpWrt (sprintf)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."evalsecTableqils2syn";$fhinLoc="FHIN_"."evalsecTableqils2syn";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    $LdoClass=1;		# do include statistics on class, content
    $LdoCorr=1;			# do include Matthews correlation
    $LdoSetAve=1;		# do include averages over many proteins

    $LdoClass=0                 if (defined $optLoc && $optLoc =~ /noClass/);
    $LdoCorr=0                  if (defined $optLoc && $optLoc =~ /noCorr/);
    $LdoSetAve=0                if (defined $optLoc && $optLoc =~ /noSetAve/);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# ------------------------------
    while (<$fhinLoc>) {	# read until ' --- \s for all '
	$tmp=$_;
	last if ($_=~/^ \-+\s+for all\s+/); }
				# build up wrt
    $tmpWrt1=      "$tmp";
				# ------------------------------
    while (<$fhinLoc>) {	# read until blank line
	last if ($_!~/^ [\+\|]/); 
	$tmpWrt1.= "$_"; }
				# ------------------------------
    while (<$fhinLoc>) {	# read until correlation
	$_=~s/\n//g; $rd=$_;
	if ($rd=~/^.*Q3mean =\s+([0-9\.]+)\s+/){
	    $aveProtQ3=$1;
	    next; }
	if ($rd=~/^.*sqrt\( Q3var \) =\s+([0-9\.]+)\s+/){
	    $aveProtSig=$1;
	    next; }
	$tmp=$rd; $tmp=~s/^\s\-+\s*//g;
	next if (length($tmp)<1);
	if ($rd=~/all.* contav .([HE])\s*=\s*([0-9\.]+)\s.*=\s*([0-9\.]+)/){
	    if    ($1 eq "H"){
		$contHdel=$2; $contHsig=$3; }
	    elsif ($1 eq "E"){
		$contEdel=$2; $contEsig=$3; }
	    next; }
	last if ($rd=~/Correlation coeffi/); }

    $tmpWrt2=      "$rd\n"; 
				# ------------------------------
    while (<$fhinLoc>) {	# read class
	$_=~s/\n//g; $rd=$_;
	$tmp=$rd; $tmp=~s/^\s\-+\s*//g;
	next if (length($tmp)<1);
	$tmpWrt2.= "$rd\n"; }
    close($fhinLoc);
				# ------------------------------
				# process
    $tmpWrt= $tmpWrt2;
    $tmpWrt.=$tmpWrt1;
				# overall table 
    @tmp=split(/\n/,$tmpWrt1);
    foreach $tmp (@tmp){
	if ($tmp =~ /\|                                    \|(.*)$/){
	    $tmp=$1;
	    $tmp=~s/\|                   \|.*$//g;
	    $tmp=~s/\|/ /g;
	    @num=split(/\s+/,$tmp);
	    @cor[1..3]=@num[1..3];
	    $q3=$num[4]; 
	    next; }
	if ($tmp =~ /^\s*\|\s*SOV\s*\|\s*(.+)$/){
	    $tmp=$1; $tmp=~s/\|/ /g;
	    $tmp=~s/^\s*|\s*$//g;
	    @num=split(/\s+/,$tmp);
	    $sovObs=$num[4];
	    $sovPrd=$num[8];
	    $info=$num[9]; $info=~s/\s([0-9\.]+)\s*.*$/$1/g;
	}}
				# class acc
    @tmp=split(/\n/,$tmpWrt2);
    foreach $tmp (@tmp){
	if ($tmp=~/.*SUM\s*\|\s*(.*)$/){
	    $tmp=$1; $tmp=~s/\|/ /g;
	    $tmp=~s/^\s*|\s*$//g;
	    @num=split(/\s+/,$tmp);
	    $classObs=$num[4]; $classPrd=$num[5];
	}
    }
				# ------------------------------
				# formats
    $fcor= "%5.2f,%5.2f,%5.2f";
    $fcont="%5.1f,%5.1f";
				# ------------------------------
				# sec str content
    if ($LdoClass) {
	$tmpWrt.=sprintf("%-30s %5.1f,%5.1f\n",       
			 "SYN Q4class  obs,prd:",$classObs,$classPrd);
	$tmpWrt.=sprintf("%-30s $fcont ($fcont)\n",   "SYN DcontH,E   (sig):",
			 $contHdel,$contEdel,$contHsig,$contEsig);}
				# ------------------------------
				# protein averages
    if ($LdoCorr) {
	$tmpWrt.=sprintf("%-30s %6.2f %-4s ($fcor)\n",
			 "SYN I     (corH,E,L):",$info," ",@cor);}
    $tmpWrt.=    sprintf("%-30s %5.1f,%5.1f\n",       "SYN SOV      obs,prd:",
			 $sovObs,$sovPrd);
    if ($LdoSetAve) {
	$tmpWrt.=sprintf("%-30s %5.1f %-5s (%5.1f)\n","SYN Q3prot     (sig):",
			 $aveProtQ3," ",$aveProtSig);}
    $tmpWrt.=    sprintf("%-30s %5.1f \n",            "SYN Q3res           :",$q3);
		     
    return(1,"ok $sbrName",$tmpWrt);
}				# end of evalsecTableqils2syn 

