#! /usr/bin/perl -w
# search program for NLS motifs

# inputs: 1) file with prot list
#         2) file with locations
#         3) NLS motifs seperated by semi colon
#         3) Sequence Format: fasta, rdbPhd,Swissprot.

if ($#ARGV<0 || $ARGV[0]=~ /[h|?]/){
    print "Given set of proteins, searches for NLS motifs\n";
    print "use: script  prot_list  File_NLS_motifs file_with_loc  file_format=xxx   loc_of_rdbPhd_or_fasta_files\n";
    print "rdbPhd or fasta format allowed\n";
    print "Interactive mode also allowed\n";
    print "Usage for interactive mode:\n";
    print "use: script mode=1 'NLS_motifs'\n";
    print "NLS_motifs are seperated by semi-colon.\n";
    print "Script scans database of proteins of known localizations for motifs\n";
    print "Variable res [AV], any res x or x{0,10} as in perl\n";
    print "use: script mode=2 File_with_Prot_seq_fasta\n";
    exit;}
# Out directories and jobId's defined here for web version.
# the defaults
$dirOut= "";
$jobId= "";
#  get it from script input
foreach $x (0 .. $#ARGV) {
  if($ARGV[$x]=~ /out/){
    $dirOut= $ARGV[$x +1];
    $jobId= $ARGV[$x+2];
  }
}
&iniDef();

open($fhout,">".$file_out) || die "*** failed opening prot_file_with_motif = $file_out\n";

print $fhout "# File with Id's and Loc of proteins containing NLS motifs\n";
print $fhout "# prot_id\tLoc\tmotif\tpos\n";

open($fhout1,">".$file_out1)|| die "*** failed opening Stat file $file_out1\n";
print $fhout1 "# Statistics for various motifs\n";
print $fhout1 "#Motif_Name\tNo_Found\t%oE\t%oX\n";

if($ARGV[0]=~ /mode/) {
    @tmp=split(/=/,$ARGV[0]);
    $tmp[1]=~s /\s//g;
    if($tmp[1] == 1){
      $inMotif= $ARGV[1]; # the input motif
      $inMotif=~tr /X/x/;
      $id= "motif";
      $res= $inMotif;
      &motifRd();
      &motifManager();
      &findMotif();
      if( $flag>0){ # implies motif found in NLS db
 # prnt out MotifDat if motif found in NLS db.
	open($fhout2,">".$file_out2)|| die"***failed opening MotifDat file $file_out2\n";
	print $fhout2 "#File contains Motif stat from db for NLS found in unk sequence\n";
	print $fhout2 "#Motif_Name\tNo_Found\t%oE\t%oX\tProtein List\n";
	foreach $prot (keys %foundMotif ){
	  foreach $nls (keys %{ $foundMotif{$prot} } ){
	    print $fhout2 "$prot\t$foundMotif{$prot}{$nls}\n";
	  }
	}
	exit;
      }
      else {
	#------------------------------------------------------------
	# scan protein db if motif not found in NLS db.
	# remove all file produced during prior run
#-------------- removes and undefines vars initialized in prev chunk--------------
	system("rm -f  $file_out1 $file_out2 ");
	&iniDef();
#--------------------end of uninitialization----------------------------
	open($fhout,">".$file_out) || die "*** failed opening prot_file_with_motif = $file_out\n";
	print $fhout "# File with Id's and Loc of proteins containing NLS motifs\n";
	print $fhout "# prot_id\tLoc\tmotif\tpos\n";
	  
	open($fhout1,">".$file_out1)|| die "*** failed opening Stat file $file_out1\n";
	print $fhout1 "# Statistics for various motifs\n";
	print $fhout1 "#Motif_Name\tNo_Found\t%oE\t%oX\n";
	$tmp_motif= $inMotif; # var contains the motif . used for maniputlations

	print STDOUT "$tmp_motif\n";
# ------------------- additions to call subroutine which incorporates unix egrep to speed up motif search----------
	
	
	$file_id= $par{"protList"};
	$fileLoci= $par{"lociList"};
	$file_fasta= $par{"protSeq"}; # contains flat file of all prot sequences
	&findLoci(); 
	
	$tmp_motif=~s /x/\[A-Z\]/g;
	print "$tmp_motif\n";
	$tmp_motif=~s /\?//g;
	&egrepManager();
	&statManager();
	exit;
      }
	
    }
    elsif($tmp[1] == 2){
      $inSeq= $ARGV[1];# protein sequence or file with sequences in fasta format.
      &motifRd();
      &motifManager();
      $resDef= "no"; # No sequence Read.
      $file_seq= $dirOut.$inSeq.$jobId;# route to file.
      
      if( -e $file_seq) {
	
	open($fhin,$file_seq) || die"*** Protein Sequence file $file_seq not readable\n";
	while(<$fhin>){
	  if($_=~ /^>/){
	    if($resDef eq "yes") {
	      # processing of previously read seq done here.
	      &findMotif();
	    }
	    $res= ""; # empty to start rd new seq.
	    $resDef="no"; # get ready for new seq.
	    chomp($_);
	    if($_=~ /\|/){
	      m/\|(\w+)\s/;
	      $id=$1;
	      $id=~tr /[A-Z]/[a-z]/;
	    }
	    else{
	      m/>(\w*)$/;
	      $id=$1;
	      
	    }
	  }
	  else{
		# read residues.
	    s /\s//g;
	    $res=$res.$_;
	    $resDef="yes";
	  }
	  
	}
	if($resDef eq "yes") {
	  # processing of LAST seq done here.
	  &findMotif();
	}
	exit;
      }
      else {
	$id= "inputSequence";
	$res= $inSeq;
	&findMotif();
	# prnt out MotifDat
	open($fhout2,">".$file_out2)|| die"***failed opening MotifDat file $file_out2\n";
	print $fhout2 "#File contains Motif stat from db for NLS found in unk sequence\n";
	print $fhout2 "#Motif_Name\tNo_Found\t%oE\t%oX\tProtein List\n";
	foreach $prot (keys %foundMotif ){
	  foreach $nls (keys %{ $foundMotif{$prot} } ){
	    print $fhout2 "$prot\t$foundMotif{$prot}{$nls}\n";
	  }
	}
	exit; # job fini... for this case.
      }
    }
    else {
      print STDOUT "Invalid mode; start again\n";
      exit;
    }
  }
