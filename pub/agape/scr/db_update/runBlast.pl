#! /usr/bin/perl -w

($mfasta,@l_args)=@ARGV;

#initial settings
$dbg=0;
$doBlast    =1;
$doPsiBlast =0;

$useFixedDbLen =0;
$usePsiSpace   =0;
#$train_db     ="/data/blast/big_98";
$train_db     ="/data/blast/big_80";
$DbLen2use     =313269626;

$formatdb_exe ="/usr/pub/molbio/bin/formatdb";
$blastpgp_exe ="/usr/pub/molbio/bin/blastpgp";
$blastall_exe ="/usr/pub/molbio/bin/blastall";

foreach (@l_args){
    if(/^psi$/i)  { $doPsiBlast=1; $doBlast=0; }
    elsif(/^blast$/i) { $doPsiBlast=0; $doBlast=1; }
    elsif(/^fixdblen/i) { $useFixedDbLen=1; $usePsiSpace=0; }
    elsif(/^psidblen/i) { $useFixedDbLen=0; $usePsiSpace=1; }
}
if($doBlast && $usePsiSpace){
    die "conflinct in arguments, stopped";
}

$fileAliNumbOut=$mfasta; $fileAliNumbOut=~s/^.*\///;
$fileAliNumbOut=~s/\..*$/\.psi-ali-numbs/;


if($useFixedDbLen){ print "INFO: using fixed db len=$DbLen2use\n"; }


#split mfasta
$ctFasta=0; $vertBarFlag=0;
open(FHIN,$mfasta) || 
    die "failed to open mfasta=$mfasta, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/); 
    if(/^>(\S*)/){
	$id=$1; 
	die "id not undrstood in line:\n$_\nstopped"
	    if($id !~ /\S/);
	if($id=~/\|/){ $vertBarFlag=1; }
	$id=~s/^.*\|//; $fasta=$id.".f";
	$h_id2fasta{$id}=$fasta;
	$ctFasta++;
	open(FHOUT,">".$fasta) || 
	    die "failed to open file=$fasta for writing, stopped";
	print FHOUT ">".$id."\n";
    }else{ print FHOUT $_; }
}
close FHOUT;
print "WARNING: found vertical bar in sequence ids !!!\n"
    if($vertBarFlag);


$cmd="$formatdb_exe -i $mfasta -p T";
system($cmd)==0 || 
    die "failed on $cmd, stopped";
@l_db_files=($mfasta.".phr",$mfasta.".pin",$mfasta.".psq");

if($doPsiBlast){
    open(FHOUTALINUMBS,">".$fileAliNumbOut) ||
	die "failed to open fileAliNumbOut=$fileAliNumbOut for output, stopped";
}

foreach $id (sort keys %h_id2fasta){
    $fasta=$h_id2fasta{$id};
    $blastOut=$id.".blastm9";
    if($doBlast){
	if($useFixedDbLen){
	    $cmd="$blastall_exe -p blastp -i $fasta -d $mfasta -e 100 -v $ctFasta -b $ctFasta -o $blastOut -m 9 -F F -z $DbLen2use -a 2";
	}else{ $cmd="$blastall_exe -p blastp -i $fasta -d $mfasta -e 100 -v $ctFasta -b $ctFasta -o $blastOut -m 9 -F F -a 2"; }
	print "$cmd\n" if($dbg);
	system($cmd)==0 || die "failed on $cmd, stopped";
    }elsif($doPsiBlast){
	$check=$id.".check";
	$blastOutTmp=$id.".blastpgpIter";

	$cmd1="$blastpgp_exe -i $fasta -d $train_db -j 2 -h 0.1 -e 0.1 -v 5000 -b 5000 -o $blastOutTmp -C $check -F T -a 2";
	if($useFixedDbLen){
	    $cmd1.=" -z $DbLen2use";   
	}
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
	print FHOUTALINUMBS $id."\t".$psiAliCt."\n";

	#system("gzip -f $blastOutTmp");
	if(! $dbg){ unlink $blastOutTmp; }
	
	$cmd2="$blastpgp_exe -i $fasta -d $mfasta -R $check -e 100 -v $ctFasta -b $ctFasta -o $blastOut -m 9 -F F";
	if($usePsiSpace){
	    print "using effective length of database $psiDbLen\n";
	    $cmd2.=" -z $psiDbLen";
	}elsif($useFixedDbLen){
	    $cmd2.=" -z $DbLen2use";
	}
	print "$cmd2\n" if($dbg);
	system($cmd2)==0 || die "failed on $cmd2, stopped";
    }else{ die "ERROR unknown action to be taken, stopped"; }
    system("gzip -f $blastOut");
}

if(! $dbg){
    foreach $id (sort keys %h_id2fasta){ 
	$fasta=$h_id2fasta{$id};
	unlink ($fasta);
    }
    foreach $file (@l_db_files){
	unlink ($file);
    }
}
