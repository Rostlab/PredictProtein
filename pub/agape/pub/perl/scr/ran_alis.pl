#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#----------------------------------------------------------------------
# ran_alis
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	ran_alis.pl file_hssp (or list of files) list_hssp (to align)
#
# task:		evaluates random alignments
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost		       April	,       1995           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&ran_alis_ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# --------------------------------------------------
				# first read all sequences to be aligned
$#id2=$ctali=0;
&open_file("$fhin","$list_in");
while(<$fhin>){
    $_=~s/\s|\n//g;
    next if (length($_)<2);
    $file_tmp=$_;
    if (-e $file_tmp) {
	%rd=&hssp_rd_seq($file_tmp);
	$id2=$file_tmp;$id2=~s/.*\/|\.hssp.*//g;
	++$ctali;
	push(@id2,$id2);
	$ali[$ctali]="";
	foreach $it (1..$rd{"len1"}){$ali[$ctali].=$rd{"seq","$it"}}
	$ali[$ctali]=~s/[a-z]/C/g;	# replace cysteines
	print"x.x $ctali,$id2:$ali[$ctali]\n";
    }
}
close($fhin);
$nali=$ctali;
				# --------------------------------------------------
				# input = single hssp or list?
$#file_hssp=0;
if (&is_hssp($file_in)){ push(@file_hssp,$file_in);}
else {
    &open_file("$fhin","$file_in");
    while(<$fhin>){ $_=~s/\s|\n//g;
				# next if empty line, or file not existing
		    next if ( (length($_)<2)||(!-e $_) );
		    push(@file_hssp,$_); }
    close($fhin); }

				# --------------------------------------------------
				# profile/metric stuff
				# --------------------------------------------------
