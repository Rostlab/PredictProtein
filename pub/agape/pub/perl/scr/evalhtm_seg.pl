#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="in: list of PHDhtm RDB files, out: segment accuracy\n".
    "     \t \n".
    "     \t ";
#  
# 
#----------------------------------------------------------------------
# evalhtm_seg
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	evalhtm_seg.pl list(.rdb_phd) files from PHD
#
# task:		in: list of PHDhtm RDB files, out: segment accuracy
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost			September,      1995           #
#			changed:	January	,      	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=         0;
$Lverb=          0;
$Lscreen=        0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName phd.rdb (or list)'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";

    printf "%5s %-15s=%-20s %-s\n","","title", "x",          "add to column names";

    printf "%5s %-15s %-20s %-s\n","","htm",   "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","sec",   "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","acc",   "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","both",  "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","nof",   "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","fil",   "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","ref2",  "no value",   "";
    printf "%5s %-15s %-20s %-s\n","","ref",   "no value",   "";

    printf "%5s %-15s %-20s %-s\n","","c11",   "no value",   "also compile segment overlap center prd obs within 11 res (ikeda)";
    printf "%5s %-15s %-20s %-s\n","","9",     "no value",   "also compile segment overlap 9 residues";

#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
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
$fhin="FHIN"; 
#$fhout="FHOUT";
$fh=             "FHOUT";
$fh2=            "FHOUT_DET";
$LisList=        0;
$#fileIn=        0;

$fileOut= "unk";
$opt_phd=  "unk";
$opt=      "unk";
$title=    "";

				# segment counted as correct if:
$par{"LsegC11"}=   0;		#  - ABS(center(obs)-center(prd))<= 11 residues
$par{"Lseg9"}=     0;		#  - pred and obs overlap 9 residues
$par{"Lseg3"}=     1;		#  - pred and obs overlap 3 residues
$par{"noverlap3"}= 3;		# number of residues required to overlap for score '3'
$par{"noverlap9"}= 9;		# number of residues required to overlap for score '9'

