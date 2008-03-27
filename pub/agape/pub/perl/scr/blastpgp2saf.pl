#! /usr/bin/perl

$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
if ($#ARGV<0){ print "\n";
               print "use: $scrName file.blastpgp file.f file.saf\n";
               exit;
           }                                                             

$fhin= "FHIN";                 
$fhdiagnose= "FHDIAGNOSE"; open($fhdiagnose,">>ERR-diagnostic.tmp");
$fhout= "FHOUT";
$fhquery= "FHQUERY";
$fhout= "FHOUT";

$blstfile= $ARGV[0];     
if (defined $ARGV[1]){
    $queryfile=$ARGV[1];}
else {
    $queryfile=$blstfile;
    $queryfile=~s/\.blast.*$/.f/;
    if (! -e $queryfile){
				# search for it
	$queryfile=~s/^.*\///g;
	$queryfile="/data/derived/hsspFasta/".$queryfile;}
    if (! -e $queryfile){
	print "*** failed finding the corresponding FASTA file!\n";
	system("echo $blstfile >> ERROR-MISSING-FASTA.list");
	exit; }}
if (defined $ARGV[2]){
    $fileout=  $ARGV[2];}
else {
    $fileout=$blstfile;
    $fileout=~s/^.*\/|\.blast.*$//g;
    $fileout.=".saf";}
    

print "$blstfile -> saf  \n";
#------------------- gets the query sequence and its length
undef @query;
open($fhquery,$queryfile) || die "*** failed to open queryFile=$queryfile!\n"; 
while(<$fhquery>){
    next if($_=~/^\n/ || $_=~/\//);
    if ($_=~/^>/){
	$_=~s/^>//;
	@tmp=split(/\s+/,$_);
	$queryName=$tmp[0];
	next;
    }
    $_=~s/\s+//g;
    @tmp=split(//,$_);
    push @query, @tmp;
}
close $fhquery;
$queryLength=$#query+1;
#..........................................................

#------------------- finds number of iterations in blast file
open($fhin,$blstfile) || die "*******on blastfile\n";
$iter=0;
while(<$fhin>){
    if($_=~/^Sequences producing significant/){
	$iter++;
    }
}
close $fhin;
#............................................................

#--------------------------------skips to the last iteration
open($fhin,$blstfile) || die "*******on blastfile\n";
$count=0;
$multiflag="no"; $supermultiflag="no";
while(<$fhin>){
    if($_=~/^Sequences producing significant/){
	$count++;
    }
    if($count==$iter){
	last;
    }
}
#............................................................
undef @alignedNames; undef @alignedseq; undef %sequences; undef %sequences_more;
while(<$fhin>){
    if(($score>1) && ($flag ne "abort")){ $multiflag= "yes"; 
	    for($index=0;$index<=$#{$sequences_more{$id}};$index++){
		${$sequences{$id}}[$index]=${$sequences_more{$id}}[$index]
	    }
        }
   if($_=~/^>/){ 
        $flag="proceede";
	$counter++; $score=0;
	undef @seq; 
	for($it=0;$it<=$queryLength-1;$it++){
	    $seq[$it]=".";
	}
	$_=~s/^>//; 
	@tmp=split(/\s+/,$_);
        $tmpname=$tmp[0];
	if($tmpname=~/swiss|trembl/){
	    @tmp=split(/\|/,$tmpname);
	    $id=$tmp[2];
	}
	else {$id=$tmp[0];}
	push @alignedseq, $id;
	next;
    }
    if($_=~/Score =/){
        $score++;
    if(($score>2) && ($flag ne "abort")){ $supermultiflag="yes"; 
	    for($index=0;$index<=$#{$sequences_more{$id}};$index++){
		${$sequences{$id}}[$index]=${$sequences_more{$id}}[$index]
	    }
        }
    }

    if($_=~/^Query:/){
	undef @query_line;
	@tmp=split(/\s+/,$_); 	       
	$beg=$tmp[1]-1; $end=$tmp[3]-1;
	@query_line=split(//,$tmp[2]);
    }
    if(($_=~/^Sbjct:/) && ($score==1)){
	undef @aligned; undef @sbjct_line;
	@tmp=split(/\s+/,$_); 
	@sbjct_line =split(//,$tmp[2]);
	for($index=0;$index<=$#sbjct_line;$index++){
	    if($query_line[$index]!~/-/){
		push @aligned, $sbjct_line[$index];
	    }
	}
	@seq[$beg .. $end]=@aligned;
	foreach $elem (@seq){
	    if(($elem ne ".") && ($elem!~/[a-z_A-Z]/)){
		$elem=".";
	    }
	}
	$sequences{$id}=[ @seq ]; 
    }
    if(($score>1) && ($_=~/^Query:/)){
	@tmp=split(/\s+/,$_);		       
	$beg=$tmp[1]-1; $end=$tmp[3]-1;
	Local: foreach $entry (@{$sequences{$id}}[$beg .. $end]){
	    if($entry=~/[a-z_A-Z]/){ $flag="abort"; last Local;}
	}
    }
    if(($score>1) && ($flag ne "abort") && ($_=~/^Sbjct:/)){
	undef @aligned; undef @sbjct_line;
	@tmp=split(/\s+/,$_);
	@sbjct_line =split(//,$tmp[2]);
	for($index=0;$index<=$#sbjct_line;$index++){
	    if($query_line[$index]!~/-/){
		push @aligned, $sbjct_line[$index];
	    }
	}
	@seq[$beg .. $end]=@aligned;
	foreach $elem (@seq){
	    if(($elem ne ".") && ($elem!~/[a-z_A-Z]/)){
		$elem=".";
	    }
	}
	$sequences_more{$id}=[ @seq ]; 
    }
}
#--------------------------preparation and printing out the resulting file
 
  print "******* ",$blstfile,"  multi   ", $multiflag,"    supermulti,", $supermultiflag,"\n";
  print $fhdiagnose $blstfile,"\t", $multiflag,"\t" ,$supermultiflag,"\n";



foreach $it (@alignedseq){
    if($it ne $queryName){push @alignedNames, $it; }
}
$pages=int $queryLength/50;
if ($queryLength%50 != 0){$pages++;}

open($fhout,">$fileout");
print $fhout "# SAF (Simple Alignment Format)\n";
print $fhout "#\n";
$nameField=0;
foreach $key (@alignedNames){
    @tmp=split(//,$key);
    if ($#tmp+2>$nameField){$nameField=$#tmp+2;}
}

for($it=1;$it<=$pages;$it++){
    $beg=($it-1)*50; $end=$it*50-1;
    printf $fhout "%-${nameField}.${nameField}s ", $queryName;
    for($index=0;$index<50;$index=$index+10){
	$first=$beg+$index; $last=$first+9;
	print $fhout  @query[$first .. $last]," ";
    }
    print $fhout  "\n";
    foreach $key (@alignedNames){
	printf $fhout "%-${nameField}.${nameField}s ", $key;
	for($index=0;$index<50;$index=$index+10){
	   $first=$beg+$index; $last=$first+9; 
	    print $fhout @{ $sequences{$key}}[$first .. $last]," ";
	}
	print$fhout  "\n";
    }
    print $fhout "\n";
}
close $fhout;