$string_aa= &metric_ini;	# aa's: = "VLIMFWYGAPSTCHRKQENDBZ"
@aa=split(//,$string_aa);
&profile_ini($string_aa);	# initialise profile computation
				# read metric
%metric=    &metric_rd($file_metric);
				# normalise metric
%metricnorm=&metric_norm_minmax(0,1,$string_aa,%metric);

				# --------------------------------------------------
				# now loop over all input files
				# --------------------------------------------------
$#ide=$#len=$#wide=$#wnide=0;
foreach $file_hssp (@file_hssp) {
				# read sequence
    %rd=&hssp_rd_seq($file_hssp);
    $seq1="";
    $id1=$rd{"id1"};
    foreach $it (1..$rd{"len1"}){$seq1.=$rd{"seq","$it"};}
    $seq1=~s/[a-z]/C/g;		# replace cysteines
    print"x.x now analysing id=$id1: $seq1\n";
				# --------------------
				# multiple comparisons
    foreach $repeat (1..$nrepeat){
				# analyse identity
	($ide,$len,$wide,$wnide)=&compare_seq($seq1,@ali);
	push(@ide,$ide);push(@len,$len);push(@wide,$wide);push(@wnide,$wnide);
    }
}
				# --------------------------------------------------
				# compute profile values
$sum=$num=$sum2=0;
foreach $aa1 (@aa){ foreach $aa2 (@aa){ 
    $sum+=($profnum{"$aa1","$aa2"}*$metric{"$aa1","$aa2"});
    $sum2+=($profnum{"$aa1","$aa2"}*$metricnorm{"$aa1","$aa2"});
    $num+=$profnum{"$aa1","$aa2"};
}}


				# --------------------------------------------------
				# write output files
$#hist=$#hist_wnide=0;
&open_file("$fh_gr",">$file_gr");
printf $fh_gr "# weighted average over residue = %7.3f\n",$wide_av;
printf $fh_gr "# normalised (0-1) weighted average over residue = %7.3f\n",$wnide_av;
printf $fh_gr "# metric for weighting %-s\n",$file_metric;
printf $fh_gr "%5s\t%6s\t%6s\t%6s\t%5s\t%5s\n","no","pide","w_pide","wn_pide","len","sum_ide";
$ide_av=$sum=$num=$wide_av=$wnide_av=0;
foreach $it (1..$#ide){
    if ($len[$it]>0){
	$ide_perc=100*($ide[$it]/$len[$it]);
	$wnide_perc=100*($wnide[$it]/$len[$it]);
	$wide_perc=($wide[$it]/$len[$it]);
	$ide_av+=$ide_perc;
	$sum+=$ide[$it];$num+=$len[$it];
	$wide_av+=$wide[$it];$wnide_av+=$wnide[$it];
	printf $fh_gr 
	    "%5d\t%6.1f\t%6.2f\t%6.1f\t%5d\t%5d\n",
	    $it,$ide_perc,$wide_perc,$wnide_perc,$len[$it],$ide[$it];
	$tmp=int($scale*$ide_perc);
	++$hist{"$tmp"};
	$tmp=int($scale*$wnide_perc);
	++$hist_wnide{"$tmp"};
    }
}
$ide_av=$ide_av/$#ide;
$ide_av_all=100*$sum/$num;
$wide_av=$wide_av/$#ide;
$wnide_av=$wnide_av/$#ide;
$ide_av_num=$num;
close($fh_gr);

&open_file("$fh_hist",">$file_hist");
printf $fh_hist "# average over %9d residues= %7.3f\n",$ide_av_num,$ide_av_all;
printf $fh_hist "# average over %9d proteins= %7.3f\n",$#ide,$ide_av;
print $fh_hist "ide\tnumber of pairs\n";
foreach $it (1..($scale*100)){
    if (defined($hist{"$it"})){
	printf $fh_hist "%4.1f\t%8d\n",($it/$scale),$hist{"$it"};}
}
close($fh_hist);

&open_file("$fh_hist",">$file_histw");
printf $fh_hist "# weighted average over %9d residues \t= %7.3f\n",$ide_av_num,$wide_av;
printf $fh_hist "# normalised (0-1) weighted average  \t\t= %7.3f\n",$wnide_av;
printf $fh_hist "# metric for weighting %-s\n",$file_metric;
print $fh_hist "ide\tweighted normalised similarity\n";
foreach $it (1..($scale*100)){
    if (defined($hist_wnide{"$it"})){
	printf $fh_hist "%4.1f\t%8d\n",($it/$scale),$hist_wnide{"$it"};}
}
close($fh_hist);

&open_file("$fh_prof",">$file_prof_out");
print $fh_prof "# average over ",$#ide," points =$ide_av\n";
@aa=split(//,$string_aa);
print $fh_prof "AA=\t";
foreach $aa1 (@aa){ print $fh_prof "$aa1\t";} 
print $fh_prof "\n";
foreach $aa1 (@aa){ 
    print $fh_prof "$aa1\t";
    foreach $aa2 (@aa){print $fh_prof $profnum{"$aa1","$aa2"},"\t";}
    print $fh_prof "\n";
}
close($fh_prof);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
@file_out=($file_gr,$file_hist,$file_histw,$file_prof_out);
if ($Lscreen) { &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
		&myprt_empty; &myprt_txt(" output in files: "); 
		print"--- \t \t "; foreach$i(@file_out){print"$i,";} print "\n";
	    }
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir


#==============================================================================
sub equal_tolerance { 
    local($v1,$v2,$tol)=@_; 
#-------------------------------------------------------------------------------
#   equal_tolerance             returns 0, if v1==v2 +- $tol
#-------------------------------------------------------------------------------
    return(0) if ( $v1 < ($v2-$tol) || $v1 > ($v2+$tol) );
    return(1);
}				# end of equal_tolerance

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub metric_ini {
#--------------------------------------------------------------------------------
#   metric_ini                  initialise the metric reading ($string_aa returned=)
#--------------------------------------------------------------------------------
    $string_aa="VLIMFWYGAPSTCHRKQENDBZ";
    return $string_aa;
}				# end of metric_ini

#==============================================================================
sub metric_norm_minmax {
    local ($min_out,$max_out,$aa,%metric) = @_ ;
    local (@key,$key,$min,$max,$fac,$sub,$Lscreen,%metricnorm,$Lerr,$aa1,$aa2,@aa);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   metric_norm_minmax          converting profiles (min <0, max>0) to percentages (0,1)
#--------------------------------------------------------------------------------
    $Lscreen=0;
    @aa=split(//,$aa);
				# ------------------------------
				# figuring out current min/max
				# ------------------------------
    $min=$max=0;
    foreach $aa1(@aa){foreach $aa2(@aa){
	if    ($metric{"$aa1","$aa2"} < $min) { $min=$metric{"$aa1","$aa2"};}
	elsif ($metric{"$aa1","$aa2"} > $max) { $max=$metric{"$aa1","$aa2"};}
    }}
				# ------------------------------
				# normalising
				# x' = D*x - ( D*xmax - maxout ), D=(maxout-minout)/(xmax-xmin)
				# ------------------------------
    $fac= ($max_out-$min_out) / ($max-$min);
    $sub= ($fac*$max) - $max_out;
    if ($Lscreen) { print  "--- in get_metricnorm\t ";
		    printf "min=%5.2f, max=%5.2f, desired min_out=%5.2f, max_out=%5.2f\n",
		    $min,$max,$min_out,$max_out;
		    print  "--- normalise by: \t x' = f * x - ( f * xmax -max_out ) \n";
		    printf "--- where: \t \t fac=%5.2f, and (f*xmax-max_out)=%5.2f\n",$fac,$sub; }

    $min=$max=0;		# for error check
    foreach $aa1(@aa){foreach $aa2(@aa){
	$metricnorm{"$aa1","$aa2"}=($fac*$metric{"$aa1","$aa2"}) - $sub;
	if    ($metricnorm{"$aa1","$aa2"}<$min) {$min=$metricnorm{"$aa1","$aa2"};}
	elsif ($metricnorm{"$aa1","$aa2"}>$max) {$max=$metricnorm{"$aa1","$aa2"};}
    }}
				# --------------------------------------------------
				# error check
				# --------------------------------------------------
    $Lerr=0;
    if ( ! &equal_tolerance($min,$min_out,0.0001) ){$Lerr=1;
		     print"*** ERROR get_metricnorm: after min=$min, but desired is=$min_out,\n";}
    if ( ! &equal_tolerance($max,$max_out,0.0001) ){$Lerr=1;
		     print"*** ERROR get_metricnorm: after max=$max, but desired is=$max_out,\n";}
    if ($Lerr) {exit;}
    return %metricnorm;
}				# end of metric_norm_minmax

#==============================================================================
sub metric_rd {
    local ($file_metric) = @_ ;
    local (@tmp,$aa1,$aa2,$fhin,$tmp,$string_aa,@aa,%metric);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   metric_rd                   reads a Maxhom formatted sequence metric
#--------------------------------------------------------------------------------
    $fhin="FHIN_RD_METRIC";
    $string_aa=&metric_ini;
    if (-e $file_metric){
	&open_file("$fhin","$file_metric");
	while(<$fhin>){$tmp=$_;last if (/^AA /);}
				# ------------------------------
				# read acid symbol
	$tmp=~s/\n//g;
	$tmp=~s/^\s*|\s*$//g;	# deleting leading blanks
	$#tmp=0;@tmp=split(/\s+/);
	$#aa=0;
	foreach $it (4 .. $#tmp){
	    push(@aa,$tmp[$it]);
	}
	while(<$fhin>){
	    $_=~s/\n//g;
	    $_=~s/^\s*|\s*$//g;	# deleting leading blanks
	    $#tmp=0;@tmp=split(/\s+/);
	    foreach $it (1 .. $#aa){
		$metric{"$tmp[1]","$aa[$it]"}=$tmp[$it+1];
	    }
	}
	close($fhin);}
    else {
	print"*** ERROR in metric_rd (lib-br): '$file_metric' missing\n"; }
				# ------------------------------
				# identity metric
    if (0){
	@tmp=split(//,$string_aa);
	foreach $aa1 (@tmp){ foreach $aa2 (@tmp){ 
	    if ($aa1 eq $aa2){ $metric{"$aa1","$aa2"}=1;}
	    else {$metric{"$aa1","$aa2"}=0;}
	}}
    }
    return(%metric);
}				# end of metric_rd

#==============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

#==============================================================================
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

#==============================================================================
sub profile_count {
    local ($s1,$s2)=@_;
    local ($aa1,$aa2,$string_aa,@aa);
    $[=1;
#--------------------------------------------------------------------------------
#   profile_count               computes the profile for two sequences
#--------------------------------------------------------------------------------
				# initialise profile counts
    $string_aa=&metric_ini;
    @aa=split(//,$string_aa);
    foreach $aa1(@aa){ foreach $aa2(@aa){
	$profile{"$aa1","$aa2"}=0;
    }}
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);
	$aa2=substr($s2,$it,1);
	++$profile{"$aa1","$aa2"};
    }
    return(%profile);
}				# end of profile_count

#==============================================================================
sub seqide_compute {
    local ($s1,$s2) = @_ ;
    local ($ide,$len,$len2,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   seqide_compute              returns pairwise seq identity between 2 strings
#                               (identical length, if not only identity of the first N,
#                               where N is the length of the shorter string, returned)
#       in:                     string1,string2
#       out:                    identity,length
#--------------------------------------------------------------------------------
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;		# sum identity
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);$aa2=substr($s2,$it,1);
				# exclude insertions
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    if ($aa1 eq $aa2) {
		++$ide;}}
    }
    return($ide,$len2);
}				# end of seqide_compute

#==============================================================================
sub seqide_weighted {
    local ($s1,$s2,%metric)=@_;
    local ($aa1,$aa2,$ide,$it,$len,$len2);
    $[=1;
#--------------------------------------------------------------------------------
#   profile_count               computes the weighted similarity
#--------------------------------------------------------------------------------
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);
	$aa2=substr($s2,$it,1);
	next if (! defined $metric{"$aa1","$aa2"});
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    $ide+=$metric{"$aa1","$aa2"};}}
    return($ide,$len2);
}				# end of seqide_weighted



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
#==========================================================================================
sub ran_alis_ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "ran_alis";
    $script_input=  "ran_alis.pl file_hssp (or list of files) list_hssp (to align)";
    $script_goal=   "evaluates random alignments";
    $script_narg=   2;
    @script_goal=   (" ",
		     "Task: \t $script_goal",
		     " ",
		     "Input:\t $script_input",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=(
		     "out_id",
		     " ",
		     "not_screen",
		     "title_out=",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            (
		     "output files named x_id.pir,\n".
		     "--- \t \t with x: x.hssp, default: x_no.pir ",
		     " ",
		     "no information written onto screen",
		     "output file name",
		     "input dir name,   default: local",
		     "output dir names, default: local",
		     "working dir name, default: local",
		     );

    if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $script_name $script_input"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf"--- %-12s %-s\n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# directories
    $dir_in=    "";
    $dir_out=   "";
    $dir_work=  "";
				# --------------------
				# files
				# file extensions
				# file handles
    $fh_gr=     "FH_GR";
    $fh_hist=   "FH_HIST";
    $fh_prof=   "FH_PROF";
    $fhin=      "FHIN";
    $file_metric="/home/rost/pub/topits/Maxhom_Blosum.metric";
    $file_metric="/home/rost/pub/topits/Maxhom_McLachlan.metric";
				# --------------------
				# further
    $nrepeat=   "21";		# number of alignments made for one input sequence
    $scale=     1;		# scaling of histograms (10 means 0.1% 0.2% ..)

				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
				# --------------------
				# executables

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=   $ARGV[1];
    $list_in=   $ARGV[2];
				# output file
    $title_out= $file_in; $title_out=~s/\.hssp.*|\.list|\s//g;

    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if ( /not_screen/ ) {    $Lscreen=0; }
	    elsif ( /title_out=/ ) { $tmp=$ARGV[$it];$tmp=~s/\n|title_out=//g; 
				     $title_out=$tmp; }
	    elsif ( /dir_in=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
				     $dir_in=$tmp; }
	    elsif ( /dir_out=/ ) {   $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
				     $dir_out=$tmp; }
	    elsif ( /dir_work=/ ) {  $tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
				     $dir_work=$tmp; }
	}
    }
    $file_gr=      "Ran_mc_all_"."$title_out";
    $file_hist=    "Ran_mc_hist_"."$title_out";
    $file_histw=   "Ran_mc_histw_"."$title_out";
    $file_prof_out="Ran_mc_prof_"."$title_out";

    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$file_in; $file_in="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$file_gr; $file_gr="$dir_out"."$tmp";
			       $tmp=$file_hist; $file_hist="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; }

    if ($Lscreen) { &myprt_line; &myprt_txt("perl script that $script_goal"); 
		    &myprt_empty; &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("title_out: \t \t $title_out");
		    &myprt_txt("end of setting up,\t let's work on it"); 
		    &myprt_empty; &myprt_line; &myprt_empty; }

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");exit;}
}				# end of ran_alis_ini