else {
  $file_id= $ARGV[0];
  if (defined $ARGV[1]){
    $fileMotif= $ARGV[1]; # file contining motifs to be scanned.
  }
  &motifRd();
  &motifManager();
  
  if(defined $ARGV[2]){
    $fileLoci =  $ARGV[2];
  }
  else{
    $fileLoci = $par{"lociList"};
  }
  &findLoci();
  
  if(defined $ARGV[3]) {
	$format=  $ARGV[3];# file format: rdbPhd , fasta or SwissProt
      }
  else{
    $format="format=fasta";
  }
  if(defined $ARGV[4]){
    $fileDir=  $ARGV[4];		# location of rdbPhd,fasta or swissprot files.
  }
  
  # determination of format
  @tmp=split(/\=/,$format);
  $file_type= $tmp[1];
  $file_type=~tr/[A-Z]/[a-z]/;
  
}
# end.
if(defined $file_id) {
  open($fhin,$file_id) || die "*** failed opening file_with_swissprot_id's=$file_id\n";
 PROT:
  while(<$fhin>){
    $_=~s /\s//g;
    $id= $_;
    $dbFlag=1; # flag activated when running entire db.
    undef $res;
    &fastaManager();
#----------------------------disabled temproarily----------------
#    if($file_type=~ /rdbphd/){
#      &phdManager();
#    }
#    elsif($file_type=~ /fasta/){
#      &fastaManager();
#    }
#    elsif($file_type=~ /swissprot/){
#      &swissManager();
#    }
 #   else {
 #     print STDOUT "unknown file type; read help\n";
 #   }
    &findMotif();
  }
}
&statManager();
close $fhin;
close $fhout1;
print $fhout "$prot_nls\n";
close $fhout;
exit;
#===============================================================================

