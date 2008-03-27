#!/usr/bin/perl -w
##!/usr/pub/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="interprets sub-cellular locations read from SWISS-PROT\n";
#
$[ =1 ;

				# ------------------------------
				# defaults
%par=(
      'dirSwiss',    "/home/rost/data/swissprot/",
      'fileSpecies', "speclist.txt",
      '', "",			# 
      'dbg',         0,			# 
      );
$par{"species"}="euka";

@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file-swiss-loci.rdb' (e.g. Euka-allLoci.rdb)\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",    "x",       "";
    printf "%5s %-15s %-20s %-s\n","","filter",     "no value","filters out other kingdoms";
    printf "%5s %-15s=%-20s %-s\n","","species",    "x",       "euka|proka|archae|virus|all";
    printf "%5s %-35s %-s\n",      ""," ", "used for title, for filtering if and only if fileSpecies!\n";
    printf "%5s %-15s=%-20s %-s\n","","fileSpecies","x",       "swiss/speclist.txt";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$Lfilter=0;
				# ------------------------------
				# read command line
$fileIn=$ARGV[1];
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=           $1;}
    elsif ($arg=~/^spec.*=(.*)$/)         { $par{"species"}=    $1;}
    elsif ($arg=~/^fileSpecies=(.*)$/)    { $par{"fileSpecies"}=$1;}
    elsif ($arg=~/^fil(ter)?$/)           { $Lfilter=           1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/\.rdb/Transl\.rdb/;$fileOut=$tmp; }

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}

if ($par{"fileSpecies"} && ! -e $par{"fileSpecies"}) {
    $par{"fileSpecies"}=$par{"dirSwiss"}.$par{"fileSpecies"};}
				# ------------------------------
				# correct species
if ($par{"species"}     && $par{"species"} ne "all") {
    $par{"species"}="euka"      if ($par{"species"}=~/^euka/);
    $par{"species"}="proka"     if ($par{"species"}=~/^prok/);
    $par{"species"}="archae"    if ($par{"species"}=~/^arch/);
    $par{"species"}="virus"     if ($par{"species"}=~/^vir/); }

				# --------------------------------------------------
				# (1) build up dictionary
&dictionaryLocation;
				# --------------------------------------------------
				# (2) get species 
undef %species;
if ($Lfilter            &&
    $par{"fileSpecies"} && -e $par{"fileSpecies"} &&
    $par{"species"}     && $par{"species"} ne "all") {

    @specNames=
	&here_swissGetKingdom($par{"fileSpecies"},$par{"species"});
    if (! @specNames) { print "*** $scrName failed reading species (".$par{"fileSpecies"}.")\n";
			exit; }
    foreach $species (@specNames) {
	print "xx species=$species\n";
	$species{$species}=1; } }

if ($Lfilter && ! defined %species) {
    print "*** $scrName you want to filter, but species failed (file=".$par{"fileSpecies"}.")!!!\n";
    exit; }


				# ------------------------------
				# (3) write RDB header
($Lok,$err)=
    &wrtLociHead($fileOut,$fhout);
if (! $Lok) { print "*** $scrName failed on $fileOut\n",$err,"\n";
	      exit;}

				# --------------------------------------------------
				# (4) read file(s) with location (raw data)
				# --------------------------------------------------
if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		  next;}
printf "--- $scrName: working on %-25s\n",$fileIn;
open("$fhin","$fileIn") || die "*** $scrName ERROR opening file $fileIn";

$ctOk=0;
$ct=0;

