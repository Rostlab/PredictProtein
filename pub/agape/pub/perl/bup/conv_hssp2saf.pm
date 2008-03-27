#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

package conv_hssp2saf;

INIT: {
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
    $scrGoal="converts HSSP 2 SAF\n";
}

#===============================================================================
sub conv_hssp2saf {
#-------------------------------------------------------------------------------
#   conv_hssp2saf                   package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0



    @ARGV=@_;			# pass from calling


				# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   {$dir=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }
				# ------------------------------
				# include libraries
    $dir=$1 || "/home/rost/pub/phd/scr/" || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
    $dir.="/" if (-d $dir && $dir !~/\/$/);
    $dir= ""  if (! defined $dir || ! -d $dir);
    foreach $lib ("lib-ut.pl","lib-br.pl"){
	require $dir.$lib || 
	    die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
				# ------------------------------
    &convHssp2saf("ini");	# sets %par

				# ------------------------------
    if ($#ARGV<1){		# help
	print  "goal:\t $scrGoal\n";
	print  "use: \t '$scrName list.hssp (or *.hssp)'\n";
	print  "opt: \t \n";
	printf "     \t %-15s= %-20s %-s\n","fileOut",  "x","";
	printf "     \t %-15s= %-20s %-s\n","extr",     "p1-p2,p3","(extract proteins p1-p2,p3 only)";
	printf "     \t %-15s= %-20s %-s\n","frag",     "n1-n2",   "(extract residues n1-n2 only)";
	printf "     \t %-15s  %-20s %-s\n","noScreen", "no value","";
	printf "     \t %-15s  %-20s %-s\n","expand",   "no value","(do expand the insertion list)";
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

    ($Lok,$msg)=
	&convHssp2saf(@ARGV);

    print "*** $scrName: final msg=\n".$msg."\n" if (! $Lok);

    return(1,"ok $scrName:pack");
}				# end of conv_hssp2saf


#===============================================================================
sub convHssp2saf {
    local($tmpMode) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convHssp2saf                script to convert HSSP 2 SAF
#       in:                     file.hssp (or list, or *.hssp)
#                               file.hssp_C   for chain!
#       in:                     opt fileOut=X     -> output file will be X
#                                                    NOTE: only for single file!
#       in:                     opt frag=n1-n2    -> extract residues n1-n2
#       in:                     opt extr=p1-p2,p3 -> extract proteins p1-p2,p3
#       in:                     opt expand        -> write expanded ali
#       in:                     opt noScreen      -> avoid writing
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp:lib-scr::"."convHssp2saf";$fhinLoc="FHIN_"."convHssp2saf";
				# ------------------------------
				# defaults
    @rdHsspHdr=("SEQLENGTH","ID","IDE","LALI","IFIR","ILAS");

    $par{"len1Min"}=      30 if (! defined $par{"len1Min"}); # minimal length
    $par{"laliMin"}=      30 if (! defined $par{"laliMin"}); # minimal alignment length
    $par{"pideMax"}=     100 if (! defined $par{"pideMax"}); # maximal percentage sequence identity
    $par{"expand"}=        0 if (! defined $par{"expand"} ); # expand insertions?
    $par{"verbose"}=       1 if (! defined $par{"verbose"}); # 
    $par{"verb2"}=         0 if (! defined $par{"verb2"}  ); # 
    @kwd=sort (keys %par);

    return if (defined $tmpMode && $tmpMode eq "ini");

				# initialise variables
    $fhin="FHIN";
				# ------------------------------
    $#fileIn=$#chainIn=0;	# read command line
    foreach $arg (@_){
	if    ($arg=~/^fileOut=(.*)$/)          { $fileOut=$1;}
	elsif ($arg=~/^frag=(.*)$/)             { $frag=$1; 
						  if ($frag !~/\d+\-\d+/){
						      print "*** arg 'frag' must be 'N1-N2'\n";
						      exit;}}
	elsif ($arg=~/^extr=(.*)$/)             { $extr=$1; }
	elsif ($arg=~/^no[Ss]creen/)            { $par{"verbose"}=$par{"verb2"}=0; }
	elsif ($arg=~/^expand$/)                { $par{"expand"}=1; }
	elsif ($arg=~/^debug$/)                 { $par{"debug"}=1; }
#	elsif ($arg=~/^=(.*)$/) { $=$1; }
	elsif (-e $arg)                         { push(@fileIn,$arg); push(@chainIn,"*");}
	elsif ($arg=~/^(.*\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
	elsif (defined %par && $#kwd>0)         { 
	    $Lok=0; 
	    foreach $kwd (@kwd){
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last;}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 die;}}
	else { print "*** wrong command line arg '$arg'\n"; 
	       die;}}
				# ------------------------------
				# verify 'extr' correct
    if (defined $extr && length($extr)>=1 && $extr=~/\d/ && $extr ne "0"){
	@extr=&get_range($extr);
	return(&errSbr("you gave the argument 'extr=$extr', not valid!\n***   Ought to be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")) if ($#extr==0);
	foreach $tmp (@extr) {
	    if ($tmp=~/\D/){ 
		return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
			       "***   Ought to be of the form:\n".
			       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")); }
	    $extr{"$tmp"}=1; }}
    elsif (defined $extr) {undef $extr ; }
				# ------------------------------
				# input file
    $fileIn=$fileIn[1];
    die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# (0) read list (if list)
    if (! &is_hssp($fileIn)){	# ------------------------------
	print "--- $scrName: read list '$fileIn'\n";
	$#fileIn=$#chainIn=0;
	$fhin="FHIN_$scrName";
	&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {
	    $_=~s/\n|\s//g;
	    next if (length($_)<5);
	    if ($_=~/^(.*\.hssp)\_([A-Z0-9])/){
		push(@fileIn,$1); push(@chainIn,$2);}
	    else {
		push(@fileIn,$_); push(@chainIn,"*");} 
	} close($fhin); $#fileOut=0; } else { @fileOut=($fileOut) if (defined $fileOut);
					      $#fileOut=0         if (! defined $fileOut); }
				# ------------------------------
				# (1) loop over file(s)
				# ------------------------------
    foreach $itfile(1..$#fileIn){
	($Lok,$msg)=
	    &convHssp2saf_hsspRdLoc;
	return(&errSbrMsg("failed reading file=$fileIn[$itfile], it=$itfile",$msg)) 
	    if (! $Lok);
    }
    if ($par{"verbose"}) { $tmp="";
			   foreach $file (@fileOut) { 
			       next if (! -e $file);
			       $tmp.="$file,";}
			   $tmp=~s/,*$//g;
			   if    (length($tmp)>2 && $tmp=~/,/){
			       print "--- output files:"; }
			   elsif (length($tmp)>2){
			       print "--- output file:"; }
			   print "$tmp\n";}

			       
    return(1,"ok $sbrName");
}				# end of convHssp2saf

#===============================================================================
sub convHssp2saf_hsspRdLoc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convHssp2saf_hsspRdLoc      reads stuff
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-scr::"."convHssp2saf_hsspRdLoc";
    $fhinLoc="FHIN_"."convHssp2saf_hsspRdLoc";

    $fileIn=$fileIn[$itfile]; $chainIn=$chainIn[$itfile];
    if (! -e $fileIn){ 
	print "-*- WARN $scrName: no fileIn=$fileIn\n";
	next;}
    print "--- $scrName: working on $itfile =$fileIn $chainIn\n" if ($par{"verbose"});
    $pdbid= $fileIn;$pdbid=~s/^.*\/|\.hssp//g; 
    $pdbid.="_".$chainIn        if ($chainIn ne "*");
    undef %tmp;			# ------------------------------
    if ($chainIn ne "*"){	# get chain positions
        ($Lok,%tmp)= 
	    &hsspGetChain($fileIn);
                                return(&errSbr("failed on getchain($fileIn)")) if (! $Lok);
	foreach $it (1..$tmp{"NROWS"}){
	    next if ($chainIn ne $tmp{"$it","chain"});
	    $ifir=$tmp{"$it","ifir"}; $ilas=$tmp{"$it","ilas"}; }}
    else {
	$ifir=$ilas=0;}
				# ------------------------------
    undef %tmp;			# read header of HSSP
    ($Lok,%tmp)=
	&hsspRdHeader($fileIn,@rdHsspHdr);
                                return(&errSbr("failed on $fileIn")) if (! $Lok);
                                # ------------------------------
                                # too short -> skip
    return(1,"too short=".$tmp{"SEQLENGTH"})  if ($tmp{"SEQLENGTH"} < $par{"len1Min"});

    $#numTake=0;		# ------------------------------
				# process data
    foreach $it (1..$tmp{"NROWS"}){
                                                            # not chain -> skip
	next if ($ifir && $ilas && ( ($tmp{"IFIR","$it"} > $ilas) || ($tmp{"ILAS","$it"} < $ifir) ));
	next if ($par{"laliMin"} > $tmp{"LALI","$it"} );    # lali too short
	next if ($par{"pideMax"} < 100*$tmp{"IDE","$it"} ); # pide too high
	next if (defined $extr && ! defined $extr{"$it"} ); # select only some proteins
        push(@numTake,$it);     # ok -> take
    }
                                # ------------------------------
    undef %tmp;			# read alignments
    if (defined $par{"expand"} && $par{"expand"}){
	$kwdSeq="seqAli";}	# read ali with insertions
    else {
	$kwdSeq="seqNoins";}	# read ali without insertions
	
    ($Lok,%tmp)=
	&hsspRdAli($fileIn,@numTake,$kwdSeq);
                                return(&errSbrMsg("failed reading alis for $fileIn, num=".
						  join(',',@numTake),$msg)) if (! $Lok);

    $nali=$tmp{"NROWS"};
    undef %tmp2;

				# ------------------------------
    if (defined $frag){		# adjust for extraction (arg: frag=N1-n2)
        ($ibeg,$iend)=split(/\-/,$frag); 
				# additional complication if expand: change numbers
	if ($kwdSeq eq "seqAli"){ $seq=$tmp{"$kwdSeq","0"};
				  @tmp=split(//,$seq); $ct=0;
				  foreach $it (1..$#tmp){
				      next if ($tmp[$it] eq ".");  # skip insertions
				      ++$ct;                       # count no-insertions
				      next if ($ct > $iend);       # outside of range to read
				      next if ($ct < $ibeg);       # outside of range to read
				      $ibeg=$it if ($ct == $ibeg); # change begin
				      $iend=$it if ($ct == $iend);}}} # change end
    else {
	$ibeg=$iend=0;}
				# ----------------------------------------
				# cut out non-chain, and not to read parts
				# ----------------------------------------
    foreach $it (0..$nali){
	if ($ifir && $ilas){
	    $tmp{"$kwdSeq","$it"}=substr($tmp{"$kwdSeq","$it"},$ifir,($ilas-$ifir+1));}
	if ($ibeg && $iend){
	    $tmp{"$kwdSeq","$it"}=substr($tmp{"$kwdSeq","$it"},$ibeg,($iend-$ibeg+1));}
	$ct=$it+1;
	$tmp2{"seq","$ct"}=$tmp{"$kwdSeq","$it"};
	undef  $tmp{"$kwdSeq","$it"};
	$tmp2{"id","$ct"}= $tmp{"$it"};}
    $tmp2{"NROWS"}=$nali+1;
    undef %tmp;			# slick-is-in!
				# ------------------------------
    undef %tmp;			# slick-is-in !
    undef @numTake;		# slick-is-in !
				# ------------------------------
				# write output file
    if (defined $fileOut && $#fileIn==1){
	$fileOutLoc=$fileOut;}
    else {
	$fileOutLoc="$pdbid".".saf"; 
	$fileOut.=$fileOutLoc."," if (defined $fileOut); }

    ($Lok,$msg)=
	&safWrt($fileOutLoc,%tmp2);
    return(&errSbrMsg("failed writing out=$fileOutLoc, for in=$fileIn",$msg)) if (! $Lok);

    push(@fileOut,$fileOutLoc);

    undef %tmp2;		# slick-is-in !

    return(1,"ok $sbrName");
}				# end of convHssp2saf_hsspRdLoc

1;