sub iniDef {
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------

    $par{"dir"} =  "$ENV{HOME}/server/pub/nls/";
    $par{"motList"}= $par{"dir"}."data/My_NLS_list"; # the default database of Motifs.
     $par{"protList"}= $par{"dir"}."data/prot_list"; # the default list of proteins with known localization.
    $par{"protSeq"}=$par{"dir"}."data/allProt.fasta"; # flat file containing all sequences in format suitable for egrep.
    $par{"lociList"}= $par{"dir"}."data/Loci.dat"; # the file with Localizations.
    $par{"seq"}= "fasta"; # default sequence type.
    $par{"fastaDir"}= "/data/derived/big/splitSwiss/"; # path to fasta files.
    $par{"swissDir"}= "/data/swissprot/current/"; # path to swissprot.
    # hashes used
    undef %op; # observed and predicted nuclear.
    undef %nop; # Not obs but predicted nuclear.
    undef %prot_list; # list of prot containing a given motif.
    undef $dbFlag; # flag activated only when scanning through entire database.
    undef $tmp_motif;
    undef @motif;
    undef @motif_w;
    undef $fileMotif; # given file with Motifs.
    undef $fileLoci;  # file with localizations.
    undef $fileDir;
    # fileHandle declarations
    $fhin=   "FHIN";
    $fhout=  "FHOUT";# fh for FoundNLS
    $fhout1=  "FHOUT1";#fh for Motif_Stat
    $fhout2= "FHOUT2";# fh for MotifDat
    $fhdata= "DATA"; # file handle for reading input
    # Output files.
    $file_out= $dirOut."FoundNLS".$jobId; # file with proteins containing given motif
    $file_out1= $dirOut."Motif_Stat".$jobId;
    $file_out2= $dirOut."MotifDat".$jobId;
}

#===============================================================================