$par{"LsegC11"}= 1;		#  - ABS(center(obs)-center(prd))<= 11 residues
$par{"Lseg9"}=   1;		#  - pred and obs overlap 9 residues

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;
					    $Lscreen=        1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;
					    $Lscreen=        0;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;
					    $Lscreen=        0;}
    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}
    elsif ($arg=~/^title=(.*)$/)          { $title=          $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    elsif ($arg=~/^htm/)                  { $opt_phd=        "htm";}
    elsif ($arg=~/^sec/)                  { $opt_phd=        "sec";}
    elsif ($arg=~/^acc/)                  { $opt_phd=        "acc";}
    elsif ($arg=~/^both/)                 { $opt_phd=        "both";}
    elsif ($arg=~/^nof/)                  { $opt=            "nof";}
    elsif ($arg=~/^fil/)                  { $opt=            "fil";}
    elsif ($arg=~/^ref2/)                 { $opt=            "ref2";}
    elsif ($arg=~/^ref/)                  { $opt=            "ref";}

    elsif ($arg=~/^c11$/i)                { $par{"LsegC11"}= 1;}
    elsif ($arg=~/^9$/)                   { $par{"Lseg9"}=   1;}

    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

if ($Ldebug){ $Lverb=$Lscreen=1;}
if ($Lverb) { $Lscreen=1;}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

#------------------------------
# defaults
#------------------------------
if    ($fileOut eq "unk" && $fileIn[1] =~ /list$/) {
    $tmp=$fileIn[1];$tmp=~s/\.list$//;
    $fileOut="Seg-".$tmp . ".dat";
    $fileOut_det="Segdet-".$tmp . ".dat";}
elsif ($fileOut eq "unk" && $fileIn[1] !~ /list$/) {
    $fileOut="Seg-htm.dat";
    $fileOut_det="Segdet-htm.dat";}
else {
    $fileOut_det=$fileOut;
    if ($fileOut=~/_ana/){
	$fileOut_det=~s/_ana$/_det/;}
    else {
	$fileOut_det=$fileOut."_det";}}

@des_rd= ("AA","OHL","PHL","RI_S","RI_H","PRHL","PR2HL");

@des_out=("AA","OHL","PRHL","RI_S");
#@des_out=("AA","OHL","PRHL","RI_S");
#@des_out=("AA","OHL","P2RHL","RI_S");

if    ($opt eq "fil")    { @des_out=("AA","OHL","PFHL","RI_S");}
elsif ($opt eq "nof")    { @des_out=("AA","OHL","PHL","RI_S");
			   @des_rd= ("AA","OHL","PHL","RI_S");}

elsif ($opt eq "ref")    { @des_out=("AA","OHL","PRHL","RI_S");}
elsif ($opt eq "ref2")   { @des_out=("AA","OHL","PR2HL","RI_S");}
else                     { @des_out=("AA","OHL","PHL","RI_S");}

if    ($opt_phd eq "htm" && 
       $opt eq "ref")    { @des_out=("AA","OHL","PHL","RI_H");
			   @des_rd= ("AA","OHL","PHL","PRHL","RI_H","RI_S"); }
elsif ($opt_phd eq "htm"){ @des_out=("AA","OHL","PHL","RI_H");
			   @des_rd= ("AA","OHL","PHL","RI_H","RI_S");}

@des_res_reference=("Nok","Nobs","Nphd","NPok","NPoks","RiRef","RiRefD");

#@des_res=("Nok","Nobs","Nphd","NPok","NPoks","RiRef","RiRefD");

@des_res=("Nok","Nobs","Nphd","NPok","NPoks",
	  "Nok9","NPok9",
	  "NokC11","NPokC11"
	  );
foreach $kwd (@des_res){
    $des_wrtWant{$kwd}=1;
}
foreach $kwd (@des_rd){
    $des_rdWant{$kwd}=1;
}


$symh=           "H";		# symbol for HTM
$des_obs=        $des_out[2];
$des_prd=        $des_out[3];

$des_Nok=        $des_res[1];	# key for number of correctly predicted
$des_Nobs=       $des_res[2];	# key for number of observed helices
$des_Nphd=       $des_res[3];	# key for number of predicted helices
$des_Nphd2=      "Nphd2";	# key for number of predicted helices for 2nd best model

$des_NPok=       $des_res[4];	# key for number of proteins correctly predicted
				#     correct number of helices(100%)
				#     note: overlap >3 residues

$des_NPoks=      $des_res[5];	# key for number of proteins correctly predicted
				# if more HTM are allowed to be predicted in end
				#     note: overlap >3 residues

$des_Nok9=       $des_res[6];	# key for number correct (overlap 9)
$des_NPok9=      $des_res[7];	# key for percentage of proteins with correct helix (overlap 9)
#$des_NPoks9=     $des_res[8];	# key for percentage of proteins with correct number wrong succession

$des_NokC11=     $des_res[8];	# key for number correct (overlap centers >=11, ikeda)
$des_NPokC11=    $des_res[9];	# key for percentage of proteins with correct helix (overlap center)
#$des_NPoksC11=   $des_res[11];	# key for percentage of proteins with correct number wrong succession


				# correct number of helices(100%)
$des_riref=      $des_res_reference[6];	# key for reliability of refinement model (zscore)
$des_rirefD=     $des_res_reference[7];	# key for reliability of refinement model (best-snd)

$opt_phd="htm"
    if ($opt_phd eq "unk");	# security
$des_prd=        "PRHL"
    if ($opt=~/ref/);    

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
    $par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in


				# --------------------------------------------------
				# loop over all files
				# --------------------------------------------------
$ctfile=$#id=$#ri=$#riD=$#nphd2=0;
foreach $fileIn (@fileIn) {
    %rd=
	&rd_rdb_associative($fileIn,"header","NHTM_2ND_BEST","REL_BEST","REL_BEST_DIFF",
			    "body",@des_rd);

				# ------------------------------
    if ($rd{"NROWS"}<5) {	# skip short ones
	next; }
				# ------------------------------
				# correct if missing
    if (defined $des_rdWant{"PRHL"} && $des_rdWant{"PRHL"}){
	foreach $it (1..$rd{"NROWS"}){
	    $rd{"PRHL",$it}=$rd{"PHL",$it} if (! defined $rd{"PRHL",$it});
	}
    }
				# RI_H
    if (defined $des_rdWant{"RI_H"} && $des_rdWant{"RI_H"}){
	foreach $it (1..$rd{"NROWS"}){
	    if    (! defined $rd{"RI_H",$it} && defined $rd{"RI_S",$it}){
		$rd{"RI_H",$it}=$rd{"RI_S",$it};}
	    elsif (! defined $rd{"RI_S",$it} && defined $rd{"RI_H",$it}){
		$rd{"RI_S",$it}=$rd{"RI_H",$it};}
	}
    }

    ++$ctfile;
    $id=$fileIn;$id=~s/^.*\/([^\.]*)\..*/$1/;$id=~s/\.rdb_.*$//g;
    $id=~s/\..*$//g;
    push(@id,$id);
    if ($opt=~/ref/ && defined $rd{"REL_BEST"}){
	$rel_best=$rd{"REL_BEST"};
	$rel_best=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$rel_best=~s/\s|\n//g;
	$rel_bestD=$rd{"REL_BEST_DIFF"};
	$rel_bestD=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$rel_bestD=~s/\s|\n//g;
	$nphd2=$rd{"NHTM_2ND_BEST"};$nphd2=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$nphd2=~s/\s|\n//g;
	push(@ri,$rel_best); push(@riD,$rel_bestD); push(@nphd2,$nphd2); }
    $all{$id,"NROWS"}=$rd{"NROWS"};
				# check RI
    if (! defined $rd{"RI_S",1}){
	foreach $itres (1..$rd{"NROWS"}){
	    $rd{"RI_S",$itres}=$rd{"RI_H",$itres};
	}}
    if (! defined $rd{"RI_H",1}){
	foreach $itres (1..$rd{"NROWS"}){
	    $rd{"RI_H",$itres}=$rd{"RI_S",$itres};
	}}

    foreach $des (@des_rd){
	$all{$id,$des}="";
	foreach $itres (1..$rd{"NROWS"}){
	    if ($des=~/RI/ && ! defined $rd{$des,$itres}){
		print "-*- missing des=$des !\n"
		    if ($itres==1);
		next;}
	    if (! defined $rd{$des,$itres}){
		print "*** file=$fileIn, des=$des, itres=$itres, missing rd()!\n";
		die;}
	    $all{$id,$des}.=$rd{$des,$itres}; 
	}
				# convert L->" "
	if ($des=~/O.*L|P.*L/){
            if ($opt_phd eq "htm") {
                $all{$id,$des}=~s/E/ /g;}
	    $all{$id,$des}=~s/L/ /g;} 
    }
}
				# --------------------------------------------------
				# analyse segment accuracy
				# --------------------------------------------------
$idvec=join("\t",@id);

%res=
    &anal_seg($idvec,$symh,$des_obs,$des_prd,
	      $des_Nok,$des_NPok,$des_NPoks,$des_Nobs,$des_Nphd,%all);
				# add ri
if ($opt=~/ref/ && defined $des_wrtWant{"RiRef"} && $des_wrtWant{"RiRef"}){
    foreach $it (1..$#id) {$res{$id[$it],$des_riref}=$ri[$it];}
    foreach $it (1..$#id) {$res{$id[$it],$des_rirefD}=$riD[$it];}
    foreach $it (1..$#id) {$res{$id[$it],$des_Nphd2}=$nphd2[$it];}}
				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
$desvec=join("\t",@des_res);
$idvec= join("\t",@id);

&wrt_res("STDOUT",$opt,$idvec,$desvec,%res)
    if ($Lverb);
open($fh, ">".$fileOut) || warn("*** evalhtm_seg: failed to open out=$fileOut\n");
&wrt_res($fh,$opt,$idvec,$desvec,%res);
close($fh);


print "--- evalhtm_seg output in file=$fileOut\n" if ($Lscreen);
    
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


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
    open($fhinLoc,$fileInLoc) ||
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
	      else { 
		  print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";
	      }
	  }
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#==============================================================================
sub get_secstr_segment_caps {
    local ($string,@des) = @_ ;
    local ($des,$it,@beg,@end,%segment);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#       out:                    $segment{"H","beg",1}= first residue in first helix
#                               $segment{"H","end",1}= last residue in first helix
#--------------------------------------------------------------------------------
				# convert vector to array (begin and end different)
    @aa=("#",split(//,$string),"#");

    foreach $des (@des) {
	$#beg=$#end=0;		# loop over all residues
	foreach $it ( 2 .. $#aa ){ # note 1st and last ="#"
	    if   ( ($aa[$it] ne $des) && ($aa[$it-1] eq $des) ){
		push(@end,($it-2)); }
	    elsif( ($aa[$it] eq $des) && ($aa[$it-1] ne $des) ){
		push(@beg,($it-1)); }  }
	if ($#end != $#beg) {	# consistency check!
	    print "*** get_secstr_segment_caps: des=$des, Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){	# store segment begins (Ncap) and ends (Ccap)
	    $segment{$des,"beg",$it}=$beg[$it];
	    $segment{$des,"end",$it}=$end[$it]; } 
	$segment{$des,"NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#==============================================================================
sub is_rdbf {
    local ($fileIn) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileIn) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$fileIn");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

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
sub rd_rdb_associative {
    local ($fileIn,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rd_rdb_associative          reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#                       ALL:    'head,body'
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#                       HEADER: rdrdb{"header"}
#                       NAMES:  rdrdb{"names"} 
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=0                  if (! defined $Lscreen);
    $Lscreen=0                  if (! $Ldebug);

				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$Lhead_all=$Lbody_all=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; $Lbody_all=1;}
	elsif($Lhead)                        {push(@des_headin,$des_in); $Lhead_all=0;}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;; $Lbody_all=0;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n"
		if ($Lscreen);}
    }
    if ($Lscreen) { 
	print "--- $sbr_name: header \t ";
	foreach $it (@des_headin){print"$it,";}print"\n"; 
	print "--- $sbr_name: body   \t ";
	foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$fileIn");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{$des_in}){
			$rdrdb{$des_in}.="\t".$tmp;}
		    else {
			$rdrdb{$des_in}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;} }
	    if(! $Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$fileIn'\n";
	    }
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read

    $#des_body=0;
    if (! $Lbody_all){
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for ($it=1;$it<=$#READNAME;++$it) {
		$rd=$READNAME[$it];
		if ($rd eq $des_in) {
		    $ptr_rd2des{$des_in}=$it;
		    push(@des_body,$des_in);
		    $Lfound=1;
		    last;} }
	    if (! $Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$fileIn'\n";
	    }
	}
    }
    else {
	foreach $it(1..$#READNAME){
	    $name=$READNAME[$it];$ptr_rd2des{"$name"}=$it;
	    push(@des_body,$name);}}

				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{$des_in};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{$des_in,"format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{$des_in,"format"}="8";}
    }

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{$des_in};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if    ($nrow_rd==0){
	    $nrow_rd=$#tmp;
	}
	elsif ($nrow_rd!=$#tmp){
	    if ($Lscreen){
		print "*** WARNING $sbr_name: different number of rows\n";
		print "*** WARNING in RDB file '$fileIn' for rows with ".
		    "key= $des_in and previous column no=$itrd,\n";
	    }
	}
	$names.=$des_in.",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{$des_in,$it}=$tmp[$it];
	}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   read_rdb_num2               reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {$READHEADER.= "$_"; # header  
		      next;}
	++$ct;			# rest
	if ( $ct >= 3 ) {	              # col content
	    @tmpar=split(/\t/);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ct==1 ) {	      # col name
	    $_=~s/\t$//g;@tmpar=split(/\t/);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
	elsif ( $ct==2 ) {	      # col format
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;}}
	    else {		# no format given, read line
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}}}
    }
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (! defined $READFORMAT[$it] && $Lscreen){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";
	}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
#==========================================================================================
sub anal_seg {
    local ($idvec,$symh,$des_obs,$des_prd,
	   $des_Nok,$des_NPok,$des_NPoks,$des_Nobs,$des_Nphd,%all) = @_ ;
    local ($fhx,@des,@id,$tmp,@tmp,$id,$it,@fh);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_seg                writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
				# default settings (global overwrites)
    $par{"Lseg9"}= 0            if (! defined $par{"Lseg9"});
    $par{"LsegC11"}=0           if (! defined $par{"LsegC11"});
    $par{"Lseg3"}= 1            if (! defined $par{"Lseg3"});
    $par{"noverlap3"}=3         if (! defined $par{"noverlap3"});
    $par{"noverlap9"}=9         if (! defined $par{"noverlap9"});

				# vector to array
    @id=split(/\t/,$idvec);
    $ctprot_ok=   $ctprot_oksucc=   $ctres_ok=   $ctres_obs=   $ctres_phd=   0;
    $ctprot_ok9=  $ctres_ok9=  0;
    $ctprot_okC11=$ctres_okC11=0;
#    $ctprot_oksuccC11=$ctprot_oksucc9=0;

    $#fh=0;
    push(@fh,$fh2);
    push(@fh,"STDOUT") if ($Lscreen);
    
    open($fh2, ">".$fileOut_det) || 
	warn "*** $scrName:anal_seg: failed writing fh=$fh2, file=$fileOut_det\n";

    foreach $fhx (@fh) {
	printf $fhx
	    "%-15s %-3s %-3s-%-3s %-3s %-3s-%-3s\n",
	    "id","obs","beg","end","phd","beg","end";
    }
    foreach $it (1..$#id){
	$id=$id[$it];
				# note: $x{$symh,"beg",$it}
	die "*** anal_seg: not defined symh=$symh or id=$id, (it=$it)\n"
	    if (! defined $symh || ! defined $id);
	die "*** anal_seg: not defined all=".$all{$id,$des_obs}.
	    "| des_obs=$des_obs, symh=$symh or id=$id, (it=$it)\n"
		if ( ! defined $des_obs || ! defined $all{$id,$des_obs});
	die "*** anal_seg: not defined all=".$all{$id,$des_prd}.
	    "| des_prd=$des_prd, symh=$symh or id=$id, (it=$it)\n"
		if ( ! defined $des_prd || ! defined $all{$id,$des_prd});

				# note: will generate output of the form
				#   %obs{"H","NROWS"}= number of helices
				#   %obs{"H","beg|end",$ct}= begin|end of helix $ct 
				#                      in terms of residue number

	%obs= &get_secstr_segment_caps($all{$id,$des_obs},$symh);
	%phd= &get_secstr_segment_caps($all{$id,$des_prd},$symh);
	if (0){
	    print "yy $id obs=",$all{$id,$des_obs},"\n";
	    print "yy $id prd=",$all{$id,$des_prd},"\n";
	}

	$ctres_obs+=$obs{$symh,"NROWS"};
	$ctres_phd+=$phd{$symh,"NROWS"};
	foreach $fhx (@fh) {
	    printf $fhx
		"%-15s %-3d %-3s-%-3s %-3d %-3s-%-3s\n",
		$id,$obs{$symh,"NROWS"}," "," ",$phd{$symh,"NROWS"}," ","";}

				# --------------------------------------------------
				# yy: very very stupid, change!!!
				# get overlap between segments
	undef %tmpoverlap;
	foreach $ctobs (1..$obs{$symh,"NROWS"}) {
	    $tmpoverlap{$ctobs,"maxval"}=0;
	    foreach $ctprd (1..$prd{$symh,"NROWS"}) {
				# begin
		if ($obs{$symh,"beg",$ctobs}>$prd{$symh,"beg",$ctprd}){
		    $beg=$obs{$symh,"beg",$ctobs};}
		else {
		    $beg=$prd{$symh,"beg",$ctprd};}
				# end
		if ($obs{$symh,"end",$ctobs}<$prd{$symh,"end",$ctprd}){
		    $end=$obs{$symh,"end",$ctobs};}
		else {
		    $end=$prd{$symh,"end",$ctprd};}
		$tmpoverlap{$ctobs,$ctprd}=1+$end-$beg;
		if ($tmpoverlap{$ctobs,$ctprd} < 0){
		    $tmpoverlap{$ctobs,$ctprd}=0;
		    next;
		}
		if ($tmpoverlap{$ctobs,$ctprd} > $tmpoverlap{$ctobs,"maxval"}){
		    $tmpoverlap{$ctobs,"maxpos"}=$ctprd;
		    $tmpoverlap{$ctobs,"maxval"}=$tmpoverlap{$ctobs,$ctprd};
		}
		printf 
		    "xx o %5d p %5d over=%5d max=%5d\n",$ctobs,$ctprd,
		    $tmpoverlap{$ctobs,$ctprd},$tmpoverlap{$ctobs,"maxval"};
	    }
	}


				# ini to avoid counting segments twice
	foreach $it(1..$phd{$symh,"NROWS"}){
	    $Lok[$it]=1;}

	$ctok3=$ctsucc3=$ctok9=$ctsucc9=$ctokC11=$ctsuccC11=0;
	
	foreach $ctobs (1..$obs{$symh,"NROWS"}) {
	    foreach $ctprd (1..$phd{$symh,"NROWS"}) {
				# no overlap beg pred > end observed
		last if ($phd{$symh,"beg",$ctprd}>$obs{$symh,"end",$ctobs});
				# no overlap end pred < beg observed
		next if ($phd{$symh,"end",$ctprd}<$obs{$symh,"beg",$ctobs});
				# skip if already counted
		next if (! $Lok[$ctprd]);
				# first time saying: this IS an overlap
		($Lok,$msg,$Lok3,$Lok9,$LokC11)=
		    &assGetOverlap($obs{$symh,"beg",$ctobs},$obs{$symh,"end",$ctobs},
				   $phd{$symh,"beg",$ctprd},$phd{$symh,"end",$ctprd},
				   $tmpoverlap{$ctobs,$ctprd});
		if (! $Lok){
		    print 
			"*** ERROR $scrName:anal_seg:assGetOverlap\n",
			"    ctobs=$ctobs, ctprd=$ctprd, symh=$symh, msg=\n",
			$msg,"\n";
		    exit;
		}
				# overlap at least 3 residues
		if ($par{"Lseg3"} && $Lok3){
		    $fst_prd=$ctprd if (! $ctok3);
		    ++$ctok3;
				# succ=number correct, wrong place
		    ++$ctsucc3 if ($ctobs==$ctprd || ($ctprd-$fst_prd+1)==$ctobs);}

				# overlap at least 9 residues
		if ($par{"Lseg9"} && $Lok9){
		    $fst_prd9=$ctprd if (! $ctok9);
		    ++$ctok9;
				# succ=number correct, wrong place
		    ++$ctsucc9 if ($ctobs==$ctprd || ($ctprd-$fst_prd9+1)==$ctobs);}

				# overlap of centers at least 11 residues
		if ($par{"LsegC11"} && $LokC11){
		    $fst_prdC11=$ctprd if (! $ctokC11);
		    ++$ctokC11;
				# succ=number correct, wrong place
		    ++$ctsuccC11 if ($ctobs==$ctprd || ($ctprd-$fst_prdC11+1)==$ctobs);}

		foreach $fhx (@fh) {
		    printf $fhx
			"%-15s %-3d %-3d-%-3d %-3d %-3d-%-3d\n"," ",
			$ctobs,$obs{$symh,"beg",$ctobs},$obs{$symh,"end",$ctobs},
			$ctprd,$phd{$symh,"beg",$ctprd},$phd{$symh,"end",$ctprd};
		}
		$Lok[$ctprd]=0;
		last;
	    }
	}
	$res{$id,$des_Nok}=    $ctok3;
	$res{$id,$des_Nok9}=   $ctok9    if ($par{"Lseg9"});
	$res{$id,$des_NokC11}= $ctokC11  if ($par{"LsegC11"});
	$res{$id,$des_Nobs}=   $obs{$symh,"NROWS"};
	$res{$id,$des_Nphd}=   $phd{$symh,"NROWS"};
	$res{$id,$des_NPok}=   0;
	$res{$id,$des_NPoks}=  0;
	$res{$id,$des_NPok9}=  0;
	$res{$id,$des_NPokC11}=0;
	$ctres_ok+=   $ctok3;
	$ctres_ok9+=  $ctok9   if ($par{"Lseg9"});
	$ctres_okC11+=$ctokC11 if ($par{"LsegC11"});
				# fully correct
	if ($obs{$symh,"NROWS"}==$phd{$symh,"NROWS"}){
	    if ($par{"Lseg3"} && $obs{$symh,"NROWS"}==$ctok3){
		$res{$id,$des_NPok}=100;
		++$ctprot_ok; }
	    if ($par{"Lseg9"} && $obs{$symh,"NROWS"}==$ctok9){
		$res{$id,$des_NPok9}=100;
		++$ctprot_ok9; }
	    if ($par{"LsegC11"} && $obs{$symh,"NROWS"}==$ctok3){
		$res{$id,$des_NPokC11}=100;
		++$ctprot_okC11; }
	}
				# correct number wrong succession
	if ($par{"Lseg3"}   && $obs{$symh,"NROWS"}==$ctsucc3){
	    $res{$id,$des_NPoks}=100;
	    ++$ctprot_oksucc;}
#	if ($par{"Lseg9"}   && $obs{$symh,"NROWS"}==$ctsucc9){
#	    $res{$id,$des_NPoks9}=100;
#	    ++$ctprot_oksucc9;}
#	if ($par{"LsegC11"} && $obs{$symh,"NROWS"}==$ctsuccC11){
#	    $res{$id,$des_NPoksC11}=100;
#	    ++$ctprot_oksuccC11;}
	    
    }


    close($fh2);		# close file to write out details

    $res{"NROWS"}=    $#id;
    if ($par{"Lseg3"}){
	$res{$des_NPok}=    $ctprot_ok;
	$res{$des_NPoks}=   $ctprot_oksucc;
	$res{$des_Nobs}=    $ctres_obs;
	$res{$des_Nphd}=    $ctres_phd;
	$res{$des_Nok}=     $ctres_ok;
    }
    if ($par{"Lseg9"}){
	$res{$des_NPok9}=   $ctprot_ok9;
#	$res{$des_NPoks9}=  $ctprot_oksucc9;
	$res{$des_Nok9}=    $ctres_ok9;
    }
    if ($par{"LsegC11"}){
	$res{$des_NPokC11}= $ctprot_okC11;
#	$res{$des_NPoksC11}=$ctprot_oksuccC11;
	$res{$des_NokC11}=  $ctres_okC11;
    }
    
    return(%res);
}				# end of anal_seg

#===============================================================================
sub assGetOverlap {
    local($obsbegLoc,$obsendLoc,$prdbegLoc,$prdendLoc,$overlapLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assGetOverlap               do the predicted and observed segments overlap
#                               or not? 
#                               returns various answers, overlap at least
#                               - 3 residues
#                               - 9 residues
#                               - centers of predicted and observed differ less than 11
#       in GLOBAL:              $par{"LsegC11"}:1=compile center11 overlap (ikeda)
#       in GLOBAL:              $par{"Lseg9"}:  1=compile 9 residue overlap (moeller)
#                               default: only 3 residue overlap
#       in:                     $obsbeg|end     first and last residue in given observed HTM
#       in:                     $prdbeg|end     first and last residue in given predicted HTM
#       in:                     $overlapLoc  overlap between predicted and observed HTM
#                               
#       out:                    1|0,msg,$Lok3(1|0),$Lok9(1|0),$LokC11  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."assGetOverlap";
				# check arguments
    return(&errSbr("not def obsbegLoc!"))          if (! defined $obsbegLoc);
    return(&errSbr("not def obsendLoc!"))          if (! defined $obsendLoc);
    return(&errSbr("not def prdbegLoc!"))          if (! defined $prdbegLoc);
    return(&errSbr("not def prdendLoc!"))          if (! defined $prdendLoc);
    return(&errSbr("not def overlapLoc!"))         if (! defined $overlapLoc);

#    print "xx overlap obsbeg=$obsbeg, end=$obsend, prdbeg=$prdbeg end=$prdend\n";

				# default settings (global overwrites)
    $par{"Lseg9"}=    0         if (! defined $par{"Lseg9"});
    $par{"LsegC11"}=  0         if (! defined $par{"LsegC11"});
    $par{"Lseg3"}=    1         if (! defined $par{"Lseg3"});
    $par{"noverlap3"}=3         if (! defined $par{"noverlap3"});
    $par{"noverlap9"}=9         if (! defined $par{"noverlap9"});

				# overlap at least 3?
    $Lok3=$Lok9=$LokC11=0;
    if    ($par{"Lseg9"} && ($overlapLoc >=$par{"noverlap9"})){
#	   (($prdbegLoc >= $obsbegLoc && $prdbegLoc <= ($obsendLoc-$par{"noverlap9"}+1)) ||
#	    ($prdendLoc <= $obsendLoc && $prdendLoc >= ($obsbegLoc+$par{"noverlap9"}-1)) ) ){

	$Lok3=1;
	$Lok9=1;
    }
    elsif ($par{"Lseg3"} && ($overlapLoc >=$par{"noverlap3"})){
#	   (($prdbegLoc >= $obsbegLoc && $prdbegLoc <= ($obsendLoc-$par{"noverlap3"}+1))||
#	    ($prdendLoc <= $obsendLoc && $prdendLoc >= ($obsbegLoc+$par{"noverlap3"}-1)))){
	
	$Lok3=1;
    }
				# compile center overlap
    if ($par{"LsegC11"}){
	$center_obs=$obsbegLoc+int(0.5*(1+$obsendLoc-$obsbegLoc));
	$center_prd=$prdbegLoc+int(0.5*(1+$prdendLoc-$prdbegLoc));
	$LokC11=1
	    if (( $center_prd >= $center_obs && ($center_prd-$center_obs)<=11 ) ||
		( $center_prd <= $center_obs && ($center_obs-$center_prd)<=11 ));
    }
    return(1,"ok $sbrName",$Lok3,$Lok9,$LokC11);
}				# end of assGetOverlap

#==========================================================================================
sub wrt_res {
    local ($fh,$opt,$idvec,$desvec,%res) = @_ ;
    local (@des,@id,$tmp,$tmpqobs,$tmpqphd,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res                writes into file readable by EVALSEC
#
#    note: 
#                           des(1)=Nok,des(2)=Nobs,des(3)=Nphd,des(4)=NPok,des(5)=NPoks,
#                           des(6)=RiRef,des(7)=RiRef
#--------------------------------------------------------------------------------
				# vector to array
    @des=split(/\t/,$desvec);
    @id=split(/\t/,$idvec);
    foreach $_ (@des){
	if ($_=~/prot.*ok/){
	    $des_NPok=$_;
	    last;
	}
    }
				# ------------------------------
				# header
    if ($res{"NROWS"}>0){
	$tmp= $res{$des_NPok}/$res{"NROWS"};
	$tmps=$res{$des_NPoks}/$res{"NROWS"}; 
    }
    else{
	$tmp=$tmps=0;
    }
    
    print  $fh "# final averages";
    print  $fh " $title "        if (length($title));
    print  $fh ": \n";

				# DATA
    printf $fh "# Nok    :%6s,%4d   (N seg correct)  \n",    " ",        $res{$des[1]};
    printf $fh "# Nobs   :%6s,%4d   (N seg observed) \n",    " ",        $res{$des[2]};
    printf $fh "# Nprd   :%6s,%4d   (N seg predicted)\n",    " ",        $res{$des[3]};
    printf $fh "# Nprot  :%6s,%4d   (N proteins)     \n",    " ",        $res{"NROWS"};
    if ($par{"Lseg3"}){		# overlap 3
	printf $fh "# NPok   :%6.1f,%4d   (P correct)\n",        100*($tmp), $res{$des[4]};
	printf $fh "# NPoks  :%6.1f,%4d   (P corr succession)\n",100*($tmps),$res{$des[5]};
    }
				# overlap 9
    if ($par{"Lseg9"}){
	printf $fh "# Nok9   :%6s,%4d   (N seg correct)  \n", " ",        $res{$des_Nok9};
	printf $fh "# NPok9  :%6.1f,%4d   (P correct)\n",     100*($tmp), $res{$des_NPok9};
    }
				# overlap center 11
    if ($par{"LsegC11"}){
	printf $fh "# NokC11 :%6s,%4d   (N seg correct)  \n", " ",        $res{$des_NokC11};
	printf $fh "# NPokC11:%6.1f,%4d   (P correct)\n",     100*($tmp), $res{$des_NPokC11};
    }

    print  $fh "# \n";

    
    printf $fh "# NOTATION: NPok       number of proteins with Nhtm pred=obs=ok (overlap 3)\n";
    printf $fh "# NOTATION: NPok(id)=  100 or 0 (overlap 3)\n";
    if ($par{"Lseg3"}){
	printf $fh 
	    "# NOTATION: NPok       number of proteins with Nhtm pred=obs=ok (overlap 3)\n",
	    "# NOTATION: NPok(id)=  100 or 0 (overlap 3)\n",
	    "# NOTATION: NPoks      at least 'core' same number, i.e., succession ok\n";
    }
    if ($par{"Lseg9"}){
	printf $fh 
	    "# NOTATION: NPok9      number of proteins with Nhtm pred=obs=ok (overlap 9)\n",
	    "# NOTATION: NPok9(id)= 100 or 0 (overlap 9)\n";
    }
    if ($par{"LsegC11"}){
	printf $fh 
	    "# NOTATION: NPokC11    number of proteins with Nhtm pred=obs=ok (centers <=11)\n",
	    "# NOTATION: NPokC11_id=100 or 0 (overlap centers <=11)\n";
    }

    if ($opt=~/ref/ && defined $des_wrtWant{"RiRef"} && $des_wrtWant{"RiRef"}){
	printf $fh "# NOTATION: RiRef      reliability of refinement model (zscore)\n";
	printf $fh "# NOTATION: RiRefD     reliability of refinement model (best-snd/len)\n";
    }
    printf $fh "# NOTATION: \n";
    printf $fh "#  \n";

				# add title?
    $tmpadd_title= "";
    $tmpadd_title.="_".$title         if (length($title)>0);

				# names
    printf $fh 
	"%-20s\t","id".$tmpadd_title;

    foreach $it ( 1 .. ($#des) ){
	printf $fh 
	    "%4s\t",$des[$it].$tmpadd_title;
    }
    if ($opt=~/ref/ && defined $des_wrtWant{"RiRef"} && $des_wrtWant{"RiRef"}){
	printf $fh 
	    "%4s\t",$des_Nphd2.$tmpadd_title;
	foreach $it( ($#des-1) .. $#des ){
	    printf $fh 
		"%4s\t",$des[$it].$tmpadd_title;
	} 
    }
    else {			# add the percentages
	foreach $it( ($#des-1) .. $#des ){
	    printf $fh 
		"%4s\t",$des[$it].$tmpadd_title;
	} 
    }
				# finally force adding 
    printf $fh 
	"%5s\t%5s\n",
	"Qobs".$tmpadd_title,"Qphd".$tmpadd_title;
				# ------------------------------
				# all proteins
    $qobs=$qphd=$riref=$rirefD=$Nphd2=0;
    foreach $it (1..$#id) {
	$id=$id[$it];
	printf $fh 
	    "%-20s\t",$id;
	foreach $des (@des){
	    if ($des=~/^N/){
		printf $fh "%4d\t",$res{$id,$des};
	    }
	}

	if (0){
	    if ($opt=~/ref/ && defined $des_wrtWant{"RiRef"} && $des_wrtWant{"RiRef"}){
		$tmp1=$res{$id,$des[$#des-1]};
		$tmp2=$res{$id,$des[$#des]};
		$tmp3=$res{$id,$des_Nphd2};
	    }
	    else{
		$tmp1=$tmp2=$tmp3=0;
	    }
	    if ($opt=~/ref/ && defined $des_wrtWant{"RiRef"} && $des_wrtWant{"RiRef"}){
		printf $fh 
		    "%4d\t%5.2f\t%5.3f\t",
		    $res{$id,$des_Nphd2},$res{$id,$des[$#des-1]},$res{$id,$des[$#des]};
	    }
	    else {
		printf $fh 
		    "%5.1f\t%5.1f\t",
		    $res{$id,$des[$#des-1]},$res{$id,$des[$#des]};
	    }
	    if (defined $des_wrtWant{"RiRef"} && $des_wrtWant{"RiRef"}){
		$riref+=$tmp1;$rirefD+=$tmp2;$Nphd2+=$tmp3;
	    }
	}

	$tmpqphd=$tmpqobs=0;
	$tmpqobs=100*($res{$id,$des[1]}/$res{$id,$des[2]})
	    if ($res{$id,$des[2]}>0);
	    
	$tmpqphd=100*($res{$id,$des[1]}/$res{$id,$des[3]})
	    if ($res{$id,$des[3]}>0);

				# sum
	$qobs+=$tmpqobs;
	$qphd+=$tmpqphd;
	printf $fh 
	    "%5.1f\t%5.1f\n",$tmpqobs,$tmpqphd;
    }
				# ------------------------------
				# recompile the bloddy sums
    foreach $kwd ("NPok","NPoks",
		  "NPok9","NPokC11"
		  ){
	$res{$kwd}=0;
    }
    foreach $id (@id) {
	foreach $kwd ("NPok","NPoks",
		      "NPok9","NPokC11"
		      ){
	    next if (! defined $res{$id,$kwd});
	    $res{$kwd}+=$res{$id,$kwd};
	}
    }
				# ------------------------------
				# write sums
    $tmp= "sum";
    $tmp.="(".$title.")"        if (length($title)>0);
    $tmp.="=".$#id;
    printf $fh 
	"%-20s\t",$tmp;
    foreach $des (@des){
	if ($des=~/^No/||$des=~/Nphd/){
	    printf $fh 
		"%4d\t",$res{$des};
	}
	elsif ($opt=~/ref/ && 
	       $des=~/$des_wrtWant{"RiRef"}/){
	    printf $fh 
		"%4d\t",$res{$des};
	    $tmp1=($riref/$#id);
	    $tmp2=($rirefD/$#id);
	    $tmp3=($Nphd2/$#id);
	    printf $fh 
		"%4d\t%5.2f\t%5.3f\t",int(100*$tmp3),$tmp1,$tmp2; 
	}
	elsif ($des=~/^NP/){
	    printf $fh
		"%5.1f\t",$res{$des}/$#id;
	}
    }

    printf $fh 
	"%5.1f\t%5.1f\n",($qobs/$#id),($qphd/$#id);
}				# end of wrt_res

