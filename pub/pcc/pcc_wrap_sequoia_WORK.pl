#! /usr/bin/perl -w


###  pcc_wrap.pl is the main script for the PredictCellCycle Server  ###
###  http://cubic.bioc.columbia.edu/services/PredictCellCycle/
###  http://cubic.bioc.columbia.edu/pp/submit_pcc.html
###  it has predictprotein as it's "engine". 
###  The script is on sequoia in /home/ppuser/server/pub/pcc/
###  It writes files to it's own directory and uses files (3) which
###  are mounted on sequoia locally /home/ppuser/server/pub/pcc/data/cc_control4
###  /home/ppuser/server/pub/pcc/data/cellcycledb.txt and remotely /data/blast/big
###  Kazimierz O. Wrzeszczynski 
###  Columbia University - Dept. of Biochemistry and Molecular Biophysics
###  2/15/04                                                         ###


###########RUN PSI-BLAST on submission fasta sequence

($Fasta)=@ARGV;                     #input comes from the submission form and is a single fasta fi

$BlastTraindb="/data/blast/big";    #psiblast iteration database

####sequoia
#$BlastFinaldb="/home/ppuser/server/pub/pcc/data/cc_control4"; #PredictCellCycle Trusted Set
#$CellCycleDB="/home/ppuser/server/pub/pcc/data/cellcycledb.txt";
#######

###local
$BlastFinaldb="/misc/freesia/orchid_copy/databases/cc_control4";
$CellCycleDB="/misc/freesia/orchid_copy/databases/cellcycledb.txt";
#####


open(FHOUT2, ">>pcc_log_file");
($day, $month, $year)=(localtime)[3,4,5];
printf FHOUT2 ("###%02d-%02d-%04d\n", $month+1, $day, $year+1900);
print FHOUT2 "$Fasta\n";
    $id=$Fasta;
    $id=~s/^.*\/|\..*$//g;
    $id=~s/.fasta$|.f$//;
    $id=~s/pred_//;
    #$FileCheck="/home/ppuser/server/pub/pcc/tmp/".$id.".check";        #binary profile file
    $FileCheck="/misc/freesia/orchid_copy/cell_cycle_final/cc_control4/tmp_db/".$id.".check"; 
    $FileOut="/misc/freesia/orchid_copy/cell_cycle_final/cc_control4/tmp_db/".$id.".psiblast";
    #$FileOut="/home/ppuser/server/pub/pcc/tmp/".$id.".psiblast";       #file name with final alignments used in second sequence analysis
    $FileHolder ="/misc/freesia/orchid_copy/cell_cycle_final/cc_control4/tmp_db/".$id.".holder.tmp";
    $cmdTrain="/usr/pub/molbio/blast/blastpgp -i $Fasta -d $BlastTraindb -v 10000 -j 3 -h 0.001 -e 0.001 -C $FileCheck -o $FileHolder";          #first blast run with 2 iterations 1)Blast using Blosum62 and then 2) using Blast with the psi profiles created.
    $Ufile1=$FileCheck;
    $Ufile2=$FileHolder;
    $Ufile3= $FileOut;
    $Lok=system($cmdTrain);         #if system command fails $Lok gets defined with value greater than 1.
    if($Lok){                       #so if $Lok exists then do error handling lines.
	print FHERR "$Fasta : ERROR psiblast training failed\n";
	print "$Fasta : ERROR psiblast training failed\n";
	#unlink ($FileCheck,"$id.holder.tmp");  #removes files from dir
	next;
    }
    $cmdFinal="/usr/pub/molbio/blast/blastpgp -i $Fasta -d $BlastFinaldb -v 10000 -b 10000 -e 1000 -R $FileCheck -o $FileOut -m 8";                 #final blast run is for final desired dataset using a profile matrix defined by -R.
    $m8File=$FileOut;
    $Lok=system($cmdFinal);
    if($Lok){ 
	print FHERR "$Fasta : ERROR psiblast final failed\n";
	print "$Fasta : ERROR psiblast final failed\n";
	$FileOut=$m8File;
        #unlink $FileOut;
	next;
    }
#######Works

