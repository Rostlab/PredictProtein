#!/usr/bin/perl -w
##!/usr/sbin/perl4 -w
#----------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "hssp_extr_stripHeader";	# name of script
$scriptIn=     "file.strip (or list or *.strip)";		# input
$scriptTask=   "extracts information from HSSP.strip header";	# task
$scriptNarg=   1;		# minimal number of input arguments
#------------------------------------------------------------------------------#
#	Copyright				February,	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	February,	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

$Lok=&ini(@ARGV);		# initialise variables
if (! $Lok){ die; }

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
$Lok=&wrtRdbHeader($fhout,"\t",$fileOut);
if (!$Lok){print "*** ERROR\n";
	   die '$scriptName unnatural death';}

$ctAll=0;			# count through all hits
foreach $fileIn(@fileIn){
    $id=$fileIn;$id=~s/^.*\/\..*$|-.*$//g;$id=~s/[DFHdfh]ssp//g;$id=~s/[._!]//g;
    if ($Lscreen){ print "--- $scriptName \t $fileIn\n";}
				# IAL,VAL,LEN,IDEL,NDEL,ZSCORE,IDEN,
				# STRHOM,LEN2,RMS,NAME,LEN1
    %rd=
	&hsspRdStripHeader($fileIn,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde);
				# write output file
    &wrtRdbOneProt($fhout,"\t"," ",$id);
    &wrtRdbOneProt("STDOUT"," ","not_count",$id);
}
close($fhout);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_txt(" $scriptName has ended fine .. -:\)"); 
		&myprt_txt(" output in file: \t $fileOut"); }
exit;

