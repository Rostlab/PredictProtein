#!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "files to convert";
$scrGoal="convert MAC files 'META r' to unix 'MET n'\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   \n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2002	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2002	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one
#

				# ------------------------------
				# defaults
   %par=(
      '', "",			# 
      );
   @kwd=sort (keys %par);
   $Ldebug=0;
   $Lverb= 1;
   $sep=   "\t";
				# ------------------------------
   if ($#ARGV<1 ||			# help
       $ARGV[1] =~/^(-h|help|special)/){
       print  "goal: $scrGoal\n";
       print  "use:  '$scrName $scrIn'\n";
       print  "opt:  \n";
				#      'keyword'   'value'    'description'
       printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
       printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";

       printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
       printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
       printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

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
       exit;
   }
				# initialise variables
   $fhin="FHIN";$fhout="FHOUT";
   $#fileIn=0;
   $dirOut=0;
				# ------------------------------
				# read command line
   foreach $arg (@ARGV){
       if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
       elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					       $dirOut.="/"     if ($dirOut !~ /\/$/);}
       
       elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					       $Lverb=          1;}
       elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
       elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
       elsif (-e $arg)                       { push(@fileIn,$arg); }
       else {
	   $Lok=0; 
	   if (defined %par && $#kwd>0) { 
	       foreach $kwd (@kwd){
		   if ($arg =~ /^$kwd=(.+)$/){
		       $Lok=1;$par{$kwd}=$1;
		       last;	# 
		   }		# 
	       }			# 
	   }			# 
	   if (! $Lok){ 
	       print "*** wrong command line arg '$arg'\n";
	       exit;
	   }
       }
   }
   
   $fileIn=$fileIn[1];

   die ("*** ERROR $scrName: missing input $fileIn!\n") 
   if (! -e $fileIn);
				# 
   $dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);

   if (! defined $fileOut){
       $tmp=$fileIn;$tmp=~s/^.*\///g;
       $tmp=~s/\..*$//g;
       $tmp.=".unix";
       if ($dirOut){
	   $fileOut=$dirOut.$tmp;
       }
       else {
	   $fileOut=$tmp;
       }
       $fileOut.="x" if (-e $fileOut);
   }

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
   $ctfile=0;
   foreach $fileIn (@fileIn){
       ++$ctfile;
       if (! -e $fileIn){
	   print "-*- WARN $scrName: no fileIn=$fileIn\n";
	   next;
       }
       printf 
	   "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	   $fileIn,$ctfile,(100*$ctfile/$#fileIn)
			    if ($Lverb);
       open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
       $tmp=<$fhin>;
       close($fhin);
       $tmp=~s/\r/\n/g;
       if (! defined $fileOut || -e $fileOut){
	   $fileOut=$fileIn;
	   $fileOut=~s/^.*\///g;
	   $fileOut.=".unix";
       }
       open($fhout,">".$fileOut)|| warn "*** $scrName ERROR opening fileOut=$fileOut!\n";
       print $fhout $tmp;
       close($fhout);
       print $tmp if ($Ldebug);
   }

   if ($Lverb){
       print "--- last output in $fileOut\n" if (-e $fileOut);
   }
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