#######now do m8 on output.
(system "chmod 755 /misc/freesia/orchid_copy/cell_cycle_final/cc_control4/tmp_db/*");
#(system "chmod 755 /home/ppuser/server/pub/pcc/tmp/*");
#print "***here $m8File ****\n";
    $tmp=$m8File; 
    $tmp=~s/.*\///; 
    $tmp=~s/\..*$//;
    #$FileOut="/home/ppuser/server/pub/pcc/tmp/".$tmp."_NEWHSSP.rdb";
    $FileOut ="/misc/freesia/orchid_copy/cell_cycle_final/cc_control4/tmp_db/".$tmp."_NEWHSSP.rdb";
    $Ufile4=$FileOut;

$par{'MinLali'}         =12;       #minimum alignment length to be considered
$par{'MinHsspDistRep'}  =-1000;    #minimum hssp distance to report 
$par{'MinIdeRep'}       =-10;      #minimum pid to report 

$HsspThresh =$par{'MinHsspDistRep'};
$IDEThresh  =$par{'MinIdeRep'};
open(FHOUT, ">".$FileOut) ||   
    die "ERROR, failed to open FileOut=$FileOut, stopped";

#FILE: foreach $m8File (@m8Files){
    undef %h_Results;
    open(FHIN,$m8File) || die "did not open m8File=$m8File<<, stopped";
    while(<FHIN>){
	#print;
	next if(/^\s+$/);
	s/^\s+|\s+$//g;
	#print $_;
	@data=split(/\s+/, $_);
	if($#data != 11){ print  "wrong format of m8File=$m8File, continue..."; next FILE; }  #check format
	($Query,$Subject,$ideWgap,$lenWgap,$mismatchNo,$gapOpenNo,$qstart,$qend,$sstart,$send,$Escore,$Bitscore)
	    =@data;
	$Query = $id; #changed since m8 in pred prot gives something else.
	$Subject=~s/.*\|//; $Query=~s/.*\|//; $Subject=~s/\w+://;
	$Subject=~tr[A-Z][a-z]; $Query=~tr[A-Z][a-z];

	undef $gapOpenNo; undef $psim; 
	$ideNo=sprintf "%3.0f", $lenWgap * $ideWgap/100;
	$aliLen=$ideNo + $mismatchNo;
	$gapLen=2 * $lenWgap -($qend-$qstart +1 + $send-$sstart +1);
	$aliLenCheck=$lenWgap -$gapLen;
	die "alignment lengths in file=$m8File $Query $Subject calculated in independent ways not eqal: $aliLen vs $aliLenCheck in line:\n$_\n, stopped" 
	    if($aliLen != $aliLenCheck);
	$pide=$ideNo/$aliLen * 100;
	$psim=$mismatchNo/$aliLen * 100;
	
     
	#next if($Subject eq $Query);
	if($aliLen < $par{'MinLali'} ){ #print "too short $aliLen vs $par{MinLali}\n"; 
                                        next;}
	#($pid,$msg)=&getDistanceNewCurveIde($LEN);
	#if(!$pid) {print "\nERROR getDistanceNewCurveIde failed for m8File=$m8File Query=$Query Subject=$Subject with message=$msg...continue..."; next File;}
	$HsspDist=&hssp_dist($pide,$aliLen);
  
	if($HsspDist < $par{'MinHsspDistRep'} ){print "below threshold\n"; next;}
	$EThreshFlag=$HsspThreshFlag=$IDEThreshFlag=1;
	if( defined $HsspThresh ){
	    if( $HsspDist >= $HsspThresh )   { $HsspThreshFlag=1; }
	}
	else                                 { $HsspThreshFlag=1; }
	
	if( defined $EThresh ){
	    if( $Escore <= $EThresh )        { $EThreshFlag=1; }
	}
	else                                 { $EThreshFlag=1; }
	
	if( defined $IDEThresh ){
	    if( $pide >= $IDEThresh )        { $IDEThreshFlag=1; }
	}
	else                                 { $IDEThreshFlag=1; }

	if( $EThreshFlag && $HsspThreshFlag && $IDEThreshFlag ){
	    if(defined $h_Results{$Query}{$Subject} ){ 
		#print "WARNING: alignment $Query and $Subject already found\n"; 
		next;
	    }
	    $h_Results{$Query}{$Subject}{'score'}=$Escore;
	    $HsspDist   =sprintf "%6.1f", $HsspDist;
	    $Escore     =sprintf "%3.1e", $Escore;
	    $Bitscore   =sprintf "%6.1f", $Bitscore;
	    $pide       =sprintf "%6.1f", $pide;
	    #print "got here!!!!!!!!!!!!!!!!!!!!!!!!!\n";
	    $h_Results{$Query}{$Subject}{'data'}=$Query."\t".$Subject."\t".$aliLen."\t".$pide."\t".$HsspDist."\t".$Escore."\t".$Bitscore."\n";
	}#else{ #print "$Subject not considered\n"; }
	 #print "Query: $Query\n";
    }
    close FHIN;
    @SortedIds=sort { $h_Results{$Query}{$a}{'score'} <=> $h_Results{$Query}{$b}{'score'} } keys %{ $h_Results{$Query} };
    #print "Query check: $Query\n";
    #@SortedIds=sort keys %{ $h_Results{$Query} };
    #print "SortedIds: @SortedIds\n"; 
    foreach $Subject (@SortedIds){
	if($h_Results{$Query}{$Subject}{'data'} !~ /\n$/){$h_Results{$Query}{$Subject}{'data'}.="\n"; }
	print FHOUT $h_Results{$Query}{$Subject}{'data'};
	$BlastOutHSSP=$FileOut;
	#unlink $FileOut;
    }				
    undef %h_Results;

close FHOUT;


##############Works, now grab id's from _NEWHSSP file

#cge1_human      cge1_human      410      100.0    80.5  1.0e-134         471.3

(system "chmod 755 /misc/freesia/orchid_copy/cell_cycle_final/cc_control4/tmp_db/*");
#(system "chmod 755 *");
#(system "chmod 755 /home/ppuser/server/pub/pcc/tmp/*");

$linecount=0; undef %seen;
open (FHFILEHSSP, $BlastOutHSSP) or die "Error, could not open file $BlastOutHSSP\n";
#$read=0;
while(<FHFILEHSSP>) {if ($linecount lt 6) {$linecount++;
  	if ($_ =~m/^(\S*)\s*(\S*)\s*\w*\s*(\w*.\w*)\s*(-{0,1}\w*.\w*)\s*(\w.\w*e{0,1}.?\w*)\s*\w*.\w*/){    
            $qid = $1; 
	    $ccid = $2;
	    $pide= $3;
	    $hssp = $4;
	    $Evalue =$5;
	    $ccid =~ tr/A-Z/a-z/;
	    $qid =~ s/\n//;
	    $ccid =~ s/\n//;
	    $ccid =~ s/swiss\S\w*\S//;
	    $hssp =~ s/\n//;
	    $Evalue =~ s/\n//;
	    $pide =~ s/\n//;
	    $seen{$qid}{$ccid}=$hssp;
           #print $qid,"  \t",$ccid," \t",$lali," \t",$pide,"  \t",$hssp,"  \t",$Evalue,"\n";
          }
	 }
        }
close FHFILEHSSP; 

print "\n";

foreach $qid1 (keys %seen) {
@sorthssp =sort { $seen{$qid1}{$b} <=> $seen{$qid1}{$a} } keys %{ $seen{$qid1} };
}

#print "PredictCellCyle Output with Sort
foreach $qid1 (keys %seen) {
print "\n\n\n###########  PredictCellCycle Output for Query ID: $qid1   ###########\n";
print "#output format:\t>Query ID\tCellCycleDB Homologue\tHSSP-distance Value(HVAL)\tConfidence Level\n";
foreach $ccid1 (@sorthssp){      
      if ($seen{$qid1}{$ccid1} >= 40) {$percaccu = "98% Accuracy"; }
      elsif ($seen{$qid1}{$ccid1} << 40  && $seen{$qid1}{$ccid1} >= 25) {$percaccu = "90% Accuracy";}
      elsif ($seen{$qid1}{$ccid1} << 25  && $seen{$qid1}{$ccid1} >= 15) {$percaccu = "65% Accuracy";}
      elsif ($seen{$qid1}{$ccid1} << 15  && $seen{$qid1}{$ccid1} >= 0) {$percaccu =  "55% Accuracy";}
      else  {$percaccu = "HVAL below reliable inference for cell cycle control function.";}
      $seenperc{$qid1}{$ccid1}{$seen{$qid1}{$ccid1}}=">$qid1\t\t$ccid1  \t\t$seen{$qid1}{$ccid1}\t\t$percaccu\n";
      print $seenperc{$qid1}{$ccid1}{$seen{$qid1}{$ccid1}};
      print FHOUT2 $seenperc{$qid1}{$ccid1}{$seen{$qid1}{$ccid1}};
  }}



#print "PredictCellCyle Output
#foreach $qid1 (keys %seen) {
#print "\n\n\n###########  PredictCellCycle Output for Query ID: $qid1   ###########\n";
#print "#output format:\t>Query ID\tCellCycleDB Homologue\tHSSP-distance Value(HVAL)\tConfidence Level\n";
#    foreach $ccid1 (keys %{$seen{$qid1}}){
#      if ($seen{$qid1}{$ccid1} >= 40) {$percaccu = "98% Accuracy"; }
#      elsif ($seen{$qid1}{$ccid1} << 40  && $seen{$qid1}{$ccid1} >= 25) {$percaccu = "90% Accuracy";}
#      elsif ($seen{$qid1}{$ccid1} << 25  && $seen{$qid1}{$ccid1} >= 15) {$percaccu = "65% Accuracy";}
#      elsif ($seen{$qid1}{$ccid1} << 15  && $seen{$qid1}{$ccid1} >= 0) {$percaccu =  "55% Accuracy";}
#      else  {$percaccu = "HVAL below reliable inference for cell cycle control function.";}
#      $seenperc{$qid1}{$ccid1}{$seen{$qid1}{$ccid1}}=">$qid1\t\t$ccid1  \t\t$seen{$qid1}{$ccid1}\t\t$percaccu\n";
      #@sortperc =sort { $seenperc{$qid1}{$ccid}{$b} <=> $seenperc{$qid1}{$ccid}{$a} } keys (%{$seenperc{$qid1}{$ccid1}});
#      print $seenperc{$qid1}{$ccid1}{$seen{$qid1}{$ccid1}};
#  }
#}




#print CellCYcleDB Ouput
foreach $qid1 (keys %seen) { 
print "\n\n\n\n###########   CellCycleDB Output for Query ID: $qid1   ###########\n";
print "#output format: >>Query ID\tCellCycleDB Homologue\t>CellCycleDB entry//\n";
LINE: foreach $ccid1 (@sorthssp){  
open (FHFILECCDB, $CellCycleDB) or die "Error, could not open file $CellCycleDB\n";
$readccdb=0;
while(<FHFILECCDB>) {
if ($_ =~ m/^>$ccid1/){ 
$readccdb = 1;
print ">>$qid1\t$ccid1\n";}
if ($readccdb eq 1){print $_;
if ($_ =~ m/^\/\//i){next LINE; $readccdb=0;}
}#ends if readccdb=1
}#ends while FH
if ($readccdb==0){print "Homologue not part of CellCycleDB trusted set";} 
} #ends foreach ccid1
} #ends foreach qid1
close FHFILECCDB;

(system "rm $Ufile1"); #removes check file
(system "rm $Ufile2"); #removes holder.tmp file
(system "rm $Ufile3"); #removes .psiblast file
(system "rm $Ufile4"); #removes NewHSSP.rdb fil3
print FHOUT2 "###end###\n";
#http://walnut.bioc.columbia.edu/srs71bin/cgi-bin/wgetz?-id+4ftgt1N56i9+-e+[CELLCYCLEDB:'p53_rat']+-qnum+1+-enum+1
close FHOUT2;


#=========================================================================
# calculates HSSP-Distance using the formula from Burkhard's
# HSSP-Paper 1999
sub hssp_dist {
    my $sbr="hssp_dist";
    my($pi) = shift;
    my($len) = shift;

    die "$sbr: args not defined, stopped"
	if(! defined $pi || ! defined $len);
    if ($len <= 11) {
        return -999;
    }
    elsif ($len > 450) {
        return $pi - 19.5;
    }
    else {
        my($exp) = -0.32 * (1 + exp(- $len / 1000));
        return $pi - (480 * ($len ** $exp));
    }
}
#=====================================================================
#==============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