#==========================================================================================
sub compare_seq {
    local ($seq1,@ali) = @_ ;
    local ($ide,$len,$it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    compare_seq                       
#         random alignment of two sequences
#       out: global (and in): %profnum
#--------------------------------------------------------------------------------
				# ------------------------------
				# random pick
    srand(sqrt(time*$repeat));	# seed
#    srand(1);			# seed
    $pos=int(rand($nali))+1;	# 1 <= pos <= nali
				# avoid identical comparisons
    if (substr($id2[$pos],2) eq substr($id1,2)) {++$pos;}
    $tmp=$ali[$pos];
    if (length($tmp)>50){	# random position
	$res=int(rand((length($tmp)-50))+1);} 
    else {$res=1;}
    $seq2=substr($tmp,$res);
    $seq1=substr($seq1,$repeat);
    ($ide,$len)=   &seqide_compute($seq1,$seq2);

				# ????????????????????????????????????????
				# beg zzz:  may be taken out ?
    %prof_loc=     &profile_count($seq1,$seq2);
				# add local (one protein) to global (all proteins)
    foreach $key (keys %prof_loc){
	$profnum{"$key"}+=$prof_loc{"$key"};
    }
				# end zzz: may be taken out ? 
				# ????????????????????????????????????????

				# weighted similarity
    ($wide,$len2)= &seqide_weighted($seq1,$seq2,%metric);
    ($wnide,$len2)=&seqide_weighted($seq1,$seq2,%metricnorm);
    return($ide,$len,$wide,$wnide);
}				# end of compare_seq

#==========================================================================================
sub hssp_rd_seq {
    local ($file_hssp) = @_ ;
    local ($fhin,$len1,$pos_guide_seq,$tmp,@tmp,$ctres,%rd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_rd_seq                       
#         reads the HSSP file and stores the alignments to be extracted
#       GLOBAL out:             @take (positions to be written)
#                               $rd{} 
#                               guide: "len1","nali","id1",("seq","ctres")
#                               alis:  ("id2","ctali"), ("seq","ctali","ctres")
#--------------------------------------------------------------------------------
				# settings
    $fhin="FHIN_HSSP";
				# 52 of the HSSP file
    $pos_guide_seq=15;		# position of guide sequence in HSSP file

				# ----------------------------------------
				# read file
    &open_file("$fhin","$file_hssp");
				# --------------------
				# header
    while (<$fhin>) { if(/^SEQLENGTH/){$_=~s/^SEQLENGTH|\s//g;$rd{"len1"}=$len1=$_;}
		      elsif(/^PDBID/){$_=~s/^PDBID|\s//g;$rd{"id1"}=$_;}
		      last if (/^\#\#/); }
				# --------------------
				# store list
    while (<$fhin>) { last if (/^\#\# ALIGN/); }
				# --------------------
				# now alis
    $ctres=0;
    while (<$fhin>) { 
	last if (/^\#\# SEQUENCE|^\#\# ALIGNMENTS/);
	if ( (!/^ SeqNo/) && (/^\s*\d+/) ) {
	    ++$ctres;
	    $rd{"seq","$ctres"}=substr($_,$pos_guide_seq,1);
	}
    }
    close($fhin);
    return %rd;
}				# end of hssp_rd_seq

#==========================================================================================
sub profile_ini {
    local ($string_aa)=@_;
    local (@tmp);
    $[=1;
#--------------------------------------------------------------------------------
#    profile_ini  initialises the keys for the profile 
#    note: global: %profile
#--------------------------------------------------------------------------------
    @tmp=split(//,$string_aa);
    foreach $aa1 (@tmp) {
	foreach $aa2 (@tmp) {
	    $profnum{"$aa1","$aa2"}=0;
	}}
}				# end of profile_ini

