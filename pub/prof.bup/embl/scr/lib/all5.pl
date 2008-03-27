#!/usr/bin/perl
##! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				June,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.4   	May,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with perl 5 specific routines (all kinds of stuff).          #
#    - blast | coils | fasta | maxhom | prodom | seg                           #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   all5                        internal subroutines:
#                               ---------------------
# 
#   blastGetSummary_5           BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#   blastRdHdr_5                reads header of BLASTP output file
#   blastWrtSummary_5           writes summary for blast results (%ide,len,distance HSSP)
#   fileColumnGenRd_5           general reader for column formats
#   rdRdbAssociative_5          reads content of an RDB file into associative array
#   rdRdbAssociativeNum_5       reads from a file of Michael RDB format:
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   all5                        external subroutines:
#                               ---------------------
# 
#   call from all5:             blastRdHdr_5,rdRdbAssociativeNum_5
# 
#   call from file:             open_file,rdbGenWrtHdr
# 
#   call from prot:             getDistanceNewCurveIde
# 
#   call from scr:              errSbr,errSbrMsg
# 
# -----------------------------------------------------------------------------# 
# 

#===============================================================================
sub blastGetSummary_5 {
    my($fileInLoc,$minLaliLoc,$minDistLoc) = @_ ;
    my($sbrName,$fhinLoc,$tmp,$Lok,@idtmp,%tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastGetSummary_5       BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#       in:                     $fileInLoc    : file with BLAST output
#       in:                     $minLaliLoc   : take those with LALI > x      (=0: all)
#       in:                     $minDistLoc   : take those with $pide>HSSP+X  (=0: all)
#       out:                    1|0,msg,$tmp{}, with
#                               $tmp{"NROWS"}     : number of pairs
#                               $tmp{"id",$it}    : name of protein it
#                               $tmp{"len",$it}   : length of protein it
#                               $tmp{"lali",$it}  : length of alignment for protein it
#                               $tmp{"prob",$it}  : BLAST probability for it
#                               $tmp{"score",$it} : BLAST score for it
#                               $tmp{"pide",$it}  : pairwise percentage sequence identity
#                               $tmp{"dist",$it}  : distance from HSSP-curve
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastGetSummary_5";$fhinLoc="FHIN_"."blastGetSummary_5";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # adjust
    $minLaliLoc=0               if (! defined $minLaliLoc || ! $minLaliLoc);
    $minDistLoc=-100            if (! defined $minDistLoc || ! $minDistLoc);
                                # ------------------------------
                                # read file
                                # ------------------------------
    ($Lok,$msg,$rh_hdrLoc)=   
        &blastRdHdr_5($fileInLoc);
    return(&errSbrMsg("failed reading blast header ($fileInLoc)",$msg)) if (! $Lok);

    $rh_hdrLoc->{"id"}=~s/,*$//g; # interpret
    @idtmp=split(/,/,$rh_hdrLoc->{"id"});
                                # ------------------------------
                                # loop over all pairs found
                                # ------------------------------
    undef %tmp; 
    $ct=0;
    while (@idtmp) {
	$idtmp=shift @idtmp;
        next if ($rh_hdrLoc->{"$idtmp","lali"} < $minLaliLoc);
                                # compile distance to HSSP threshold (new)
        ($pideCurve,$msg)= 
#            &getDistanceHsspCurve($rh_hdrLoc->{"$idtmp","lali"});
            &getDistanceNewCurveIde($rh_hdrLoc->{"$idtmp","lali"});
        return(&errSbrMsg("failed getDistanceNewCurveIde",$msg))  
            if ($msg !~ /^ok/);
            
        $dist=$rh_hdrLoc->{"$idtmp","ide"}-$pideCurve;
        next if ($dist < $minDistLoc);
                                # is ok -> TAKE it
        ++$ct;
        $tmp{"id","$ct"}=       $idtmp;
	foreach $kwd ("len","lali","prob","score"){
	    $tmp{"$kwd","$ct"}= $rh_hdrLoc->{"$idtmp","$kwd"}; }
        $tmp{"pide","$ct"}=     $rh_hdrLoc->{"$idtmp","ide"};
        $tmp{"dist","$ct"}=     $dist;
    } 
    $tmp{"NROWS"}=$ct;

    undef %{rh_hdrLoc};		# slim-is-in !
    return(1,"ok $sbrName",\%tmp);
}				# end of blastGetSummary_5

#===============================================================================
sub blastRdHdr_5 {
    my($fileInLoc) = @_ ;
    my($sbrName,$fhinLoc,$tmp,$Lok,@idFoundLoc,
	  $Lread,$name,%hdrLoc,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastRdHdr_5                 reads header of BLASTP output file
#       in:                     $fileBlast
#       out:                    (1,'ok',%hdrLoc)
#       out:                    $hdrLoc{"$id"}='id1,id2,...'
#       out:                    $hdrLoc{"$id","$kwd"} , with:
#                                  $kwd=(score|prob|ide|len|lali)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastRdHdr_5";$fhinLoc="FHIN-blastRdHdr_5";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")    if (! defined $fileInLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc") if (! -e $fileInLoc);
				# ------------------------------
				# open BLAST output
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n");
				# ------------------------------
    $#idFoundLoc=$Lread=0;	# read file
    while (<$fhinLoc>) {
	last if ($_=~/^\s*Sequences producing /i);}
				# ------------------------------
				# skip header summary
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)<1 || $_ !~/\S/); # skip empty line
	$Lread=1 if (! $Lread && $_=~/^\s*>/);
	next if (! $Lread);
	last if ($_=~/^\s*Parameters/i); # final
				# ------------------------------
	$line=$_;		# read ali paras
				# id
	if    ($line=~/^\s*>\s*(.*)/){
	    $name=$1;$id=$name;$id=~s/^([\S]+)\s+.*$/$1/g;
	    if (length($id)>0){
		push(@idFoundLoc,$id);$Lskip=0;
		$hdrLoc{"$id","name"}=$name;}
	    else              {
		$Lskip=1;}}
				# length
	elsif (! $Lskip && ! defined $hdrLoc{"$id","len"} && 
	       ($line=~/^\s*Length = (\d+)/)) {
	    $hdrLoc{"$id","len"}=$1;}
				# sequence identity
	elsif (! $Lskip && ! defined $hdrLoc{"$id","ide"} &&
	       ($line=~/^\s* Identities = \d+\/(\d+) \((\d+)/) ) {
	    $hdrLoc{"$id","lali"}=$1;
	    $hdrLoc{"ide","$id"}=$hdrLoc{"$id","ide"}=$2;}
				# score + prob (blast3)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = [\d\.]+ bits \((\d+)\).*, Expect = \s*([\d\-\.e]+)/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}
				# score + prob (blast2)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}}close($fhinLoc);
				# ------------------------------
    $hdrLoc{"id"}="";		# arrange to pass the result
    for $id(@idFoundLoc){
	$hdrLoc{"id"}.="$id,"; } $hdrLoc{"id"}=~s/,*$//g;

    $#idFoundLoc=0;		# save space
    return(1,"ok $sbrName",\%hdrLoc);
}				# end of blastRdHdr_5 

#===============================================================================
sub blastWrtSummary_5 {
    my($fileOutLoc,$rh_tmp) = @_ ;
    my($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastWrtSummary_5             writes summary for blast results (%ide,len,distance HSSP)
#       in:                     $fileOutLoc   (if = 0, written to STDOUT)
#       in:                     $tmp{} :
#                    HEADER:
#                               $tmp{"para","expect"}='para1,para2' 
#                               $tmp{"para","paraN"}   : value for parameter paraN
#                               $tmp{"form","paraN"}   : output format for paraN (default '%-s')
#                    DATA gen:
#                               $tmp{"NROWS"}        : number of proteins (it1)
#                               
#                               $tmp{$it1}             : number of pairs for it1
#                               $tmp{"id",$it1}        : name of protein it1
#                    DATA rows:
#                               $tmp{$it1,"id",$it2}   : name of protein it2 aligned to it1
#                               $tmp{$it1,"len",$it2}  : length of protein it2
#                               $tmp{$it1,"lali",$it2} : alignment length for it1/it2
#                               $tmp{$it1,"pide",$it2} : perc sequence identity for it1/it2
#                               $tmp{$it1,"dist",$it2} : distance from HSSP-curve for it1/it2
#                               $tmp{$it1,"prob",$it2} : BLAST prob for it1/it2
#                               $tmp{$it1,"score",$it2}: BLAST score for it1/it2
#                               
#                               $tmp{"form",$kwd}    : perl format for keyword $kwd
#                               $tmp{"sep"}            : separator for output columns
#                               
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastWrtSummary_5";$fhoutLoc="FHOUT_"."blastWrtSummary_5";
				# ------------------------------
				# defaults
				# ------------------------------
    $form{"id"}=   "%-15s";
    $form{"len"}=  "%5d";
    $form{"lali"}= "%4d";
    $form{"pide"}= "%5.1f";
    $form{"dist"}= "%5.1f";
    $form{"prob"}= "%6.3f";
    $form{"score"}="%5.1f";
    $sepLoc="\t";
    $sepLoc=$rh_tmp->{"sep"}    if (defined $rh_tmp->{"sep"});
				# ------------------------------
				# what do we have?
				# ------------------------------
    $#kwdtmp=0;
    push(@kwdtmp,"id")          if (defined $rh_tmp->{"1","id","1"});
    push(@kwdtmp,"len")         if (defined $rh_tmp->{"1","len","1"});
    push(@kwdtmp,"lali")        if (defined $rh_tmp->{"1","lali","1"});
    push(@kwdtmp,"pide")        if (defined $rh_tmp->{"1","pide","1"});
    push(@kwdtmp,"dist")        if (defined $rh_tmp->{"1","dist","1"});
    push(@kwdtmp,"prob")        if (defined $rh_tmp->{"1","prob","1"});
    push(@kwdtmp,"score")       if (defined $rh_tmp->{"1","score","1"});
				# ------------------------------
                                # format defaults
                                # ------------------------------
    foreach $kwd (@kwdtmp){
        $form{"$kwd"}=$rh_tmp->{"form","$kwd"} if (defined $rh_tmp->{"form","$kwd"}); }

				# ------------------------------
				# header defaults
				# ------------------------------
    $tmp2{"nota","id1"}=        "guide sequence";
    $tmp2{"nota","id2"}=        "aligned sequence";
    $tmp2{"nota","len"}=        "length of aligned sequence";
    $tmp2{"nota","lali"}=       "alignment length";
    $tmp2{"nota","pide"}=       "percentage sequence identity";
    $tmp2{"nota","dist"}=       "distance from new HSSP curve";
    $tmp2{"nota","prob"}=       "BLAST probability";
    $tmp2{"nota","score"}=      "BLAST raw score";

    $tmp2{"nota","expect"}="";
    foreach $kwd (@kwdtmp) {
        $tmp2{"nota","expect"}.="$kwd,";}
    $tmp2{"nota","expect"}=~s/,*$//g;

    $tmp2{"para","expect"}= "";
    $tmp2{"para","expect"}.=
	$rh_tmp->{"para","expect"}  if (defined $rh_tmp->{"para","expect"});
    foreach $kwd (split(/,/,$tmp2{"para","expect"})){	# import
	$tmp2{"para","$kwd"}=$rh_tmp->{"para","$kwd"};}
    $tmp2{"para","expect"}.=",PROTEINS";
    $tmp2{"para","PROTEINS"}=""; $tmp2{"form","PROTEINS"}="%-s";
    foreach $it1 (1..$rh_tmp->{"NROWS"}) {
        $tmp2{"para","PROTEINS"}.=$rh_tmp->{"id","$it1"}.",";}
    $tmp2{"para","PROTEINS"}=~s/,*$//g;
                                # --------------------------------------------------
                                # now write it
                                # --------------------------------------------------
    
				# open file
    if (! $fileOutLoc || $fileOutLoc eq "STDOUT"){
	$fhoutLoc="STDOUT";}
    else { &open_file("$fhoutLoc",">$fileOutLoc") || 
               return(&errSbr("fileOutLoc=$fileOutLoc, not created")); }
	    
				# ------------------------------
				# write header
				# ------------------------------
    if ($fhoutLoc ne "STDOUT"){
        ($Lok,$msg)=
	    &rdbGenWrtHdr($fhoutLoc,%tmp2);
	return(&errSbrMsg("failed writing RDB header (lib-br:rdbGenWrtHdr)",$msg)) if (! $Lok); }
    undef %tmp2;                # slim-is-in!

				# ------------------------------
				# write names
				# ------------------------------

    $formid=$form{"id"};
    $fin=""; $form=$formid;   $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
    $fin.= sprintf ("$form$sepLoc","id1"); 
    foreach $kwd (@kwdtmp) {$form=$form{"$kwd"}; 
			    $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
			    $kwd2=$kwd;
			    $kwd2="id2" if ($kwd eq "id");
                            $fin.= sprintf ("$form$sepLoc",$kwd2); }
    $fin=~s/$sepLoc$//;
    print $fhoutLoc "$fin\n";
				# ------------------------------
                                # write data
				# ------------------------------
    foreach $it1 (1..$rh_tmp->{"NROWS"}){
        $fin1=         sprintf ( "$formid$sepLoc",$rh_tmp->{"id","$it1"}) 
	    if (defined $rh_tmp->{"id","$it1"});

				# none above threshold
        if (! defined $rh_tmp->{"$it1"} || $rh_tmp->{"$it1"} == 0) {
	    $fin=$fin1;
	    $fin.=     sprintf ("$formid$sepLoc","none"); 
            foreach $kwd (@kwdtmp) { 
		next if ($kwd eq $kwdtmp[1]);
                $form=$form{"$kwd"}; $form=~s/(\.\d+)[FND]$|d$//gi;$form.="s";
                $fin.= sprintf ("$form$sepLoc",""); }
	    print $fhoutLoc $fin,"\n";
	    next;}
				# loop over all above
	foreach $it2 (1..$rh_tmp->{"$it1"}){
	    $fin=$fin1;
            $Lerror=0;
            foreach $kwd (@kwdtmp) { 
                if (! defined $rh_tmp->{"$it1","$kwd","$it2"}) {
                    $Lerror=1;
                    last; }
                $form=$form{"$kwd"};
                $fin.= sprintf ("$form$sepLoc",$rh_tmp->{"$it1","$kwd","$it2"}); }
            next if ($Lerror);
            $fin=~s/$sepLoc$//;
            print $fhoutLoc $fin,"\n";}}

    close($fhoutLoc)            if ($fhoutLoc ne "STDOUT");
    undef %form;		# slim-is-in!
    return(1,"ok $sbrName");
}				# end of blastWrtSummary_5

#===============================================================================
sub fileColumnGenRd_5 {
    my($fileInLoc,@colNumLoc) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,@rd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileColumnGenRd_5           general reader for column formats
#                               (ignoring '#' and first line)
#       in:                     $fileInLoc
#       in:                     @colNum : column numbers, if 0: read all
#       out:                    1|0,msg,$nrows,\%rd
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br5:"."fileColumnGenRd_5";
    $fhinLoc="FHIN_"."fileColumnGenRd_5";$fhoutLoc="FHIN_"."fileColumnGenRd_5";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %rd;
    $errWrt="";
    $ctLine=0;			# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	++$ctLine; $itrow=$ctLine-1;
	next if ($ctLine==1);	# skip first line
	$_=~s/\n//g;
	$_=~s/^[\s\t]*|[\s\t]*$//g; # purge leading blanks|tabs

	@tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}

	if ($itrow==1){		# only first time: check numbers passed
	    @colNumLoc=(1..$#tmp) if (! defined @colNumLoc || ! @colNumLoc); }

				# read columns
	foreach $itcol (@colNumLoc) {
	    $tmp=$tmp[$itcol];
	    if (! defined $tmp){
		$errWrt.="*** ERROR $SBR: itrow=$itrow, itcol=$itcol, not defined (file=$fileInLoc)\n";
		next; }
	    $rd[$itrow][$itcol]=$tmp[$itcol];
	}
    } close($fhinLoc);
    $nrows=$itrow;

    return(1,$errWrt)           if (length($errWrt) > 0);
    return(1,"ok $sbrName",$nrows,\@rd);
}				# end of fileColumnGenRd_5

#===============================================================================
sub prtProtSeq {
    my($rh_seq) = @_ ;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prtProtSeq                  prints protein sequences (asf) like:
#                                  
#                                   ....,....1 ....,....2
#                               AA  SEQWENCEAA SEQWENCE
#                               SEC LLLEEELLHH LLLEEELL 
#                                  
#       in:                     $rh_seq->{}
#       in:                     "kwd"='kwd1,kwd2'    : all keywords for following array
#       in:                     "kwdFormat"          : number of characters to write per keyword
#       in:                     "$kwd"               : sequence
#       in:                     "count"=<1|0|undef>  : add points counting the residues
#                                      def = NO
#       in:                     "block"=<\d+|0|undef>: number of residues to group (e.g. 10)
#                                      def = NONE
#       in:                     "line"=<\d+|0|undef> : number of residues per line
#                                      def = 50
#       in:                     "sepSect"            : between sections
#       in:                     "preText"            : text before each line
#       in:                     "begSeq"             : e.g. '|' before sequence
#       in:                     "endSeq"             : e.g. '|' after sequence
#       out:                    $wrt=sprintf ready to print!
#-------------------------------------------------------------------------------
    $SBR="lib-nn:"."prtProtSeq";
				# ------------------------------
				# defaults
    $perLine=  50;		# number of residues per line
    $perBlock=  0;		# number of residues to group (e.g. 10)
    $Lcount=    0;		# add points counting residues
    $formKwd=   0;		# number of characters to write per keyword
    $sepSect=   "";		# separator between sections (may be '\n')
    $preText=   "";		# text before each line
    $begSeq=    "";
    $endSeq=    "";

				# ------------------------------
				# check arguments
#    return(&errSbr("not def !",$SBR))          if (! defined $);
    $perLine= $rh_seq->{"line"}      if (defined $rh_seq->{"line"}      && $rh_seq->{"line"});
    $perBlock=$rh_seq->{"block"}     if (defined $rh_seq->{"block"}     && $rh_seq->{"block"});
    $Lcount=  1                      if (defined $rh_seq->{"count"}     && $rh_seq->{"count"});
    $formKwd= $rh_seq->{"kwdFormat"} if (defined $rh_seq->{"kwdFormat"} && $rh_seq->{"kwdFormat"});
    $sepSect= $rh_seq->{"sepSect"}   if (defined $rh_seq->{"sepSect"}   && $rh_seq->{"sepSect"});
    $preText= $rh_seq->{"preText"}   if (defined $rh_seq->{"preText"}   && $rh_seq->{"preText"});
    $begSeq=  $rh_seq->{"begSeq"}    if (defined $rh_seq->{"begSeq"}    && $rh_seq->{"begSeq"});
    $endSeq=  $rh_seq->{"endSeq"}    if (defined $rh_seq->{"endSeq"}    && $rh_seq->{"endSeq"});

    $sepKwdSeq=" ";

    if ($perBlock) {		# how many blocks?
	$nBlock=int($perBlock/$perLine);
	$nBlock+=1		if ($nBlock != ($perBlock/$perLine)); }

				# keywords
    @tmp=split(/,/,$rh_seq->{"kwd"});

				# ------------------------------
    $len=0;			# maximal length sequence
    foreach $kwd (@tmp) {
	$lenHere=length($rh_seq->{$kwd});
	$len=$lenHere           if ($lenHere > $len); }
				# ------------------------------
				# maximal length keyword
    if (! $formKwd) {
	foreach $kwd (@tmp) {
	    $lenHere=length($kwd);
	    $formKwd=$lenHere   if ($lenHere > $formKwd); }}
    
				# --------------------------------------------------
				# all residues
				# --------------------------------------------------
    $wrt="";
    for ($it1=1; $it1 <= $len; $it1 += $perLine){
				# lines
	$wrt.=                  sprintf($preText."%-".$formKwd."s".$sepKwdSeq."%-s%-s%-s\n",
					" " x length($begSeq),
					&myprt_npoints($perLine,$it1),
					" " x length($endSeq)) if ($Lcount);
	    
				# ------------------------------
				# all keywords
				# ------------------------------
	foreach $kwd (@tmp) {
	    $remain=    $len - $it1 + 1;
	    $perLineNow=$perLine;
	    $perLineNow=$remain if ($remain < $perLine);
	    $tmp=       substr($rh_seq->{$kwd},$it1,$perLineNow);
				# name (keyword)
	    $wrt.=              sprintf($preText."%-".$formKwd."s".$sepKwdSeq,$kwd);
	    $wrt.=              $begSeq;
				# --------------------
				# do blocks
	    if ($perBlock) {
		for ($it2=1; $it2 <= length($tmp); $it2 += $perBlock){
		    $remain2=    length($tmp) - $it2 + 1;
		    $perBlockNow=$perBlock;
		    $perBlockNow=$remain2 if ($remain2 < $perBlockNow);
		    $tmp2=       substr($tmp,$it2,$perBlockNow);
		    $wrt.=      sprintf("%-s ",$tmp2); } }
				# --------------------
				# no blocks
	    else {
		$wrt.=          sprintf("%-s",$tmp); }
	    $wrt.=              $endSeq;
	    $wrt.=              "\n";
	}
    }

    return($wrt);
}				# end of prtProtSeq

#===============================================================================
sub rdRdbAssociative_5 {
    my ($fileInLoc,@des_in) = @_ ;
    my ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative_5          reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       in:                     $des_in[n]='all'      -> all will be read
#       in:                     $des_in[n]='all_head' -> full header will be read
#       in:                     $des_in[n]='all_body' -> full body (all columns) will be read
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative_5";
				# get input
    $Lhead=$Lhead_all=
	$Lbody=$Lbody_all=
	    $#des_headin=$#des_bodyin=0;

    foreach $des_in (@des_in){
	if    ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif ($des_in=~/^all$/)              {$Lhead=$Lhead_all=$Lbody=$Lbody_all=1;}
	elsif ($des_in=~/^all_head/)          {$Lhead=$Lhead_all=1; }
	elsif ($des_in=~/^all_body/)          {$Lbody=$Lbody=1; }
	elsif ((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif ((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif ($Lhead)                        {push(@des_headin,$des_in);}
	elsif ($Lbody)                        {$des_in=~s/\n|\s//g;;
					       push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhinLoc","$fileInLoc") ;
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    ($ra_readname,$ra_readformat,$ra_readcol)=
	&rdRdbAssociativeNum_5($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}

				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    if (! $Lbody_all) {
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for ($it=1; $it<=$#READNAME; ++$it) {
		$rd=$ra_readname->[$it];$rd=~s/\s//g;
		if ($rd eq $des_in) {
		    $ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		    last;} }
	    if((!$Lfound) && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}}
				# ------------------------------
				# read all columns
    else {
	for ($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$ra_readname->[$it];$rd=~s/\s//g;
	    $ptr_rd2des{$rd}=$it;push(@des_body,$rd);
	}}
				# ------------------------------
				# get format
    foreach $des_in(@des_body) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $ra_readformat->[$it] ) {
	    $rdrdb{"$des_in","format"}=$ra_readformat->[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in (@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$ra_readcol->[$itrd]);
	$nrow_rd=$#tmp          if (! $nrow_rd);
	if ($nrow_rd != $#tmp) {
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "***         in RDB file '$fileInLoc' for rows with ".
		"key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in","$it"}=$tmp[$it];
	    $rdrdb{"$des_in","$it"}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd; 
	
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (\%rdrdb);
}				# end of rdRdbAssociative_5

#===============================================================================
sub rdRdbAssociativeNum_5 {
    my ($fhLoc2,@readnum) = @_ ;
    my ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum_5   reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;$READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
    return(\@READNAME,\@READFORMAT,\@READCOL);
}				# end of rdRdbAssociativeNum_5

1;