#==========================================================================================
sub ini {
    local(@argv)=@_;
    local (@script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    @script_goal=   (" ",
		     "Task: \t $scriptTask",
		     " ",
		     "Input:\t $scriptIn",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scriptName help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("excl=n1-n2 ",
		     "incl=m1-m2 ",
		     "upIde= ",
		     "lowIde= ",
		     "minZ= ",
		     " ",
		     "not_screen",
		     "fileOut=");
    @script_opt_keydes= 
	            ("sequences n1 to n2 will be excluded: n1-*, n1-n2, or: n1,n5,... ",
		     "sequences m1 to m2 will be included: m1-*, m1-m2, or: m1,m5,... ",
		     "upper level of sequence identity ",
		     "lower level of sequence identity ",
		     "minimal zscore ",
		     " ",
		     "no information written onto screen",
		     "output file name");
    if ( ($argv[1]=~/^help|^man|-h/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $scriptName $scriptIn"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#argv < $scriptNarg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# file
    $fileOut=   "unk";
    $fhout=     "FHOUT";
    $fhin=      "FHIN";
				# --------------------
				# further
    $exclTxt=  "unk";		# n-m -> exclude positions n to m
    $inclTxt=  "unk";
    $minZ=     -100;		# minimal zscore
    $lowIde=   0;		# lower limit for percentage seq identity
    $upIde=    100;		# upper limit for percentage seq identity
				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
				# --------------------
    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $#fileIn=0;
    foreach $arg (@argv){
	if   ($arg=~/^excl=/ )    {$arg=~s/\n|^excl=//g;$arg=~s/\(|\)//g;$exclTxt=$arg;}
	elsif($arg=~/^incl=/ )    {$arg=~s/\n|^incl=//g;$arg=~s/\(|\)//g;$inclTxt=$arg;}
	elsif($arg=~/^lowIde=/ )  {$arg=~s/\n|^lowIde=//g;$lowIde=$arg;}
	elsif($arg=~/^upIde=/ )   {$arg=~s/\n|^upIde=//g;$upIde=$arg;}
	elsif($arg=~/^minZ=/ )    {$arg=~s/\n|^minZ=//g;$minZ=$arg;}
	elsif($arg=~/^not_screen/){$Lscreen=0; }
	elsif($arg=~/^fileOut=/ ) {$tmp=$arg;$tmp=~s/\n|^fileOut=//g; $fileOut=$tmp; }
	elsif(-e $arg){
	    if   (&is_strip($arg)){
		push(@fileIn,$arg);}
	    else {$tmp=$#fileIn;
		  $Lok=&open_file("$fhin","$arg");
		  if (!$Lok){ print "*** ERROR $sbrName open '$arg'\n";
			      return(0);}
		  while(<$fhin>){$_=~s/\s//g;$file=$_;if (length($_)<4){next;}
				 if (&is_strip($file)){
				     push(@fileIn,$file);}}close($fhin);
		  if ($#fileIn==$tmp){
		      print "*** ERROR $sbrName '$arg' was NOT a list!!\n";
		      return(0);}}}
	else {print "*** ERROR $sbrName '$arg' not recognised!\n";
	      return(0);}}
    if ($fileOut eq "unk"){
	$fileOut="Out-hsspStripHeader.tmp";}

    # ------------------------------------------------------------
    # settings onto screen
    # ------------------------------------------------------------
    if ($Lscreen) { &myprt_line; &myprt_txt("perl script that $scriptTask"); 
		    print "--- fileIn:    \t  \t ";
		    foreach $fileIn(@fileIn){print"$fileIn,";}print"\n";
		    print "--- fileOut:   \t  \t $fileOut";
		    if ($exclTxt!~/unk/) {&myprt_txt("exclude pos: \t $exclTxt"); }
		    if ($inclTxt!~/unk/) {&myprt_txt("include pos: \t $inclTxt"); }
		    printf "--- %-20s %-5.2f\n","minZ",$minZ;
		    printf "--- %-20s %-5.2f\n","lowIde",$lowIde;
		    printf "--- %-20s %-5.2f\n","upIde",$upIde;
		    &myprt_line; }
    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lok=1;
    foreach $fileIn(@fileIn){
	if (! -e $fileIn) { print "*** $scriptName no input=$fileIn,\n";$Lok=0;}}
    return($Lok);
}				# end of ini



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   converts range=n1-n2 into @range (1,2)
#       in:                     'n1-n2' NALL: e.g. incl=1-5,9,15 
#                               n1= begin, n2 = end, * for wild card
#                               NALL = number of last position
#       out:                    @takeLoc: begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    $#range=0;
    if (! defined $range_txt || length($range_txt)<1 || $range_txt eq "unk" 
	|| $range_txt !~/\d/ ) {
	print "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
	return(0);}
    $range_txt=~s/\s//g;	# purge blanks
    $nall=0                     if (! defined $nall);
				# already only a number
    return($range_txt)          if ($range_txt !~/[^0-9]/);
    
    if ($range_txt !~/[\-,]/) {	# no range given
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	return(0);}
				# ------------------------------
				# dissect commata
    if    ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
				# ------------------------------
				# dissect hyphens
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=&get_rangeHyphen($range_txt,$nall);}

				# ------------------------------
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    push(@range2,&get_rangeHyphen($range,$nall));}
	else {
            push(@range2,$range);}}
    @range=@range2; $#range2=0;
				# ------------------------------
    if ($#range>1){		# sort
	@range=sort {$a<=>$b} @range;}
    return (@range);
}				# end of get_range

#==============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     'n1-n2', NALL (n1= begin, n2 = end, * for wild card)
#                               NALL = number of last position
#       out:                    begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {push(@rangeLoc,$it);} }
    else { @rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#==============================================================================
sub hsspRdStripHeader {
    local($fileInLoc,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde,@kwdInStripLoc)=@_ ;
    local($sbrName,$fhinLoc,$Lok,$tmp,@excl,@incl,$nalign,$des,$kwd,$kwdRd,$info,
	  @kwdDefStripTopLoc,@kwdDefStripHdrLoc,%ptr,$posIde,$posZ,$ct,$i,
	  @kwdStripTopLoc,@kwdStripHdrLoc,%LtakeLoc,$rdBeg,$rdEnd,$Ltake);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#       in:                     fileStrip
#                               exclTxt="n1-n2", or "*-n2", or "n1,n3,...", or 'none|all'
#                               inclTxt="n1-n2", or "*-n2", or "n1,n3,...", or 'none|all'
#                               minimal Z-score; minimal and maximal seq ide
#         neutral:  'unk'       for all non-applicable variables!
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#                               $rd{"$des","$ct"} = column $des for pair no $ct
#                               $des=
#                                   IAL,VAL,LEN1,IDEL,NDEL,ZSCORE,IDE,STRHOM,LEN2,RMS,NAME
#                               -------------------------------
#                               ALTERNATIVE keywords for HEADER
#                               -------------------------------
#                               nali     -> alignments (number of alis)
#                               listName -> list name (alignment list)
#                               lastName -> last name was (last aligned id)
#                               sortMode -> sort-mode (ZSCORE/asf.)
#                               weight1  -> weights 1 (sequence weights for guide: (YES|NO))
#                               weight2  -> weights 2 (sequence weights for aligned: (YES|NO))
#                               smin     -> smin      (minimal value of scoring metric)
#                               smax     -> smax      (maximal value of scoring metric)
#                               gapOpen  -> gap_open  (gap open penalty)
#                               gapElon  -> gap_elongation  (gap elongation/extension penalty)
#                               indel1   -> INDEL in sec-struc of SEQ1 (YES|NO)
#                               indel2   -> INDEL in sec-struc of SEQ2 (YES|NO)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# defaults
    @kwdDefStripTopLoc=("test sequence","list name","last name was","seq_length",
			"alignments","sort-mode","weights 1","weights 1","smin","smax",
			"maplow","maphigh","epsilon","gamma",
			"gap_open","gap_elongation",
			"INDEL in sec-struc of SEQ 1","INDEL in sec-struc of SEQ 2",
			"NBEST alignments","secondary structure alignment");
    @kwdDefStripHdrLoc=("NR","VAL","LALI","IDEL","NDEL",
			"ZSCORE","IDE","STRHOM","LEN2","RMSD","SIGMA","NAME");
    $ptr{"IAL"}= 1;$ptr{"VAL"}= 2;$ptr{"LALI"}= 3;$ptr{"IDEL"}= 4;$ptr{"NDEL"}= 5;
    $ptr{"ZSCORE"}=6;$ptr{"IDE"}=7;$ptr{"STRHOM"}=8;
    $ptr{"LEN2"}=9;$ptr{"RMSD"}=10;$ptr{"SIGMA"}=11;$ptr{"NAME"}=12;
    $posIde=$ptr{"IDE"};$posZ=$ptr{"ZSCORE"};

    @kwdOutTop=("nali","listName","lastName","sortMode","weight1","weight2","smin","smax",
		"gapOpen","gapElon","indel1","indel2");

    %translateKwdStripTop=	# strip top
	('nali',"alignments",
	 'listName',"list name",'lastName',"last name was",'sortMode',"sort-mode",
	 'weight1',"weights 1",'weight2',"weights 2",'smin',"smin",'smax',"smax",
	 'gapOpen',"gap_open",'gapElon',"gap_elongation",
	 'indel1',"INDEL in sec-struc of SEQ 1",'indel2',"INDEL in sec-struc of SEQ 2");
	 
				# ------------------------------
				# check input arguments
    undef %addDes;
    $#kwdStripTopLoc=$#kwdStripHdrLoc=0;
    foreach $kwd (@kwdInStripLoc){
	$Lok=0;
	foreach $des (@kwdDefStripHdrLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdStripHdrLoc,$kwd);
			       last;}}
	next if ($Lok);
	foreach $des (@kwdDefStripTopLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdStripTopLoc,$kwd);
			       foreach $desOut(@kwdOutTop){
				   if ($kwd eq $translateKwdStripTop{"$desOut"}){
				       $addDes{"$des"}=$desOut;
				       last;}}
			       last;} }
	next if ($Lok);
	if (defined $translateKwdStripTop{"$kwd"}){
	    $addDes=$translateKwdStripTop{"$kwd"};
	    $Lok=1; push(@kwdStripTopLoc,$addDes);
	    $addDes{"$addDes"}=$kwd;}
	next if ($Lok);
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" 
	    if (! $Lok);}
    undef %LtakeLoc;		# logicals to decide what to read
    foreach $kwd (@kwdStripTopLoc){
	$LtakeLoc{$kwd}=1;}	# 
				# force reading of NALI
    if (! defined $LtakeLoc{"alignments"}){push(@kwdStripTopLoc,"alignments");
					   $LtakeLoc{"alignments"}=1;}

    $#excl=$#incl=0;		# set zero
				# --------------------------------------------------
				# now start to read
				# open file
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
				# --------------------------------------------------
				# file type:
				# '==========  MAXHOM-STRIP  ==========='
    $_=<$fhinLoc>;		# first line
    if ($_!~/^[= ]+MAXHOM-STRIP[= ]+/){ # file recognised?
	print "*** ERROR ($sbrName) not maxhom.STRIP file! (?)\n";
	return(0);}
    undef %tmp;		# save space
				# --------------------------------------------------
    while (<$fhinLoc>) {	# read file TOP (global info)
				# stop if next key:
				# '============= SUMMARY ==============='
	last if ($_ =~/^[= ]+SUMMARY[= ]+/);
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
	next if ($_ !~ /\:/);	# skip if ':' missing (=> error!)
	($kwdRd,$info)=split(/:/,$_);
	if ($kwdRd=~/seq_length/){
	    $len1=$info;$len1=~s/\D//g;}
	$kwdRd=~s/\s*$//g;	# purge blanks at end
	if ($LtakeLoc{$kwdRd}){	# want the info?
	    $info=~s/^\s*|\s*$//g;
	    $tmp{"$kwdRd"}=$info;
				# add short names for header
	    if (defined $addDes{"$kwdRd"}){
		$kwdRdAdd=$addDes{"$kwdRd"};
		$tmp{"$kwdRdAdd"}=$info;}
	    next;}}
    $nalign=$tmp{"alignments"};
				# ------------------------------
				# get range to be in/excluded
    if ($inclTxt ne "unk"){ @incl=&get_range($inclTxt,$nalign);} 
    if ($exclTxt ne "unk"){ @excl=&get_range($exclTxt,$nalign);} 
    $ct=0;			# --------------------------------------------------
    while (<$fhinLoc>) {	# read PAIR information
				# '=========== ALIGNMENTS =============='
	last if ($_ =~ /^[= ]+ALIGNMENTS[= ]+/);
	next if ($_ =~ /^\s*IAL\s+VAL/); # skip line with names
	$_=~s/\n//g; 
	next if (length($_)<5);	# another format error if occurring

	$rdBeg=substr($_,1,69);$rdBeg=~s/^\s*|\s*$//g;
	$rdEnd=substr($_,70);  $rdEnd=~s/^\s*|\s*$//g;
	$rdEnd=~s/(\s)\s*/$1/g; # 2 blank to 2

	@tmp=(split(/\s+/,$rdBeg),"$rdEnd");

	$pos=$tmp[1];		# ------------------------------
	$Ltake=1;		# exclude pair because of RANK?
	if ($#excl>0){foreach $i (@excl){if ($i eq $pos){$Ltake=0;
							 last;}}}
	if (($#incl>0)&&$Ltake){ 
	    $Ltake=0; foreach $i (@incl){if ($i eq $pos){$Ltake=1; 
							 last;}}}
	next if (! $Ltake);	# exclude
				# exclude because of identity?
	next if ((( $upIde ne "unk") && (100*$tmp[$posIde]>$upIde))||
		 (($lowIde ne "unk") && (100*$tmp[$posIde]<$lowIde)));
				# exclude because of zscore?
	next if ((  $minZ  ne "unk") && ($tmp[$posZ]<$minZ));

	++$ct;
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
# IAL    VAL   LEN IDEL NDEL  ZSCORE   %IDEN  STRHOM  LEN2   RMS SIGMA NAME

	$tmp{"LEN1","$ct"}=$len1;
	foreach $kwd (@kwdStripHdrLoc){
	    $pos=$ptr{"$kwd"};
	    if (($pos>$#tmp)||($pos<1)){
		print "*** ERROR in $sbrName ct=$ct, kwd=$kwd, pos should be $pos\n";
		print "***          however \@tmp not defined for that\n";
		return(0);}
	    if ($kwd eq "IDE"){$tmp=100*$tmp[$pos];}else{$tmp=$tmp[$pos];}
	    $tmp{"$kwd","$ct"}=$tmp;}
    } close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    undef @kwdInLoc;undef @kwdDefStripTopLoc;undef @kwdDefStripHdrLoc;undef %ptr; 
    undef @kwdStripTopLoc; undef @kwdStripHdrLoc; undef %LtakeLoc;
    
    return (%tmp);
}				# end of hsspRdStripHeader

#==============================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_STRIP";
    open($fh, $fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1 if ($_=~/===  MAXHOM-STRIP  ===/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_strip

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
# library collected (end)   lll
#==============================================================================


1;


#==========================================================================================
sub hsspRdStripHeader {
    local($fileInLoc,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde)=@_ ;
    local($fhinLoc,$Lok,$tmp,@excl,@incl,$nalign);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#       in:                     fileStrip
#                               exclTxt="n1-n2", or "*-n2", or "n1,n3,..."
#                               inclTxt="n1-n2", or "*-n2", or "n1,n3,..."
#                               minimal Z-score; minimal and maximal seq ide
#       out:
#                               $rd{"NROWS"}     = number of rows
#                               $rd{"$des","$ct"} = column $des for pair no $ct
#                               $des=
#                                   IAL,VAL,LEN,IDEL,NDEL,ZSCORE,IDEN,STRHOM,LEN2,RMS,NAME
#--------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
				# open file
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    $#excl=$#incl=0;		# set zero
				# ------------------------------
				# read file
    while (<$fhinLoc>) {	# get Nali
	$tmp=$_;
	last if (/^\s*alignments\s+/);
	if (/^\s*seq_lengt/){$tmp=~s/^\s*seq_len.*:\s+//g;$tmp=~s/[^0-9]//g;$len1=$tmp;}}
    $tmp=~s/^.*:\s+//g;$tmp=~s/[^0-9]//g;$nalign=$tmp;
				# get range to be in/excluded
    if ($inclTxt!~/unk/){ @incl=&get_range($inclTxt,$nalign);} 
    if ($exclTxt!~/unk/){ @excl=&get_range($exclTxt,$nalign);} 
				# ------------------------------
				# read file
    while (<$fhinLoc>) {	# skip before SUMMARY
	last if (/=== SUMMARY ===/); }
    $ct=0;
    while (<$fhinLoc>) {	# 
	last if (/=== ALIGNMENTS ===/);
	$_=~s/\n//g;               if (length($_)<5){next;}
	$rd=$_;
	if (/^\s*IAL\s+/){	# first line: names
	    $rdBeg=substr($rd,1,69);$rdBeg=~s/^\s*|\s*$//g;
	    @name=(split(/\s+/,$rdBeg),"NAME");foreach $name(@name){$name=~s/\%//g;}
	    foreach $it (1..$#name){if   ($name[$it] eq "IDEN")  {$posIde=$it;}
				    elsif($name[$it] eq "ZSCORE"){$posZ=$it;}}
	    next;}
	$rdBeg=substr($rd,1,69);$rdBeg=~s/^\s*|\s*$//g;
	$rdEnd=substr($rd,70);  $rdEnd=~s/^\s*|\s*$//g;
	$rdEnd=~s/^([^\s]+)\s.*$/$1/g; # take only PDBid
	@tmp=(split(/\s+/,$rdBeg),$rdEnd);
	$pos=$tmp[1];
	$Ltake=1;
	if ($#excl>0) {foreach $i (@excl){ if ($i eq $pos){$Ltake=0; 
							   last;}}}
	if (($#incl>0) && $Ltake) { 
	    $Ltake=0;foreach $i (@incl){ if ($i eq $pos) {$Ltake=1; 
							  last;}}}
	if (! $Ltake) {		# dont continue if range to be excluded
	    next; }
	if ((100*$tmp[$posIde]>$upIde)||(100*$tmp[$posIde]<$lowIde)){
	    next; }
	if ($tmp[$posZ]<$minZ){
	    next;}
	++$ct;
	$rdLoc{"LEN1","$ct"}=$len1;
	foreach $it (1..$#tmp){
	    if ($name[$it] eq "IDEN"){$tmp=100*$tmp[$it];}else{$tmp=$tmp[$it];}
	    $rdLoc{"$name[$it]","$ct"}=$tmp; }}close($fhinLoc);
    $rdLoc{"NROWS"}=$ct;
    return (%rdLoc);
}				# end of hsspRdStripHeader

#===============================================================================
sub wrtRdbHeader {
    local($fhoutLoc,$sep,$fileOutLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHeader                writes RDB header
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtRdbHeader";$fhinLoc="FHIN"."$sbrName";

    if ($fhoutLoc ne "STDOUT"){
	$Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileOutLoc' not opened\n";
		    return(0);}}
    print $fhoutLoc "# Perl-RDB\n";
    print $fhoutLoc "# \n";
    print $fhoutLoc "# Extracted Strip header\n";
    print $fhoutLoc "# \n";
    printf $fhoutLoc 
	"%6s$sep%6s$sep%-10s$sep%-10s$sep%6s$sep%6s$sep%4s$sep%5s$sep%5s$sep%5s\n",
	"ct",   "pos", "id1",   "id2",   "valAli","zAli","ide","len1","len2","lali";
    printf $fhoutLoc 
	"%6s$sep%6s$sep%-10s$sep%-10s$sep%6s$sep%6s$sep%4s$sep%5s$sep%5s$sep%5s\n",
	"6N",   "6N",  "10",    "10",    "6.2F",  "6.2F","4N","5N","5N","5N";
}				# end of wrtRdbHeader

#===============================================================================
sub wrtRdbOneProt {
    local($fhoutLoc,$sep,$txtCount,$idLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbOneProt               writes the RDB data for one protein
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtRdbOneProt";$fhinLoc="FHIN"."$sbrName";

    foreach $it (1..$rd{"NROWS"}){
	if ($txtCount ne "not_count"){++$ctAll;}

	printf $fhoutLoc 
	    "%6d$sep%6d$sep%-10s$sep%-10s$sep%6s$sep%6s$sep%4s$sep%5s$sep%5s$sep%5s\n",
	    $ctAll,$rd{"IAL","$it"},"$idLoc",$rd{"NAME","$it"},
	    $rd{"VAL","$it"},$rd{"ZSCORE","$it"},int($rd{"IDEN","$it"}),
	    $rd{"LEN1","$it"},$rd{"LEN2","$it"},$rd{"LEN","$it"};
    }
}				# end of wrtRdbOneProt