while (<$fhin>) {
				# skip comments
    next if ($_=~/^\#|^lineNo|^\s*5N/);
    $_=~s/\n//g;
    $_=~s/^\s*|\s*$//g;		# purge leading blanks
    @tmp=split(/\t/,$_); 
    $tmp[2]=~s/\s//g;
    $Lexcl=$Lincl=0;
    ++$ct;
				# ------------------------------
				# exclude if species not wanted
    if ($Lfilter) {
	$species=$tmp[2];
	$species=~s/^.*_(.+)$/$1/;
	$Lexcl=1                if (! defined $species{$species}); }
#    print "xx excl species=$species, ($tmp[2]-$tmp[3])\n";
#    exit if ($ct > 2000);
    print "--- ct=$ct, excl species=$species ($tmp[2]-$tmp[3])\n" if ($Lexcl && $par{"dbg"});
    next if ($Lexcl);		# exclude, indeed (species)
	

				# ------------------------------
				# exclude if in list (e.g. membrane)
    foreach $kwd (@lociIgnore){
	next if ($tmp[3] !~ /$kwd/);
	$Lexcl=1;
	last;}
    print "--- ct=$ct, excl membrane ($tmp[2]-$tmp[3])\n" if ($Lexcl && $par{"dbg"});
    next if ($Lexcl);		# exclude, indeed (marked)

				# ------------------------------
				# exclude as double location
    foreach $kwd (@lociWatch){
	next if ($tmp[3] !~ /$kwd/ );
	$Lexcl=1;
	last;}
    print "--- ct=$ct, excl double location ($tmp[2]-$tmp[3])\n" if ($Lexcl && $par{"dbg"});
    next if ($Lexcl);		# exclude, indeed (dangerous)

				# ------------------------------
				# find the correct translation
    foreach $loci (@lociTake){
	next if ($tmp[3] !~ /$loci/);
	$Lincl=1;
	$lociFound=$loci;
	print "--- ct=$ct for trans=$loci, for location=$tmp[3]!\n" if ($par{"dbg"});
	last;}
				# ------------------------------
				# now write it!
    ++$ctOk;
    $id=$tmp[2];$id=~s/\s//g;
    if    (! $Lincl)                            {
	$loci=$lociUnk;}
    elsif (defined $lociInterpret{"$lociFound"}){
	$loci=$lociInterpret{"$lociFound"};}
    else                                        {
	$loci=$lociUnk;}
    
    printf "--- now: %5s %-15s %-15s %-7s\n",$ctOk,$id,$loci,$par{"species"};

				# --------------------
    printf $fhout 		# write into file
	"%5s\t%-15s\t%-15s\t%-7s\t%-50s\n",
	$ctOk,$id,$loci,$par{"species"},substr($tmp[3],1,50);
}
close($fhin);close($fhout);
print "--- fileOut=$fileOut\n";

exit;

#===============================================================================
sub here_swissGetKingdom {
    local($fileLoc,$kingdomLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,@specLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   here_swissGetKingdom             gets all species for given kingdom
#       in:                     $kingdom (all,euka,proka,virus,archae)
#       out:                    @species
#-------------------------------------------------------------------------------
    $sbrName="swissKingdom2Species";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# assign search pattern
    if    ($kingdomLoc eq "all")   { $tmp="EPAV";}
    elsif ($kingdomLoc eq "euka")  { $tmp="E";}
    elsif ($kingdomLoc eq "proka") { $tmp="P";}
    elsif ($kingdomLoc eq "virus") { $tmp="V";}
    elsif ($kingdomLoc eq "archae"){ $tmp="A";}
				# read SWISS-PROT file (/data/swissprot/speclist.txt)
    $#specLoc=0;
    open($fhinLoc,$fileLoc) || return(0,"*** $sbrName: failed opening '$fileLoc'\n");
	
				# notation 'SPECIES V|P|E|A\d+ ..'
    while (<$fhinLoc>) {
	last if /^Code  Taxon: N=Official name/;}
    while (<$fhinLoc>) {
	next if (! /^[A-Z].*[$tmp][0-9a-z:]+ /);
	@tmp=split(/\s+/,$_);
	$tmp[1]=~tr/[A-Z]/[a-z]/;
	push(@specLoc,$tmp[1]);}
    close($fhinLoc);

    return(@specLoc);
}				# end of here_swissGetKingdom

#===============================================================================
sub dictionaryLocation {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dictionaryLocation          interpreting the SWISS-PROT location keywords
#       in/out GLOBAL
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."dictionaryLocation";
				# ------------------------------
				# from Nakai & Kanehisa: 
				# ------------------------------
				# 
				# - chloroplast      (stroma, thylakoid membr, thylakoid space)
				# - cytoplasm
				# - endoplasmic ret  (lumen, membrane)
				# - golgi complex
				# - lysosome         (lumen, membrane)
				# - mitochondrion    (inner membrane, intermembr space, 
                                #                     matrix space, outer membrane)
				# - nucleus
				# - extracellular space
				# - plasma membrane  (GPI-anchored, integral)
				# - peroxisome
				# - vacuole
    $lociUnk=       "unk";
    %lociInterpret= (
		     'CHLOROPLAST',           "pla", 
		     'CYTOPLASM',             "cyt", # proka + euka
		     'ENDOPLASMIC RETICULUM', "ret",
		     'EXTRACELLULAR',         "ext", # proka + euka
		     'INTERCELLULAR',         "ext",
		     'GOLGI',                 "gol",
		     'LYSOSOMAL',             "lys",
		     'MITOCHONDRIA',          "mit",
		     'NUCLEAR',               "nuc",
		     'PEROXISOM',             "oxi",
		     'VACUOLAR',              "vac",
		     'PERIPLASMIC',           "rip",
		     );
    @lociAbbrev=    ("cyt","pla","ret","ext","gol",
		     "lys","mit","nuc","oxi","vac","rip");
    %lociExplain=   ('cyt',"CYTOPLASM             [euka,proka]",
		     'pla',"CHLOROPLAST           [euka,plants]  (STROMA and THYLAKOID)",
		     'ret',"ENDOPLASMIC RETICULUM [euka]         (LUMEN)",
		     'ext',"EXTRACELLULAR         [euka,proka]",
		     'gol',"GOLGI                 [euka]         (LUMEN, not VACUOLES)",
		     'lys',"LYSOSOMAL             [euka,animals]",
		     'mit',"MITOCHONDRIA          [euka]         (MATRIX)",
		     'nuc',"NUCLEAR               [euka,proka]",
		     'oxi',"PEROXISOM             [euka,proka]",
		     'vac',"VACUOLAR              [euka,plants]",
		     'rip',"PERIPLASMIC           [proka]",
		     );
				# note: hierarchy: first taken first
    @lociTake=  ("VACUOLAR",	# important to be first 
		 "CYTOPLASM",
		 "EXTRACELLULAR",
		 "NUCLEAR",
		 "ENDOPLASMIC RETICULUM", # note: 'ER LUMEN' and 'ER MEMBRANE'
		 "GOLGI",	# note: GOLGI LUMEN, MEMBRANE, '.* VACUOLES'
		 "INTERCELLULAR",
		 "CHLOROPLAST",	# note: CHLOROPLAST STROMA, THYLAKOID MEMBRANE, THYLAKOID
		 "LYSOSOMAL",
		 "MITOCHONDRIA", # note: MITOCHONDRIAL INNER MEMBRANE, INTERMEMBRANE, 
				#       MITOCHONDRIAL MATRIX, OUTER MEMBRANE
		 "PEROXISOM",	# note: PEROXISOMAL 
		 );
    @lociIgnore=("(PROBABLE)","(POTENTIAL)","(BY SIMILARITY)","(POSSIBLE)",
		 "MEMBRANE","CELL WALL","WALLS",
		 "CYTOPLASMIC VESICLES"
		 );
    @lociWatch= ("ENDOPLASMIC RETICULUM AND THE GOLGI APPARATUS",
		 "DIFFERENT SUBCELLULAR ",
		 "CYTOPLASMIC MICROTUBULES",
		 "CYTOPLASMIC .* EXTRACELLULAR",
		 "CYTOPLASMIC .* GOLGI",
		 "CYTOPLASMIC .* MITOCHONDR",
		 "CYTOPLASMIC .* NUCLE",
		 "CYTOPLASMIC .* PARTICULATE ",
		 "CYTOPLASMIC .* VACUOLAR",
		 "GOLGI .* VACUOLES",
		 "NUCLEAR .* CYTOPLASM",
		 "LYSOSOME.* VACUOLES",
		 "MITOCHONDRIA.* CYTOPLASMIC",
		 "MITOCHONDRIA.* ENDOPLASMIC RETICULUM.",
		 "MITOCHONDRIA.* EXTRAMITOCHONDRIAL",
		 "MITOCHONDRIA.* NUCLE",
		 "MITOCHONDRIA.* PEROXISOMAL",
		 "NUCLEAR.* CENTRO",
		 "NUCLEAR.* CYTOPLASM",
		 "NUCLEAR.* MITOCHONDRIAL",
		 "NUCLEAR.* CYTOSOL",
		 "NUCLEAR PORE ",
		 "NUCLEAR.* MOSTLY",
		 "PEROXISOMAL .* GLYOXYSOMAL",
		 "PEROXISOMAL .* MITOCHONDR",
		 "PEROXISOMAL .* CYTOPLASMIC",
		 "PERIPLASM.* CYTOPLASM",
		 "PERIPLASM.* ",
		 "PERIPLASM.* ",
		 "PERIPLASM.* ",
		 "PERIPLASM.* EXTRACELLULAR",
		 );	     
}				# end of dictionaryLocation

#===============================================================================
sub wrtLociHead {
    local($fileOutLoc,$fhoutLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtLociHead                 writes header of output file
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."wrtLociHead";

    open($fhoutLoc,">$fileOutLoc") || return(0,"*** $sbrName failed to open new $fileOutLoc");

    print $fhoutLoc
	"\# Perl-RDB\n","\# SWISS-PROT sub-cellular locations (interpreted)\n",
	"\# NOTATION ----------------------------------------------------------------------\n",
	"\# NOTATION COLUMN-NAMES\n",
	"\# NOTATION lineNo:       counts rows\n",
	"\# NOTATION id:           PDB/SWISS-PROT identifier\n",
	"\# NOTATION loci:         sub-cellular location interpreted from SWISS-PROT\n",
	"\# NOTATION species:      from SWISS-PROT (euka, proka, archae, virus)\n",
	"\# NOTATION swiss-entry:  entry for sub-cellular location taken from SWISS-PROT\n",
	"\# NOTATION ----------------------------------------------------------------------\n",
	"\# NOTATION ABBREVIATIONS\n";
    foreach $des(@lociAbbrev){
	print $fhoutLoc "\# NOTATION loci $des:     ",$lociExplain{"$des"},"\n";}
    print $fhoutLoc
	"\# NOTATION ----------------------------------------------------------------------\n",
	"\# \n";
    printf $fhoutLoc		# names
	"%5s\t%-15s\t%-15s\t%-7s\t%-s\n","lineNo","id", "loci","species","swiss-entry";
    printf $fhoutLoc		# formats
	"%5s\t%-15s\t%-10s\t%-7s\t%-s\n","5S",    "15S","15S", "7S",     "50S";
    return(1,"ok");
}				# end of wrtLociHead

