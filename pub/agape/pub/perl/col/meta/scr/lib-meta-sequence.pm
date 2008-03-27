##!/usr/bin/perl -w

#===============================================================================
sub dsspRdSeq {
    my   ($ra_fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[=1;
#-------------------------------------------------------------------------------
#   dsspRdSeq                   extracts the sequence from DSSP
#       in:                     $ra_fileIn,$chain,$beg,$end
#       in:                     for wild cards beg="", end=""
#       out:                    $Lok,$seq,$seqC (second replaced a-z to C)
#-------------------------------------------------------------------------------
    $sbrName="dsspRdSeq";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);
				#----------------------------------------
				# extract input
    if (defined $chainIn && length($chainIn)>0 && $chainIn=~/[A-Z0-9]/){
	$chainIn=~s/\s//g;$chainIn =~tr/[a-z]/[A-Z]/; }
    else{
	$chainIn = "*" ;}
    $begIn = "*" if (! defined $begIn || length($begIn)==0); $begIn=~s/\s//g;;
    $endIn = "*" if (! defined $endIn || length($endIn)==0); $endIn=~s/\s//g;;
				#--------------------------------------------------
				# read in file
    foreach $it (1 .. $#{$ra_fileIn}) {
	last if ($ra_fileIn->[$it]=~/^  \#  RESIDUE/ ); } # skip anything before data...
    $seq=$seqC="";
    $itTmp=$it;
    foreach $it (($itTmp+1) .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$Lread=1;
	$chainRd=substr($_,12,1); 
	$pos=    substr($_,7,5); $pos=~s/\s//g;

	next  if (($chainRd ne "$chainIn" && $chainIn ne "*" ) || # check chain
                  ($begIn ne "*"  && $pos < $begIn) || # check begin
                  ($endIn ne "*"  && $pos > $endIn)) ; # check end

	$aa=substr($_,14,1);
	$aa2=$aa;if ($aa2=~/[a-z]/){$aa2="C";}	# lower case to C
	$seq.=$aa;
	$seqC.=$aa2; } 
    return(1,$seq,$seqC)        if (length($seq)>0);
    return(0);
}                               # end of dsspRdSeq 

#===============================================================================
sub fastaRdGuide {
    my   ($ra_fileIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $ra_fileIn
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $sbrName="fastaRdGuide";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    $ct=0;$seq="";
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") 
	if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#===============================================================================
sub fastaRdMul {
    my   ($ra_fileIn,$rd) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdMul                  reads many sequences in FASTA db
#       in:                     $ra_fileIn,$rd with:
#                               $rd = '1,5,6',   i.e. list of numbers to read
#                               $rd = 'id1,id2', i.e. list of ids to read
#                               NOTE: numbers faster!!!
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="fastaRdMul";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    undef %tmp;
    if (! defined $rd) {
	$LisNumber=1;
	$rd=0;}
    elsif ($rd !~ /[^0-9\,]/){ 
	@tmp=split(/,/,$rd); 
	$LisNumber=1;
	foreach $tmp(@tmp){
	    $tmp{$tmp}=1;}}
    else {
	$LisNumber=0;
	@tmp=split(/,/,$rd); }
    
    $ct=$ctRd=0;
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){ # line with id
	    ++$ct;$Lread=0;
	    last if ($rd && $ctRd==$#tmp); # fin if all found
	    next if ($rd && $LisNumber && ! defined $tmp{$ct});
	    $id=$1;$id=~s/\s\s*/ /g;$id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    $Lread=1 if ( ($LisNumber && defined $tmp{$ct})
			 || $rd == 0);

	    if (! $Lread){	# go through all ids
		foreach $tmp(@tmp){
		    next if ($tmp !~/$id/);
		    $Lread=1;	# does match, so take
		    last;}}
	    next if (! $Lread);

	    ++$ctRd;
	    $tmp{$ctRd,"id"}=$id;
	    $tmp{$ctRd,"seq"}="";}
	elsif ($Lread) {	# line with sequence
	    $tmp{$ctRd,"seq"}.="$_";}}

    $seq=$id="";		# join to long strings
    foreach $it (1..$ctRd) { $id.= $tmp{$it,"id"}."\n";
			     $tmp{$it,"seq"}=~s/\s//g;
			     $seq.=$tmp{$it,"seq"}."\n";}
    $#tmp=0;			# save memory
    undef %tmp;			# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdMul

#===============================================================================
sub fastaWrt {
    local($fileOutLoc,$id,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrt                    writes a sequence in FASTA format
#       in:                     $fileOut,$id,$seq (one string)
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
#    print "yy into write seq=$seqLoc,\n";

    open($fhoutLoc,">".$fileOutLoc) ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
    print $fhoutLoc ">$id\n";
    for($it=1;$it<=length($seqLoc);$it+=50){
	foreach $it2 (0..4){
	    last if (($it+10*$it2)>=length($seqLoc));
	    printf $fhoutLoc " %-10s",substr($seqLoc,($it+10*$it2),10);}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fastaWrt

#===============================================================================
sub fastaWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrtMul                 writes a list of sequences in FASTA format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $fileOut="txt" -> output in printf string!
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id",$ct}   id for sequence $ct
#       in:                     $tmp{"seq",$ct}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    $ctOk=0; 
    $prtloc=
	"";

    foreach $itPair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id",$itPair} || ! defined $tmp{"seq",$itPair});
        ++$ctOk;
                                # some massage
        $tmp{"id",$itPair}=~s/[\s\t\n]+/ /g;
        $tmp{"seq",$itPair}=~s/[\s\t\n]+//g;
                                # write
	$prtloc.=
	    ">".$tmp{"id",$itPair}."\n";
	$lenHere=length($tmp{"seq",$itPair});
        for($it=1; $it<=$lenHere; $it+=50){
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$prtloc.= 
		    sprintf(" %-10s",substr($tmp{"seq",$itPair},$itHere,$nchunk)); 
	    }
	    $prtloc.=
		"\n";
	}
    }

    if ($fileOutLoc ne "txt"){
	open($fhoutLoc,">".$fileOutLoc) ||
	    return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
	print $fhoutLoc 
	    $prtloc;
	$prtloc="";
	close($fhoutLoc); }
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewer sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,$prtloc);
}				# end of fastaWrtMul

#===============================================================================
sub gcgRd {
    my   ($ra_fileIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   gcgRd                       reads sequence in GCG format
#       in:                     $ra_fileIn
#       out:                    1|0,$id,$seq 
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="gcgRd";

    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    $seq="";
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	$line=$_;
	if ($line=~/^\s*(\S+)\s*from\s*:/){
	    $id=$1;
	    next;}
	next if ($line !~ /^\s*\d+\s+(.*)$/);
	$tmp=$1;$tmp=~s/\s//g;
	$seq.=$tmp;}

    return(0,"*** ERROR $sbrName: file=$fileInLoc, no sequence found\n") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of gcgRd

#===============================================================================
sub getFileFormat {
    my   ($ra_fileIn)= @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormat               quick scan for file format
#                               assumptions:
#                               (1) file exists
#                               (2) file is db format (i.e. no list)
#       in:                     $ra_fileIn = reference to array with full sequence info
#       out:                    0|1,format
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormat";$fhinLoc="FHIN_"."getFileFormat";
				# check arguments
    return(0,"no input")        if (! defined $ra_fileIn);

				# special for meta
    return(1,"meta")            if ($ra_fileIn->[1]!~/[^ABCDEFGHIKLMNPQRSTUVWXYZ ]/i);

                                # alignments (EMBL 1)
    return(1,"hssp")            if (&isHssp($ra_fileIn));
    return(1,"strip")           if (&isStrip($ra_fileIn));
    return(1,"fssp")            if (&isFssp($ra_fileIn));
                                # alignments (EMBL 2)
    return(1,"daf")             if (&isDaf($ra_fileIn));
    return(1,"saf")             if (&isSaf($ra_fileIn));
                                # alignments other
    return(1,"msf")             if (&isMsf($ra_fileIn));
    return(1,"fastamul")        if (&isFastaMul($ra_fileIn));
    return(1,"pirmul")          if (&isPirMul($ra_fileIn));
                                # sequences
    return(1,"dssp")            if (&isDssp($ra_fileIn));
    return(1,"fasta")           if (&isFasta($ra_fileIn));
    return(1,"swiss")           if (&isSwiss($ra_fileIn));
    return(1,"pir")             if (&isPir($ra_fileIn));
    return(1,"gcg")             if (&isGcg($ra_fileIn));
    return(1,"pdb")             if (&isPdb($ra_fileIn));
                                # PP
    return(1,"ppcol")           if (&isPPcol($ra_fileIn));
				# NN
    return(1,"nndb")            if (&isRdbNNdb($ra_fileIn));
                                # PHD
    return(1,"phdrdbboth")      if (&isPhdBoth($ra_fileIn));
    return(1,"phdrdbacc")       if (&isPhdAcc($ra_fileIn));
    return(1,"phdrdbhtmref")    if (&isPhdHtmref($ra_fileIn));
    return(1,"phdrdbhtmtop")    if (&isPhdHtmtop($ra_fileIn));
    return(1,"phdrdbhtm")       if (&isPhdHtm($ra_fileIn));
    return(1,"phdrdbsec")       if (&isPhdSec($ra_fileIn));
                                # RDB
    return(1,"rdb")             if (&isRdb($ra_fileIn));
    return(1,"unk");
}				# end of getFileFormat

#===============================================================================
sub isDaf {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is DAF; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^\# DAF/i);
    return(0);
}				# end of isDaf

#===============================================================================
sub isDssp {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isDssp                      checks whether or not file is in DSSP format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is dssp; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i);
    return(0);
}				# end of isDssp

#===============================================================================
sub isDsspList {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isDsspList                  checks whether or not file is a list of DSSP files
#       in:                     @content_of_file (as reference)
#       out:                    1 if is dssp; 0 else
#-------------------------------------------------------------------------------
    $sbr3="isDsspList";
    return(0) if (! defined $ra_file);
    foreach $it (1 .. $#{$ra_file}) {
	return(0,"*** $sbr3: file no $it=".$ra_file->[$it]." missing!");
	return(0) if (! &isDssp($ra_file->[$it]));
    }
    return(1);			# ok all are DSSP
}				# end of isDsspList

#===============================================================================
sub isFasta {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isFasta                checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $one=$ra_file->[1];
    $two=$ra_file->[2];
				# is PIR '>P1;'
    return(0)                   if ($one =~ /^\s*>\s*p.*\;/i);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
				    $two !~/[^\sABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i);
    return(0);
}				# end of isFasta

#===============================================================================
sub isFastaMul {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $one=$ra_file->[1];
    $two=$ra_file->[2];
    return(0)                   if (! defined $two || ! defined $one);
				# is PIR '>P1;'
    return(0)                   if ($one =~ /^\s*>\s*p.*\;/i);
				# note: MUL needs more than 1!!!
#    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
#				    $two !~/[^\sABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i);
    foreach $it (3 .. $#{$ra_file}) {
	return(0) if ($ra_file->[$it] =~ /^\s*>\s*p.*\;/i);
	next if ($ra_file->[$it] !~ /^\s*>\s*\w+/);
	return(1);
	last;}
    return(0);
}				# end of isFastaMul
     
#===============================================================================
sub isFssp {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isFssp                      checks whether or not file is in FSSP format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is fssp; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^FSSP/);
    return(0);
}				# end of isFssp

#===============================================================================
sub isGcg {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#    isGcg                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);

    $ctLocFlag=$already_sequence=0;
    foreach $it (1 .. $#{$ra_file}) {
	$tmp=$ra_file->[$it];
	last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
	if   ($tmp=~/from\s*:\s*\d+\s*to:\s*\d+/i)          {
	    ++$ctLocFlag;}
	elsif($tmp=~/^\s*\w+\s+Length\s*:\s+\d+\s+\d\d\-/i) {
	    ++$ctLocFlag;}
	elsif(! $already_sequence && $tmp=~/[\s\t]*\d+\s+[A-Z]+/i) {
	    $already_sequence=1;
	    ++$ctLocFlag;}
	last if ($ctLocFlag==3);}
    return(1) if ($ctLocFlag==3);
    return(0) ;
}				# end of isGcg

#===============================================================================
sub isHssp {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isHssp                      checks whether or not file is in HSSP format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is hssp; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^HSSP/i);
    return(0);
}				# end of isHssp
     
#===============================================================================
sub isHsspEmpty {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspEmpty                 checks whether or not HSSP file has NALIGN=0
#       in:                     @content_of_file (as reference)
#       out:                    1 if is empty; 0 else
#-------------------------------------------------------------------------------
    return(1) if (! defined $ra_file);
    foreach $it (1 .. $#{$ra_file}) {
	next if ($ra_file->[$it] !~/^NALIGN\s+(\d+)/);
	return(0) if (defined $1 && $1 > 0);
    }
    return(1);
}				# end of isHsspEmpty

#===============================================================================
sub isMsf {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/\s*MSF[\s:]+/i);
    return(0);
}				# end of isMsf

#===============================================================================
sub isNNinFor {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isNNinFor                   is input for FORTRAN input
#       in:                     @content_of_file (as reference)
#       out:                    1|0,msg,$LisNNinFor
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/NNin_in/i);
    return(0);
}				# end of isNNinFor

#===============================================================================
sub isPdb { 
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPdb                       checks whether or not file is PDB format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
#HEADER    PANCREATIC HORMONE                      16-JAN-81   1PPT      1PPT   3
    return(1) if ($ra_file->[1]=~/^HEADER\s+.*\d\w\w\w\s+\d+\s*$/i);
    return(0);
}				# end of isPdb

#===============================================================================
sub isPhdAcc {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in PHD.rdb_acc format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $Lrdb=0;
    foreach $it (1 .. $#{$ra_file}) {
				# first one has to be RDB
	$Lrdb=1    if ($ra_file->[$it]=~/^\# Perl-RDB/i);
	return(0)  if (! $Lrdb);
	return(0)  if ($ra_file->[$it]!~/^\#/);
	if ($ra_file->[$it]=~/\#\s+PHD\s*(\S_)/i) {
	    return(1) if (defined $1 && 
			  $1=~/acc/i);
	    last; }}
    return(0);
}				# end of isPhdAcc

#===============================================================================
sub isPhdBoth {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPhdBoth                   checks whether or not file is in PHD.rdb format 
#                               acc + sec
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $Lrdb=0;
    foreach $it (1 .. $#{$ra_file}) {
				# first one has to be RDB
	$Lrdb=1    if ($ra_file->[$it]=~/^\# Perl-RDB/i);
	return(0)  if (! $Lrdb);
	return(0)  if ($ra_file->[$it]!~/^\#/);
	if ($ra_file->[$it]=~/\#\s+PHD\s*(\S+).*PHD\s*(\S+)/i) {
	    return(1) if (defined $1 && defined $2 &&
			  $1=~/(acc|sec)/i && $2=~/(acc|sec)/);
	    last; }}
    return(0);
}				# end of isPhdBoth

#===============================================================================
sub isPhdHtm {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in PHD.rdb_htm format
#				(i.e. the dirty ali format used for aqua)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $Lrdb=0;
    foreach $it (1 .. $#{$ra_file}) {
				# first one has to be RDB
	$Lrdb=1    if ($ra_file->[$it]=~/^\# Perl-RDB/i);
	return(0)  if (! $Lrdb);
	return(0)  if ($ra_file->[$it]!~/^\#/);
	if ($ra_file->[$it]=~/\#\s+PHD\s*(\S_)/i) {
	    return(1) if (defined $1 && 
			  $1=~/htm/i);
	    last; }}
    return(0);
}				# end of isPhdHtm

#===============================================================================
sub isPhdHtmref {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPhdHtmref                 checks whether or not file is in PHD.rdb_Htmref format
#				(i.e. the dirty ali format used for aqua)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $Lrdb=0;
    foreach $it (1 .. $#{$ra_file}) {
				# first one has to be RDB
	$Lrdb=1    if ($ra_file->[$it]=~/^\# Perl-RDB/i);
	return(0)  if (! $Lrdb);
	return(0)  if ($ra_file->[$it]!~/^\#/);
	if ($ra_file->[$it]=~/\#\s+PHD\s*(\S_)/i) {
	    return(1) if (defined $1 && 
			  $1=~/htm.*ref/i);
	    last; }}
    return(0);
}				# end of isPhdHtmref

#===============================================================================
sub isPhdHtmtop {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPhdHtmtop                 checks whether or not file is in PHD.rdb_Htmtop format
#				(i.e. the dirty ali format used for aqua)
#       in:                     @content_of_file (as toperence)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $Lrdb=0;
    foreach $it (1 .. $#{$ra_file}) {
				# first one has to be RDB
	$Lrdb=1    if ($ra_file->[$it]=~/^\# Perl-RDB/i);
	return(0)  if (! $Lrdb);
	return(0)  if ($ra_file->[$it]!~/^\#/);
	if ($ra_file->[$it]=~/\#\s+PHD\s*(\S_)/i) {
	    return(1) if (defined $1 && 
			  $1=~/htm.*top/i);
	    last; }}
    return(0);
}				# end of isPhdHtmtop

#===============================================================================
sub isPhdSec {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in PHD.rdb_sec format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $Lrdb=0;
    foreach $it (1 .. $#{$ra_file}) {
				# first one has to be RDB
	$Lrdb=1    if ($ra_file->[$it]=~/^\# Perl-RDB/i);
	return(0)  if (! $Lrdb);
	return(0)  if ($ra_file->[$it]!~/^\#/);
	if ($ra_file->[$it]=~/\#\s+PHD\s*(\S_)/i) {
	    return(1) if (defined $1 && 
			  $1=~/sec/i);
	    last; }}
    return(0);
}				# end of isPhdSec

#===============================================================================
sub isPir {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#    isPir                      checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $one=$ra_file->[1];
    $two=$ra_file->[2];
    return(0)                   if (! defined $one ||
				    $one !~ /^\>P1\;/i);
    return(0)                   if (! defined $two);
    return(1);
}				# end of isPir

#===============================================================================
sub isPirMul {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    $one=$ra_file->[1];
    $two=$ra_file->[2];
    return(0)                   if (! defined $two || ! defined $one);
#    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
#				    $two !~/[^\sABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i);
    foreach $it (3 .. $#{$ra_file}) {
	next if ($ra_file->[$it] !~ /^\s*>\s*P1.*\;/i);
	return(1);
	last;}
    return(0);
}				# end of isPirMul

#===============================================================================
sub isPPcol {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isPPcol                     checks whether or not file is in RDB format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is ppcol, 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^\# pp.*col/i);
    return(0);
}				# end of isPPcol
     
#===============================================================================
sub isRdb {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     @content_of_file (as reference)
#       out:                    returns 1 if is RDB, 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^\# .*RDB/);
    return(0);
}				# end of isRdb

#===============================================================================
sub isRdbNNdb {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isRdbNNdb                   checks whether or not file is in RDB format for NN.pl
#       in:                     @content_of_file (as reference)
#       out:                    1 if is rdb_nn; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^\# Perl-RDB.*NNdb/i);
    return(0);
}				# end of isRdbNNdb

#===============================================================================
sub isSaf {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^\#.*SAF/i);
    return(0);
}				# end of isSaf

#===============================================================================
sub isStrip {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#   isStrip                     checks whether or not file is in HSSP-strip format
#       in:                     @content_of_file (as reference)
#       out:                    1 if is strip; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/===  MAXHOM-STRIP  ===/i);
    return(0);
}				# end of isStrip

#===============================================================================
sub isSwiss {
    my($ra_file)= @_; $[ =1 ;
#-------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     @content_of_file (as reference)
#       out:                    1 if is yes; 0 else
#-------------------------------------------------------------------------------
    return(0) if (! defined $ra_file);
    return(1) if ($ra_file->[1]=~/^ID   /i);
    return(0);
}				# end of isSwiss

#===============================================================================
sub msfRd {
    my   ($ra_fileIn) = @_ ;
    local ($sbrName,$Lok,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfRd                       reads MSF files input format
#       in:                     $ra_fileIn
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="msfRd"; 
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

				# ------------------------------
    undef %msfIn;               # read file
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
        last if ($_=~/^\s*\//); # skip everything before ali sections
    } 
    $itTmp=$it;
    undef %tmp;
    $ct=0;
    foreach $it (($itTmp+1) .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
        $_=~s/^\s*|\s*$//g;     # purge leading blanks
        $tmp=$_;$tmp=~s/\d//g;
        next if (length($tmp)<1); # skip lines empty or with numbers, only
                                # --------------------
				# from here on: 'id sequence'
        $id= $_; $id =~s/^\s*(\S+)\s*.*$/$1/;
        $seq=$_; $seq=~s/^\s*(\S+)\s+(\S.*)$/$2/;
        $seq=~s/\s//g;
        if (! defined $tmp{$id}){ # new
            ++$ct;$tmp{$id}=$ct;
            $msfIn{"id",$ct}= $id;
            $msfIn{"seq",$ct}=$seq;}
        else {
            $ptr=$tmp{$id};
            $msfIn{"seq","$ptr"}.=$seq;}}

    $id=$seq="";
    $ctRd=$ct;
    foreach $ct (1..$ctRd){
	$id.=$msfIn{"id",$ct}."\n";
	$seq.=$msfIn{"seq",$ct}."\n";
    }
    $id=~s/\n$//g;
    $seq=~s/\n$//g;
    undef %msfIn; undef %tmp;	# slim-is-in
    return(1,$id,$seq);
}				# end of msfRd

#===============================================================================
sub msfWrt {
    local($fhoutLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfWrt                      writing an MSF formatted file of aligned strings
#         in:                   $fileMsf,$input{}
#                               if $fileMsf='txt' : all written into text string (sprintf)
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{"$it"}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    $sbrName="msfWrt";
				# ------------------------------
    $#nameLoc=$#tmp=0;		# process input
    foreach $it (1..$input{"NROWS"}){
	$name=$input{"$it"};
	push(@nameLoc,$name);	# store the names
	push(@stringLoc,$input{"$name"}); } # store sequences

    $FROM=$input{"FROM"}        if (defined $input{"FROM"});
    $TO=  $input{"TO"}          if (defined $input{"TO"});

				# ------------------------------
				# write into file
    $prtloc=
	"MSF of: ".$FROM." from:    1 to:   ".length($stringLoc[1])." \n".
	    $TO." MSF: ".length($stringLoc[1]).
		"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";

    foreach $it (1..$#stringLoc){
	$prtloc.=
	    sprintf("Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
			 $nameLoc[$it],length($stringLoc[$it]));
    }
    $prtloc.=
	" \n"."\/\/\n"." \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    $prtloc.=
		sprintf("%-20s",$nameLoc[$it2]);
	    foreach $it3 (1..5){
		last if (length($stringLoc[$it2])<($it+($it3-1)*10));
		$prtloc.=
		    sprintf(" %-10s",substr($stringLoc[$it2],($it+($it3-1)*10),10));
	    }
	    $prtloc.=
		"\n";
	}
	$prtloc.=
	    "\n";
    }
    $prtloc.=
	"\n";
    if ($fhoutLoc ne "txt"){
	print $fhoutLoc $prtloc;
	close($fhoutLoc);
	$prtloc="";}

    $#nameLoc=$#stringLoc=0;	# save space
    return(1,$prtloc);
}				# end of msfWrt

#===============================================================================
sub msfCheckNames {
    my   ($ra_fileIn,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCheckNames               reads MSF file and checks consistency of names
#       in:                     $ra_fileIn
#       out:                    (0,err=list of wrong names)(1,"ok")
#-------------------------------------------------------------------------------
    $sbrName="msfCheckNames";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    undef %name; 
    $Lerr=$#name=0;
				# ------------------------------
				# read header
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
				# read names in header
	if ($_=~/^\s*name\:\s*(\S+)/i){
	    $name{$1}=1;push(@name,$1);
				# ******************************
	    if (length($1)>=15){ # current GOEBEL limit!!!
		print "*** ERROR name must be shorter than 15 characters ($1)\n";
		print "***       it is ",length($1),"\n";
		$Lerr=1;}
	    if (! defined $len){ # sequence length
		$len=$_;$len=~s/^\s*[Nn]ame:\s*\S+\s+[Ll]en:\s*(\d+)\D.*$/$1/;}
	    next;}
	last if ($_=~/\/\//);}
    $itTmp=$it;
    
    $ctBlock=0;			# ------------------------------
    undef %ctRes;		# read body
    foreach $it (($itTmp+1) .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;$tmp=$_;$tmp=~s/\s//g;
	next if (length($tmp)<3);
	if ($_=~/^\s+\d+\s+/ && ($_!~/[A-Za-z]/)){
	    ++$ctBlock;$ctName=0; 
	    undef %ctName;
	    next;}
	$name=$_;$name=~s/^\s*(\S+)\s*.*$/$1/;
	$seq= $_;$seq =~s/^\s*\S+\s+//;$seq=~s/\s//g;
	$ctRes{$name}+=length($seq); # sequence length
	if (! defined $name{$name}){
	    print "*** block $ctBlock, name=$name not used before\n";
	    $Lerr=1;}
	else {
	    ++$ctName; 
	    if (! defined $ctName{$name} ){
		$ctName{$name}=1;} # 
	    else {print "*** block $ctBlock, name=$name more than once\n";
		  $Lerr=1;}}}
    foreach $name(@name){
	if ($ctRes{$name} != $len){
	    print 
		"*** name=$name, wrong no of residues, is=",
		$ctRes{$name},", should be=$len\n";
	    $Lerr=1;}}
    return (1,1) if (! $Lerr);
    return (1,0) if ($Lerr);
}				# end of msfCheckNames

#===============================================================================
sub pdbExtrSequence {
    my   ($ra_fileIn,$chainInLoc,$LskipNucleic) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbExtrSequence             reads the sequence in a PDB file
#       in:                     $ra_fileIn=    content of PDB file
#       in:                     $chainInLoc=   chains to read ('A,B,C' for many)
#                                  ='*'        to read all
#       in:                     $LskipNucleic= skip if nucleic acids
#       out:                    1|0,msg,%pdb as implicit reference with:
#       out:                    $pdb{"chains"}="A,B" -> all chains found ('none' for not specified)
#                               $pdb{$chain}=  sequence for chain $chain 
#                                              (='none' for not specified chain)
#                               NOTE: 'X' used for hetero-atoms, or for symbol 'U'
#                               $pdb{"header"}
#                               $pdb{"compnd"}
#                               $pdb{"source"}
#                               $pdb{"percentage_strange"}= 
#                                              percentage (0-100) of 'strange' acids ('!X')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="pdbExtrSequence";
				# check arguments
    return(0,"*** ERROR $sbrName: not def ra_fileIn!")
	if (! defined $ra_fileIn);
    $chainInLoc="*"             if (! defined $chainInLoc);
    $LskipNucleic=0             if (! defined $LskipNucleic);
    $chainInLoc="*"             if (length($chainInLoc) < 1 || $chainInLoc =~/\s/);

    undef %pdb;			# security
    $#chainLoc=0;
    $ctLine=0;			# count lines in file (for error)
    $ctStrange=0;		# count amino acids (non ACGT)
    $ctRes=0;
    $Lflag=0;			# set to 1 as soon as sequence found

				# ------------------------------
				# read file
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
				# ------------------------------
	++$ctLine;
				# skip anything before sequence
	if ($_!~/^SEQRES/) {

#HEADER    HYDROLASE (SERINE PROTEINASE)           24-APR-89   1P06      1P06   3
	    if ($_=~/^HEADER\s+(.*)\d\d\-[A-Z][A-Z][A-Z]\-\d\d\s*\d\w\w\w\s+/){
		$pdb{"header"}=$1;
		$pdb{"header"}=~s/^\s*|\s*$//g;
		$pdb{"header"}=~s/^\s\s+|\s//g;
		next; }
#COMPND    ALPHA-LYTIC PROTEASE (E.C.3.4.21.12) COMPLEX WITH             1P06   4
#COMPND   2 METHOXYSUCCINYL-*ALA-*ALA-*PRO-*PHENYLALANINE BORONIC ACID   1P06   5
	    if ($_=~/^COMPND\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"compnd"}="" if (! defined $pdb{"compnd"});
		$pdb{"compnd"}.=$1;
		$pdb{"compnd"}=~s/^\s*|\s*$//g;
		$pdb{"compnd"}=~s/\s\s+/\s/g; # purge many blanks
		next; }
#SOURCE    (LYSOBACTER $ENZYMOGENES 495)                                 1P06   6
	    if ($_=~/^SOURCE\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"source"}=$1; $pdb{"source"}=~s/[\(\)\$]//g;
		$pdb{"source"}=~s/^\s*|\s*$//g;
		$pdb{"source"}=~s/\s\s+/\s/g; # purge many blanks
		next; }
	    last if ($Lflag);	# end after read
	    next; }
				# delete stuff at ends
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
#SEQRES   1 A  198  ALA ASN ILE VAL GLY GLY ILE GLU TYR SER ILE ASN ASN  1P06  74
	$Lflag=1;			# sequence found
	$_=~s/\n//g;
	$line=substr($_,11);
	$line=substr($line,1,60);
	$chainRd=$line; $chainRd=~s/^\s*(\D*)\d+.*$/$1/g; $chainRd=~s/\s//g;
	$chainRd="*"            if (! defined $chainRd || length($chainRd)<1);
				# skip if wrong chain
	next if ($chainInLoc ne "*" && $chainRd ne $chainInLoc);
				# rename chain for non-specified
	$chainRd="none"         if ($chainRd eq "*");

				# get sequence part
	$seqRd3= $line; $seqRd3=~s/^\D*\d+(\D+).*$/$1/g;
	$seqRd3=~s/^\s*|\s*$//g; # purge trailing spaces
				# strange
	next if (! defined $seqRd3 || length($seqRd3)<3);
				# split into array of 3-letter residues
	@tmp=split(/\s+/,$seqRd3);
				# ------------------------------
				# end if is nucleic that was NOT
				# wanted!
	return(2,"nucleic","")
	    if ($LskipNucleic && $tmp[1]=~/^[ACGT]$/);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	$seqRd1="";		# 3 letter to 1 letter
	foreach $tmp (@tmp) {
	    ($Lok,$msg,$oneletter)=&amino_acid_convert_3_to_1($tmp);
				# HETERO atom?
	    if    (! $Lok && $oneletter eq "unk") {
		print "-*- WARN $fileInLoc ($ctLine) residue =$tmp\n";
		$oneletter="X";}
	    elsif (! $Lok || $oneletter !~/^[A-Z]$/) { 
		$msgErr="*** $sbrName ($fileInLoc): line=$ctLine, problem with conversion to 1 letter:\n";
		print "xx ".$msgErr.$msg."\n"; exit; # xx
		return(0,$msgErr.$msg); }
	    $seqRd1.=$oneletter; }
				# first
	if (! defined $pdb{$chainRd}) {
	    push(@chainLoc,$chainRd);
	    $pdb{$chainRd}=""; }
				# append to current chain
	$pdb{$chainRd}.=$seqRd1;
				# count non ACGT
	@tmp=split(//,$seqRd1);
	$ctRes+=$#tmp;		# count residues
	foreach $tmp (@tmp) {
	    next if ($tmp!~/^[ABCDEFGHIKLMNPQRSTVWXYZ]$/); # exclude strange stuff
	    ++$ctStrange;}
    } 
    $pdb{"chains"}=join(',',@chainLoc);
    $pdb{"percentage_strange"}=0;
    $pdb{"percentage_strange"}=100*int($ctStrange/$ctRes) if ($ctStrange && $ctRes);
    
    return(1,"ok $sbrName",\%pdb);
}				# end of pdbExtrSequence

#===============================================================================
sub pirRdSeq {
    my   ($ra_fileIn) = @_ ;
    local($sbrName,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdSeq                    reads the sequence from a PIR file
#       in:                     $ra_fileIn
#       out:                    (1,name,sequence in one string)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="pirRdSeq";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    $seq=$id="";$ct=0;
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	++$ct;
	if   ($ct==1){
	    $id=$_;$id=~s/^\s*\>\s*P1\s*\;\s*(\S+)[\s\n]*.*$/$1/g;}
	elsif($ct==2){
	    $id.=", $_";}
	else {
	    $_=~s/[\s\*]//g;
	    $seq.="$_";}}
    $seq=~s/\s//g;$seq=~s/\*$//g;
    return(1,$id,$seq);
}				# end of pirRdSeq

#===============================================================================
sub pirRdMul {
    my   ($ra_fileIn,$extr)= @_ ;
    local($sbrName,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdMul                    reads the sequence from a PIR file
#       in:                     file,$extr with:
#                               $extr = '1,5,6',   i.e. list of numbers to read
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="pirRdMul";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    $extr=~s/\s//g  if (defined $extr);
    $extr=0         if (! defined $extr || $extr =~ /[^0-9\,]/);
    if ($extr){
	@tmp=split(/,/,$extr); 
	undef %tmp;
	foreach $tmp(@tmp){
	    $tmp{$tmp}=1;}}

    $ct=$ctRd=$ctProt=0;        # ------------------------------
				# read the file
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	if ($_ =~ /^\s*>/){	# (1) = id (>P1;)
            $Lread=0;
	    ++$ctProt;
	    $id=$_;$id=~s/^\s*>\s*P1?\s*\;\s*//g;$id=~s/(\S+)[\s\n]*.*$/$1/g;$id=~s/^\s*|\s*$//g;
	    $id.="_";

	    $id.=<$fhinLoc>;	# (2) still id in second line
	    $id=~s/[\s\t]+/ /g;
	    $id=~s/_\s*$/g/;
	    $id=~s/^[\s\t]*|[\s\t]*$//g;
            if (! $extr || ($extr && defined $tmp{$ctProt} && $tmp{$ctProt})){
                ++$ctRd;$Lread=1;
		$tmp{$ctRd,"id"}=$id;
		$tmp{$ctRd,"seq"}="";}}
        elsif($Lread){		# (3+) sequence
            $_=~s/[\s\*]//g;
            $tmp{$ctRd,"seq"}.="$_";}}
                                # ------------------------------
    $seq=$id="";		# join to long strings
    if ($ctRd > 1) {
	foreach $it(1..$ctRd){
	    $id.= $tmp{$it,"id"}."\n";
	    $tmp{$it,"seq"}=~s/\s//g;$tmp{$it,"seq"}=~s/\*$//g;
	    $seq.=$tmp{$it,"seq"}."\n";} }
    else { $it=1;
	   $id= $tmp{$it,"id"};
	   $tmp{$it,"seq"}=~s/\s//g;$tmp{$it,"seq"}=~s/\*$//g;
	   $seq=$tmp{$it,"seq"}; }
	
    $#tmp=0;			# save memory
    undef %tmp;			# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct,\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of pirRdMul

#===============================================================================
sub safRd {
    my   ($ra_fileIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   safRd                       reads SAF format
#       in:                     $ra_fileIn
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       out:                    ($Lok,$msg,$tmp{}) with:
#       out:                    $tmp{"NROWS"}  number of alignments
#       out:                    $tmp{"id", $it} name for $it
#       out:                    $tmp{"seq",$it} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="safRd";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    $LverbLoc=0;

    $ctBlocks=$ctRd=$#nameLoc=0;  
    undef %nameInBlock; 
    undef %tmp;			# --------------------------------------------------
				# read file
				# --------------------------------------------------
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
				# ignore lines with numbers, blanks, points only
	$tmp=$_; $tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1);

	$line=~s/^\s*|\s*$//g;	# purge leading blanks
				# ------------------------------
				# names
	$name=$line; $name=~s/^([^\s\t]+)[\s\t]+.*$/$1/;
				# maximal length: 14 characters (because of MSF2Hssp)
	$name=substr($name,1,14);
				# ------------------------------
				# sequences
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
	print "--- $sbrName: name=$name, seq=$seq,\n" if ($LverbLoc);
				# ------------------------------
				# guide sequence: determine length
				# NOTE: no 'left-outs' allowed here
				# ------------------------------
	$nameFirst=$name        if ($#nameLoc==0);	# detect first name
	if ($name eq "$nameFirst"){
	    ++$ctBlocks;	# count blocks
	    undef %nameInBlock;
	    if ($ctBlocks == 1){
		$lenFirstBeforeThis=0;}
	    else {
		$lenFirstBeforeThis=length($tmp{"seq","1"});}

	    if ($ctBlocks>1) {	# manage proteins that did not appear
		$lenLoc=length($tmp{"seq","1"});
		foreach $itTmp (1..$#nameLoc){
		    $tmp{"seq",$itTmp}.="." x ($lenLoc-length($tmp{"seq",$itTmp}));}
	    }}
				# ------------------------------
				# ignore 2nd occurence of same name
	next if (defined $nameInBlock{"$name"}); # avoid identical names

				# ------------------------------
				# new name
	if (! defined ($tmp{"$name"})){
	    push(@nameLoc,$name); ++$ctRd;
	    $tmp{"$name"}=$ctRd; $tmp{"id",$ctRd}=$name;
	    print "--- $sbrName: new name=$name,\n"   if ($LverbLoc);

	    if ($ctBlocks>1){	# fill up with dots
		print "--- $sbrName: file up for $name, with :$lenFirstBeforeThis\n" if ($LverbLoc);
		$tmp{"seq",$ctRd}="." x $lenFirstBeforeThis;}
	    else{
		$tmp{"seq",$ctRd}="";}}
				# ------------------------------
				# finally store
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$ptr=$tmp{"$name"};    
	$tmp{"seq","$ptr"}.=$seq;
	$nameInBlock{"$name"}=1; # avoid identical names
    }
				# ------------------------------
				# fill up ends
    $lenLoc=length($tmp{"seq","1"});
    foreach $itTmp (1..$#nameLoc){
	$tmp{"seq",$itTmp}.="." x ($lenLoc-length($tmp{"seq",$itTmp}));}
    $tmp{"NROWS"}=$ctRd;
    $tmp{"names"}=join (',',@nameLoc);  $tmp{"names"}=~s/^,*|,*$//;

    $id=$seq="";
    foreach $ct (1..$ctRd){
	$id.= $nameLoc[$ct]."\n";
	$seq.=$tmp{"seq",$ct}."\n";
    }
    $id=~s/\n$//g;
    $seq=~s/\n$//g;

    $#nameLoc=0;		# slim-is-in
    undef %nameInBlock;		# slim-is-in
    undef %tmp;			# 
    return(1,$id,$seq);
}				# end of safRd

#===============================================================================
sub safWrt {
    local($fileOutLoc,%tmp) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   safWrt                      writing an SAF formatted file of aligned strings
#       in:                     $fileOutLoc       output file
#                                   = "STDOUT"    -> write to screen
#                                   = "txt"       -> write to string
#       in:                     $tmp{"NROWS"}     number of alignments
#       in:                     $tmp{"id", "$it"} name for $it
#       in:                     $tmp{"seq","$it"} sequence for $it
#       in:                     $tmp{"PER_LINE"}  number of res per line (def=50)
#       in:                     $tmp{"HEADER"}    'line1\n,line2\n'..
#                                   with line1=   '# NOTATION ..'
#       out:                    1|0,msg implicit: file
#       err:                    ok-> 1,ok | error -> 0,message
#--------------------------------------------------------------------------------
    $sbrName="lib-br:safWrt"; $fhoutLoc="FHOUT_safWrt";
                                # check input
    return(0,"*** ERROR $sbrName: no acceptable output file ($fileOutLoc) defined\n") 
        if (! defined $fileOutLoc || length($fileOutLoc)<1 || $fileOutLoc !~/\w/);
    return(0,"*** ERROR $sbrName: no input given (or not input{NROWS})\n") 
        if (! defined %tmp || ! %tmp || ! defined $tmp{"NROWS"} );
    return(0,"*** ERROR $sbrName: tmp{NROWS} < 1\n") 
        if ($tmp{"NROWS"} < 1);
    $tmp{"PER_LINE"}=50         if (! defined $tmp{"PER_LINE"});
    $fhoutLoc="STDOUT"          if ($fileOutLoc eq "STDOUT");
				# ------------------------------
				# write header
				# ------------------------------
    $prtloc= "# SAF (Simple Alignment Format)\n"."\# \n";
    $prtloc.=$tmp{"HEADER"}     if (defined $tmp{"HEADER"});
    
				# ------------------------------
				# write data into file
				# ------------------------------
    for($itres=1; $itres<=length($tmp{"seq","1"}); $itres+=$tmp{"PER_LINE"}){
	foreach $itpair (1..$tmp{"NROWS"}){
	    $prtloc.=
		sprintf("%-20s",$tmp{"id","$itpair"});
				# chunks of $tmp{"PER_LINE"}
	    $chunkEnd=$itres + ($tmp{"PER_LINE"} - 1);
	    foreach $itchunk ($itres .. $chunkEnd){
		last if (length($tmp{"seq","$itpair"}) < $itchunk);
		
		$prtloc.=
		    substr($tmp{"seq","$itpair"},$itchunk,1);
				# add blank every 10
		$prtloc.=
		    " " 
			if ($itchunk != $itres && 
			    (int($itchunk/10)==($itchunk/10)));
	    }
	    $prtloc.=
		"\n";
	}
	$prtloc.=
	    "\n";
    }
    $prtloc.=
	"\n";
    $#nameLoc=$#stringLoc=0;	# save space

                                # ------------------------------
                                # open new file
    if ($fhoutLoc ne "STDOUT" &&
	$fhoutLoc ne "txt") {
	&open_file("$fhoutLoc",">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); }
    if ($fhoutLoc ne "txt"){
	print $fhoutLoc $prtloc;
	$prtloc="";
	return(1,"ok $sbrName") if ($fhoutLoc eq "STDOUT");
	close($fhoutLoc);
	return(0,"*** ERROR $sbrName: failed to write file $fileOutLoc\n") 
	    if (! -e $fileOutLoc);
	return(1,"ok $sbrName");}

    return(1,"string empty??\n".$prtloc) if (length($prtloc)<10);
    return(1,$prtloc);
}				# end of safWrt

#===============================================================================
sub swissRdSeq {
    my   ($ra_fileIn) = @_ ;
    local($sbrName,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#       in:                     $ra_fileIn
#       out:                    (1,name,sequence in one string)
#-------------------------------------------------------------------------------
    $sbrName="swissRdSeq";
    return(0,"*** ERROR $sbrName: no file input") 
	if (! defined $ra_fileIn);

    $seq="";
    foreach $it (1 .. $#{$ra_fileIn}) {
	$_=$ra_fileIn->[$it];
	$_=~s/\n//g;
	if ($_=~/^ID\s+(\S*)\s*.*$/){
	    $id=$1;}
	last if ($_=~/^\/\//);
	next if ($_=~/^[A-Z]/);
	$seq.="$_";}
    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of swissRdSeq

1;
