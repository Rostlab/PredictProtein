#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts PALM address to something for word\n".
    "     \t do: 1. extract from palm into TAB format\n".
    "     \t     2. run this\n".
    "     \t     3. import into word, format, print\n".
    "     \t     \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Feb,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;

$#kwdcol=0;
@kwdcol=
    (
     "First_Name",
     "Last_Name",
     "Nickname",
     "Prefix",
     "Suffix",
     "Title",
     "Company",
     "Division",
     "Address_1_Label",
     "Street_1_Line_1",
     "Street_1_Line_2",
     "City_1",
     "State_1",
     "Zip_1",
     "Country_1",
     "Address_2_Label",
     "Street_2_(Line_1)",
     "Street_2_(Line_2)",
     "City_2",
     "State_2",
     "Zip_2",
     "Country_2",
     "Phone_1_Label",
     "Phone_1",
     "Extension_1",
     "Phone_2_Label",
     "Phone_2",
     "Extension_2",
     "Phone_3_Label",
     "Phone_3",
     "Extension_3",
     "Phone_4_Label",
     "Phone_4",
     "Extension_4",
     "Comments",
     "Birthday",
     "Email",
     "Web_Site",
     "Custom_1",
     "Custom_2",
     "Custom_3",
     "Custom_4",
     "Custom_5",
     "Custom_6",
     "Custom_7",
     "Custom_8",
     "Custom_9",
     "Modified",
     "Marked",
     "Category_1",
     "Category_2",
     );

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s %-20s %-s\n","","priv",    "no value","only private addresses";
    printf "%5s %-15s %-20s %-s\n","","off",     "no value","only office addresses";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$Lpriv=$Loff=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^priv$/)                { $Lpriv=          1;}
    elsif ($arg=~/^off$/)                 { $Loff=           1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn\n") 
    if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

$Lpriv=$Loff=1                  if (! $Lpriv && ! $Loff);

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=0;
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn";
    while (<$fhin>) {
	$_=~s/\n//g;
	$line=$_;
				# names:
	if ($_=~/^First|^Marked/){
	    @tmp=split(/\t/,$_);
	    foreach $it (1..$#tmp){
		$tmp=$tmp[$it]; 
		$tmp=~s/\s/_/g;	# blanks to '_'
		$tmp=~s/[\(\)]//g; # delete brackets
		
		$ptr_col2name[$it]=$tmp;
		$ptr_name2col{$tmp}=$it; 
	    }
	    next; }
				# body:
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){
	    $tmp[$it]=~s/^\s*|\s*$//g;
	    next if ($tmp[$it]=~/other/i || length($tmp[$it])<1);
	    $res{$ct,$ptr_col2name[$it]}=$tmp[$it];
	    print "xx ct=$ct, it=$it, tmp=$tmp[$it], ($ptr_col2name[$it])\n"
		if ($line=~/Sali/);
	}
    }
    close($fhin);
}
$res{"NROWS"}=$ct;
				# ------------------------------
				# (2) process output
				# ------------------------------
