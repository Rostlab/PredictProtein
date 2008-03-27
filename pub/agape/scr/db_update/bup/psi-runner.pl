#! /usr/bin/perl -w

($fileList)=@ARGV;

open(FHIN,$fileList) ||
    die "failed to open fileList=$fileList, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    ($it)=/^(\S+)/;
    $h_fastas{$it}=1;
}
close FHIN;
$blastpgp_exe ="/usr/pub/molbio/bin/blastpgp";
$train_db     ="/home/dudek/server/pub/agape/mat/big_80";

foreach $fasta (sort keys %h_fastas){
    $id=$fasta; $id=~s/^.*\///; $id=~s/\..*$//;
    $blastOutTmp=$id.".blastpgpIterTmp";
    $check=$id.".check";
    $mat  =$id.".mat";
    $dbSizeFile=$id.".dbsize_dat";

    #$cmd1="$blastpgp_exe -i $fasta -d $train_db -j 3 -h 0.1 -e 0.1 -v 5000 -b 5000 -o $blastOutTmp -C $check -Q $mat -F T -a 1";
     
    $cmd1="$blastpgp_exe -i $fasta -d $train_db -j 1 -h 0.1 -e 0.1 -v 50 -b 50 -o $blastOutTmp -F T -a 1";
  
    print "$cmd1\n" if($dbg);
    system($cmd1)==0 || die "failed on $cmd1, stopped";
    
    $psiAliCt=0;
    open(FHTMP,$blastOutTmp) || die "failed to open blastOutTmp=$blastOutTmp, stopped";
    while(<FHTMP>){
	if(/effective length of database:\s*(\S+)/){
	    print $_ if($dbg);
	    $psiDbLen=$1;
	    $psiDbLen=~s/\,//g;
	}
	elsif(/^Searching/){ $psiAliCt=0; }
	elsif(/^>/){ $psiAliCt++; }
    }
    close FHTMP;
    open(FHOUTALINUMBS,">".$dbSizeFile) ||
	die "error failed to open dbSizeFile=$dbSizeFile for writing, stopped";
    print FHOUTALINUMBS $id."\t".$psiDbLen."\t".$psiAliCt."\n";
    close FHOUTALINUMBS;

    #system("gzip -f $blastOutTmp");
    #if(! $dbg){ unlink $blastOutTmp; }
}