sub motifRd {
#-------------------------------------------------------------------------------
#    motifRd                    read database of Motifs
#-------------------------------------------------------------------------------
    local $fh;
    $fh= "FHIN";
    if(!(defined $fileMotif)) {
	$fileMotif= $par{"motList"}; # use def motif db.
	if(!(defined $dbFlag)){
	$motFlag=1;
      }
    }
    open($fh,$fileMotif) || die"** could not open motifs file $fileMotif\n";
    $i=0;
    undef $tmp_motif;
    while(<$fhin>) {
      $in= $_;
      next if /^(\#|\s)/;
      @tmp=split(/[\s]+/,$_);
      if($motFlag==1 && !(defined $dbFlag) && defined $tmp[0]){# mtoif list is picked up from ~/perl/col/prot/My_NLS_list
	chomp ($in);
	$motDat{$tmp[0]}= $in;
	
      }
      if($i==0){
	$tmp_motif=$tmp[0];
      }
      else {
	$tmp_motif=$tmp_motif.";".$tmp[0];
      }
      $i++;
    }
    close $fh;
    
}

#===============================================================================

sub motifManager {
#===============================================================================
#    motifManager               compiles list and does preprocessing of Motifs.
#===============================================================================
    if(!(defined $tmp_motif)) {
	print STDOUT "Motif List not defined; check inputs and default parameters\n";
	exit;
    }
    @motif= split(/;/,$tmp_motif); # array motif contains set of NLS signals
    foreach $i (0..$#motif) {
    
#	print STDOUT "$motif[$i]\n";
	$motif_w[$i]= $motif[$i];
    	$motif_w[$i]=~s /x/\\w/g; # replace x with \w. Perl syntax.
	   
    }
    foreach $i (0..$#motif) {
	print $fhout "#motif_$i: $motif[$i]\n";
    }

    # End of reading in input parameters.
}

#===============================================================================

sub findLoci {
#===============================================================================
#   findLoci                    finds location if known.
#===============================================================================
    local $fh;
    $fh= "FHIN";
    if(!(defined $fileLoci)) {
	$fileLoci= $par{"lociList"}; # use def Loci list.
    }
    open($fh,$fileLoci) || die "*** failed opening file_location=$fileLoci\n";
    undef %location; 
    
    #reads protein locations, kingdom from file "xTransl.rdb"
    while(<$fhin>){
	next if ($_=~/^\#/);
	@tmp=split(/[\s]+/,$_);
	$id=$tmp[0];
	$location{$id}=$tmp[2];
    
    }

    close $fh;
}

#===============================================================================

sub findMotif {
#===============================================================================    
#   findMotif                 searches for motif in $res.
#===============================================================================

    $len= length $res;
    # scanning for motif starts here.
    $flag=0;		#  check to see if prot contains NLS motif.
    undef $stack;# kepps track of NLS's found if more than one found.
    undef $loc_stack; # keeps track of loci of NLS Found.	
      MOT:
	foreach $x (0..$#motif_w) {
	    #print "$motif_w[$x]\n";
	  if ($res eq $motif[$x] ){
	     $flag++;
	      if ( defined $motDat{$motif[$x]}){
	      $foundMotif{$id}{$motif[$x]}= $motDat{$motif[$x]};
	    }
	     $ext_motif{$motif[$x]}++;
	    if(defined $prot_list{$motif[$x]}){
	      $prot_list{$motif[$x]}=$prot_list{$motif[$x]}.",".$id;
	    }
	    else{
	      $prot_list{$motif[$x]}=$id;
	    }
	      if(defined $stack) {
	      $stack=$stack.";".$motif[$x];
	      $loc_stack=$loc_stack.";".$loc;
	    }
	    else{
	      $stack= $motif[$x];
	      $loc_stack= $loc;
	    }
	    # stat analysis
	    
	    if(defined $location{$id} && $location{$id}=~ /nuc/) {
	      $op{$motif[$x]}++;
	    }
	    else{
	      $nop{$motif[$x]}++;
	    }
	  }
	  elsif  ($res=~ /(\w+)$motif_w[$x]/) {
	    
	    $flag++;
	    
	    @tmp=split(//,$1);
	    $loc= $#tmp+1;
	    
	    if (defined $stack && $stack=~ /$motif[$x]/){
	      next MOT;
	    }
	    if ( defined $motDat{$motif[$x]}){
	      $foundMotif{$id}{$motif[$x]}= $motDat{$motif[$x]};
	    }
	    $ext_motif{$motif[$x]}++;
	    if(defined $prot_list{$motif[$x]}){
	      $prot_list{$motif[$x]}=$prot_list{$motif[$x]}.",".$id;
	    }
	    else{
	      $prot_list{$motif[$x]}=$id;
	    }
	    if(defined $stack) {
	      $stack=$stack.";".$motif[$x];
	      $loc_stack=$loc_stack.";".$loc;
	    }
	    else{
	      $stack= $motif[$x];
	      $loc_stack= $loc;
	    }
	    # stat analysis
	    
	    if(defined $location{$id} && $location{$id}=~ /nuc/) {
	      $op{$motif[$x]}++;
	    }
	    else{
	      $nop{$motif[$x]}++;
	    }
		
	   }
	 }
	  if ($flag>0) { 
	    $prot_nls++;
	    if(defined $location{$id}){
	      $loci= $location{$id};
	    }
	    else {
	      $loci= "unk";
	    }
	    print $fhout "$id\t$loci\t$len\t$stack\t$loc_stack\n";
	    print STDOUT "$id\t$loci\t$len\t$stack\t$loc_stack\n";
	  } 
	}
    
    #===============================================================================
    
    sub statManager{
#===============================================================================
      #   statManager            compiles Motif stat.
      #===============================================================================
      
      foreach $k (keys %ext_motif) {
	
	$op{$k}= int (10000*$op{$k}/$ext_motif{$k})/100;
	$nop{$k}= int(10000*$nop{$k}/$ext_motif{$k})/100;
	print $fhout1 "$k\t$ext_motif{$k}\t$op{$k}\t$nop{$k}\t$prot_list{$k}\t";
	@tmp=split(/,/,$prot_list{$k});
	foreach $z (0..$#tmp){
	  if ($z==0) {
	    
	    print $fhout1 "$location{$tmp[$z]}";
	  }
	  else{
	    print $fhout1 ",$location{$tmp[$z]}";
	  }
	}
	print $fhout1 "\n";
	
      }
    }
    #===============================================================================
    
    sub fastaManager{
      #===============================================================================
      #   fastaManager          fasta sequence Reader
      #===============================================================================
      $res= ""; # seq list empty to start with.
      $id=~m /_(\w)/; # for finding dir in /data/derived/big/splitSwiss/?/***.f
      $fileFasta= $par{"fastaDir"}.$1."/".$id.".f";
      if(-e $fileFasta){
	print "processing protein: $fileFasta\n";  
	open($fhdata,$fileFasta) || die "***failed opening fastaFiles\n";
      RESIDUE:
	while(<$fhdata>){
	  next RESIDUE if ($_=~ /^\>/);
	  $_=~s /\s//g;
	  $res=$res.$_;
	}
	close $fhdata;
      }
      else{
	print "Fasta file couldn't be found for $id\n";
	next PROT;
    }
}
    
#===============================================================================

sub swissManager{
#===============================================================================
#   swissManager          Swiss sequence Reader.
#===============================================================================
    $res= ""; # seq list empty to start with.
    $id=~m /_(\w)/; # for finding dir in /data/derived/big/splitSwiss/?/***.f
    $fileSwiss= $par{"swissDir"}.$1."/".$id;
    if(-e $fileSwiss){
	print "processing protein: $fileSwiss\n";  
	open($fhdata,$fileSwiss) || die "***failed opening $fileSwiss \n";
	while(<$fhdata>) {
	    next if /^[A-Z]/;
	    last if /^\/\//;
	    s /\s//g;
	    $res=$res.$_;
	}
	
	close $fhdata;
    }
    else {
	print "Swiss file couldn't be found for $fileSwiss \n";
	next PROT;
    }
}
#===============================================================================

sub phdManager{
#===============================================================================
#   phdManager           rdbPhd sequence Reader.
#===============================================================================
    $res= ""; # seq list empty to start with.
    $fileRdb= $fileDir.$id."-fil.rdbPhd";
    if (-e $fileRdb) {
	    print "processing protein: $fileRdb\n";
	    
	    open($fhdata,$fileRdb) || die "***failed opening PHD_files\n";
	    
	    while(<$fhdata>){
		next if ($_=~/^\#/ ||$_=~/^\w/ || $_=~/^4N/);
		
		$_=~s /[\s]+//;
		@tmp=split(/[\s]+/,$_);
		$res= $res.$tmp[1];
	    }
	    close $fhdata;
	}
	else {
	    print "rdbPhd file couldn't be found for $id\n";
	    
	}
}

#===============================================================================
sub egrepManager {
#===============================================================================
#egrepManager            subroutine uses unix egrep to find sequences which contain given motif
#===============================================================================

 # method: egrep $tmp_motif in $file_fasta and the process o/p
  my(@protSeq,$foundSeq,@tmp,$seq);
  $foundSeq= `egrep "$tmp_motif" "$file_fasta"`; # each line of $foundSeq contains a protein seq that contains the motif
  
  @protSeq=split(/\n/,$foundSeq);
 SEQ:
  foreach $protSeq (@protSeq) {
    @tmp= split(/\t/,$protSeq);
    $id=$tmp[0];
    $id=~s /\>//;
    $id=~s /\s//g;
    $seq=$tmp[1];
    $seq=~s /\s//g;
    $len= length $seq;
    if($seq=~ /($tmp_motif)/){
      $pos = (length$`) +1; # start position of motif
      
      if(defined $location{$id}){
	      $loci= $location{$id};
	    }
	    else {
	      $loci= "unk";
	    }
      $ext_motif{$inMotif}++; # counts number of proteins which contains this nls.

      if(defined $location{$id} && $location{$id}=~ /nuc/) {
	$op{$inMotif}++;
	   }
      else{
	$nop{$inMotif}++;
      }
      if(defined $prot_list{$inMotif}){
	      $prot_list{$inMotif}=$prot_list{$inMotif}.",".$id;
	    }
	    else{
	      $prot_list{$inMotif}=$id;
	    }
      print $fhout "$id\t$loci\t$len\t$inMotif\t$pos\n";
      print STDOUT "$id\t$loci\t$len\t$inMotif\t$pos\n";
    }
  }
}