$#name=0;
foreach $it (1..$res{"NROWS"}){
    next if ($Lpriv && 
	     ((defined $res{$it,"Category_1"} && $res{$it,"Category_1"} =~/Work/) ||
	      (defined $res{$it,"Category_2"} && $res{$it,"Category_2"} =~/Work/)));
    next if ($Loff && 
	     ((defined $res{$it,"Category_1"} && $res{$it,"Category_1"} =~/Priv/) ||
	      (defined $res{$it,"Category_2"} && $res{$it,"Category_2"} =~/Priv/)));

#    $res{$it,"Last_Name"}=~s/\s//g;
    $tmpwrt= $res{$it,"Last_Name"};
    
    $tmpwrt.=", ".$res{$it,"First_Name"}     if (defined $res{$it,"First_Name"});
    $tmpwrt.=":";

    if (! $Lpriv){
	$tmpwrt.=$res{$it,"Company"}         if (defined $res{$it,"Company"});
	$tmpwrt.=$res{$it,"Division"}        if (defined $res{$it,"Division"});
    }
    $#tmp=0;
    foreach $itx (1..2){
	$tmp[$itx]="";
	if (defined $res{$it,"Address_".$itx."_Label"}){
	    if ($res{$it,"Address_".$itx."_Label"} =~/work/i){
		$tmp[$itx].=" w:";}
	    else {
		$tmp[$itx].=" p:";}
	}
		
	$tmp[$itx].=
	    " ".$res{$it,"Street_".$itx."_Line_1"} if (defined $res{$it,"Street_".$itx."_Line_1"});
	
	$tmp[$itx].=
	    " ".$res{$it,"Street_".$itx."_Line_2"} if (defined $res{$it,"Street_".$itx."_Line_2"} &&
						       $res{$it,"Street_".$itx."_Line_2"}=~/^\S+$/);
	$tmp[$itx].=", "                           if (defined $res{$it,"Street_".$itx."_Line_1"});
	if (defined $res{$it,"Country_".$itx} && $res{$it,"Country_".$itx} =~ /usa/i){
	    $tmp[$itx].=" ".$res{$it,"City_".$itx}      if (defined $res{$it,"City_".$itx});
	    $tmp[$itx].=",".$res{$it,"Zip_".$itx}       if (defined $res{$it,"Zip_".$itx});
	    $tmp[$itx].=" ".$res{$it,"State_".$itx}     if (defined $res{$it,"State_".$itx});}
	else {
	    $tmp[$itx].=" ".$res{$it,"Zip_".$itx}       if (defined $res{$it,"Zip_".$itx});
	    $tmp[$itx].=" ".$res{$it,"City_".$itx}      if (defined $res{$it,"City_".$itx});}
    }
    if (Lpriv){
	if (defined $tmp[1] && length($tmp[1])>2 &&
	    defined $tmp[2] && length($tmp[2])>2){
	    $tmpwrt.=$tmp[1]." (";
	    $tmpwrt.="w "       if ($tmp[2]!~/^\sw/);
	    $tmpwrt.=$tmp[2]."),";}
	elsif (defined $tmp[2] && length($tmp[2])>2){
	    $tmpwrt.=$tmp[2].",";}
	elsif (defined $tmp[1] && length($tmp[1])>2){
	    $tmpwrt.=$tmp[1].",";} }
    else {
	foreach $tmpx (@tmp){
	    next if (! defined $tmpx || length($tmpx)<3);
	    $tmpwrt.=" ".$tmpx.",";}}

    $phone=$fax=$work=$priv=$cell=0;
    $#phone=0;
    foreach $itx (1..4){
	if    (defined $res{$it,"Phone_".$itx."_Label"} &&
	       defined $res{$it,"Phone_".$itx}          &&
	       $res{$it,"Phone_".$itx."_Label"} =~/fax/i){
	    $fax=$res{$it,"Phone_".$itx}; }
	elsif (defined $res{$it,"Phone_".$itx."_Label"} &&
	       defined $res{$it,"Phone_".$itx}          &&
	       $res{$it,"Phone_".$itx."_Label"} =~/work/i){
	    $work=$res{$it,"Phone_".$itx}; }
	elsif (defined $res{$it,"Phone_".$itx."_Label"} &&
	       defined $res{$it,"Phone_".$itx}          &&
	       $res{$it,"Phone_".$itx."_Label"} =~/priv/i){
	    $priv=$res{$it,"Phone_".$itx}; }
	elsif (defined $res{$it,"Phone_".$itx."_Label"} &&
	       defined $res{$it,"Phone_".$itx}          &&
	       $res{$it,"Phone_".$itx."_Label"} =~/cell/i){
	    $cell=$res{$it,"Phone_".$itx}; }
	elsif (defined $res{$it,"Phone_".$itx}){
	    $tmp2=" w:" if ($itx==1);
	    $tmp2=" p:" if ($itx>1);
	    push(@phone,$tmp2.$res{$it,"Phone_".$itx});}}
    $tmpwrt.=", "       if ($priv || $cell || $work || $fax || $phone);
    $tmpwrt.=" p:$priv" if ($priv);
    $tmpwrt.=" c:$cell" if ($cell);
    $tmpwrt.=" w:$work" if ($work);
    $tmpwrt.=" f:$fax"  if ($fax);
    $ct=0;
    foreach $phone (@phone){
	++$ct;
	if ($#phone==1){
	    $phone=~s/ [wp]://g;}
	elsif ($phone !~/[wp]:/){
	    $phone="$ct:".$phone;}
	$tmpwrt.=" ".$phone;}
	
#    $tmpwrt.=$res{$it,}
#    $tmpwrt.=$res{$it,}
    $tmpwrt.=",";

    $tmpwrt=~s/\,\s*\,/\,/g;
    $tmpwrt=~s/\,\,/\,/g;
    $tmpwrt=~s/[\.,_ ]$//g;
    $tmpwrt=~s/:\,/:/g;
    $tmpwrt=~s/(\s)\s+/$1/g;
    $tmpwrt=~s/zz,/zz/g;
    $tmpwrt=~s/,(\S)/, $1/g;
    $tmpwrt=~s/\( /\(/g;
    $tmpwrt=~s/ \)/\)/g;
    print $tmpwrt,"\n";
    $name=  $res{$it,"Last_Name"};
    $name.= "_".$res{$it,"First_Name"} if (defined $res{$it,"First_Name"});
    $fin{$name}=$tmpwrt;
    push(@name,$name);
#    exit;
}
				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
undef %tmp;
foreach $name (sort @name){
    next if (defined $tmp{$name});
    print $fhout $fin{$name},"\n";
    print $fin{$name},"\n";
}
close($fhout);

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

