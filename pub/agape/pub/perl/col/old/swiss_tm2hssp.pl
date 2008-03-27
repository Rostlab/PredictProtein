#!/usr/bin/perl -w
##!/usr/sbin/perl4 -w
#----------------------------------------------------------------------
# read_swiss
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	read_swiss.pl list-swiss-files (give swiss id, no list!)
#
# task:		reads seq. and e.g TM's from Swissprot and puts it into
#               HSSP file
#
#----------------------------------------------------------------------#
#	Burkhard Rost			August,	        1994           #
#			changed:	January	,      	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "read_swiss";
$script_goal      = "reads seq. and e.g TM's from Swissprot (in : swiss id, out HSSPTM)";
$script_input     = "list-swiss-files";
$script_opt_ar[1] = "2nd = executable";

#----------------------------------------
# about script
#----------------------------------------
&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
for ($it=1; $it<=$#script_opt_ar; ++$it) {
    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
} &myprt_empty; 
if ( ($ARGV[1]=~/help/) || ($ARGV[1]=~/help/) || ($#ARGV<1) ) { exit; }

#----------------------------------------
# read input
#----------------------------------------
&myprt_empty;
$file_in	= $ARGV[1]; 	&myprt_txt("file in: \t \t $file_in"); 

$opt_passed = "";
for ( $it=1; $it <= $#ARGV; ++$it ) { $opt_passed .= " " . "$ARGV[$it]"; }
&myprt_txt("options passed:"); &myprt_txt("      \t \t$opt_passed"); 
&myprt_empty; &myprt_line; &myprt_empty;

#------------------------------
# defaults
#------------------------------
$dir_hssp="";
$ext_hssp=".hssp"; $ext_hssptm=".hssptm";

#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); exit; }

#----------------------------------------
# read list
#----------------------------------------
$#file_in=0;
if (&is_swissprot($file_in)){
    push(@file_in,$file_in);}
else {
    &open_file("FILE_IN", "$file_in");
    while ( <FILE_IN> ) {
	$tmp=$_;$tmp=~s/\n//g;
	if (length($tmp)>0) {
	    push(@file_in,$tmp);}}
    close(FILE_IN);}

foreach $file_in(@file_in){
    if (! -e $file_in) {
	print "-*- MISSING Swiss-Prot: \t '$file_in'\n";
	next;}
    print "--- now reading Swiss-Prot: \t '$file_in'\n";
				# -----------------------------------------
				# now read swissprot (sequence and TM)
				# -----------------------------------------
    &read_swiss($file_in); 
    $tmp=$file_in;		# for security (old, i.e. before 01-96)
				# -----------------------------------------
				# now read / and write HSSP
				# -----------------------------------------
    $tmpfile=$dir_hssp.$SWISSID.$ext_hssp; $tmpfiletm=$dir_hssp.$SWISSID.$ext_hssptm; 
    print "--- now writing HSSP: \t '$tmpfiletm'\n";
    &write_tm2hssp($tmpfile,$tmpfiletm,$SEQ,$#TMBEG,@TMBEG,@TMEND);
}

&myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 

exit;




#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub is_swissprot {return(&isSwiss(@_));} # alias

#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open("$fhinLoc","$fileLoc"); $Lok=0;
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#===============================================================================
sub isSwissGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isSwissGeneral              checks (and finds) SWISS files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not swiss|isSwiss|isSwissList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:isSwissGeneral";$fhinLoc="FHIN"."$sbrName";
    return(1,"isSwiss",$fileInLoc) if (&isSwiss($fileInLoc)) ;  # file is swiss
				# ------------------------------
    if (&isSwissList($fileInLoc)) { # file is swiss list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;	    
			    next if (length($_)==0);
			    $tmp=$_;
			    if    ((-e $tmp) && &isSwiss($tmp))        { 
				push(@tmp,$tmp);}
			    else {		# search for valid SWISS file
				($file,$chain)=&swissGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &isSwiss($file))        { 
				    push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isSwissList",@tmp);}}
				# ------------------------------
    else {			# search for SWISS
	($file,$chain)=
	    &swissGetFile($fileInLoc,@dirLoc);
	return(1,"isSwiss",  $file) if ((-e $file) && &isSwiss($file));
	return(0,"not swiss",$fileInLoc);}
}				# end of isSwissGeneral

#===============================================================================
sub isSwissList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isSwissList                 checks whether or not file is list of Swiss files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_SwissList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (! -e $fileTmp){return(0);}
			if (&isSwiss($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isSwissList


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


#==========================================================================
sub read_swiss {
    local ($fin) = @_ ;
    $[ =1 ;

#--------------------------------------------------
#   reads and writes the sequence of HSSP + 70 alis
#--------------------------------------------------

    &open_file("FHTMP", "$fin");
    $SWISSID=$fin;$SWISSID=~s/.*\/(.*)/$1/g; print "x.x SWISSID:$SWISSID,\n";
    $#TMBEG=0;$#TMEND=0;$SEQ="";
    while(<FHTMP>) {
	if (/^FT   TRANSMEM/) {
	    $tmp1=substr($_,16,5);$tmp1=~s/\s//g;$tmp2=substr($_,23,5);$tmp2=~s/\s//g;
	    if ( (length($tmp1)*length($tmp2)) > 0 ) {
		push(@TMBEG,$tmp1);push(@TMEND,$tmp2);
	    }
	} elsif (/^     /) {
	    $tmp1=$_;$tmp1=~s/\s|\n//g;
	    $SEQ.=$tmp1;
	}
    }
    close(FHTMP);
    print "x.x SWISSID:$SWISSID\n";
    print "x.x tm  :\n";for($i=1;$i<=$#TMBEG;++$i) {print"$i:$TMBEG[$i] -$TMEND[$i]\n";}
    print "x.x seq :$SEQ\n";

}

#==========================================================================
sub write_tm2hssp {
    local ($finhssp,$finhssptm,$seq,$ntm,@tmbegend) = @_ ;
    $[ =1 ;

#--------------------------------------------------
#   reads and writes the sequence of HSSP + 70 alis
#--------------------------------------------------
    &open_file("FHTMPHSSP", "$finhssp"); &open_file("FHOUT", ">$finhssptm");
    
    $Lwrite=0;$ctres=0; $Lwriteprof=0;
    while(<FHTMPHSSP>) {
	if ( /^\#\# ALI/ )   { $Lwrite=0;$ctres=0;}
	elsif ( /^\#\# SEQ/ ){ $Lwrite=0;$Lwriteprof=1;}
	if ($Lwrite) {
	    ++$ctres;
	    $tmp=  substr($_,15,4); $tmpline=$_;
	    $tmpaa=substr($_,15,1); 
	    if ( $tmpaa ne substr($seq,$ctres,1) ) { 
		print "ERROR: for ctres=$ctres,aa=$tmpaa,\n*** however seq=$seq\n"; 
		exit; }
	    $Ltm=0;
	    for ($i=1;$i<=$ntm;++$i) {
		if ( ($ctres>=$tmbegend[$i])&&($ctres<=$tmbegend[$i+$ntm]) ) {
		    $i=$ntm+1; $Ltm=1;
		    $tmpsub=$tmpaa."  H"; } }
	    if ($Ltm) {$tmpline=~s/$tmp/$tmpsub/;}
	    $tmpline=~s/( [A-Z.]  )U /$1  /;
	    print FHOUT $tmpline;
	    print  $tmpline; }
	else {
	    print FHOUT $_;
#	    print "x.x",substr($_,1,20),"\n";
	}
	if ( (!$Lwriteprof)&&( /^ SeqNo/ ) ) { $Lwrite=1;}
    }
    close(FHTMPHSSP);close(FHOUT);
}
