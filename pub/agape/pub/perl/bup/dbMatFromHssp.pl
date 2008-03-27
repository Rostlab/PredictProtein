#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compiles a matrix of evolutionary exchanges\n";
#  
#
$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib ("lib-ut.pl","lib-br.pl"){
     require $dir.$lib || 
 	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
				# ------------------------------
&dbMatFromHssp("ini");		# ini

				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName list.hssp (or *.hssp)'\n";
    print "opt: \t \n";
    print "     \t fileOut=x   \n";
    print "     \t skip      -> if SAF existing, no action\n";
    print "     \t noskip    -> write new SAF, even if existing\n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (@kwd){
	    printf "     \t %-20s=%-s (def)\n",$kwd,$par{"$kwd"};}}
    exit;}
				# ------------------------------
				# now running it
($Lok,$msg)=
    &dbMatFromHssp(@ARGV);

print "*** $scrName: final msg=".$msg."\n" if (! $Lok);
exit;

#===============================================================================
sub dbMatFromHssp {
    local($tmpMode) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dbMatFromHssp               compiles matrix of residue exchanges for list of
#                               HSSP files
#       in:                     file.hssp (or list, or *.hssp)
#                               file.hssp_C   for chain!
#       in:                     opt fileOut=X     -> output file will be X
#                                                    NOTE: only for single file!
#       in:                     opt extr=n1-n2    -> extract residues n1-n2
#       in:                     opt expand        -> write expanded ali
#       in:                     opt noScreen      -> avoid writing
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp:lib-scr::"."dbMatFromHssp";$fhinLoc="FHIN_"."dbMatFromHssp";
				# ------------------------------
				# defaults
				# ------------------------------
    $par{"len1Min"}=           30; # minimal length
    $par{"laliMin"}=           30; # minimal alignment length
    $par{"pideMax"}=           99; # maximal percentage sequence identity

    $par{"expand"}=             0; # expand insertions?
    $par{"debug"}=              0; # 
    $par{"fileTrace"}=          "DB-TRACE" .$$.".tmp"; # 
    $par{"fileScreen"}=         "DB-SCREEN".$$.".tmp"; # file dumping the screen from system(exe)

    $par{"exeConvHssp2saf"}=    "/home/rost/perl/scr/conv_hssp2saf.pl";	# executable for HSSP->SAF

    $par{"verb2"}=              0; # 
    $par{"verb2"}=              0; # 
    $par{"doSkipExisting"}=     0; # skips if *saf file already existing

    $par{"aa"}=                     "VLIMFWYGAPSTCHRKQEND"; 

    @aa=split(//,$par{"aa"});
    foreach $tmp(@aa){
	$aa{$tmp}=1;}
    $aa=$par{"aa"};

    @kwd=sort (keys %par);

    $sep="\t";
				# ini matrix
    foreach $it1 (1..$#aa){
	foreach $it2 (1..$#aa){
	    $mat{"$aa[$it1]","$aa[$it2]"}=0;}}

    return if (defined $tmpMode && $tmpMode eq "ini");

				# ------------------------------
				# initialise variables
    $fhin="FHIN";$fhout="FHOUT";
    $fhTrace="FHDBTRACE";
    $#fileRm=0;
				# ------------------------------
    $#fileIn=$#chainIn=0;	# read command line
    foreach $arg (@_){
	if    ($arg=~/^fileOut=(.*)$/)          { $fileOut=$1;}
	elsif ($arg=~/^debug|debug=1/)          { $par{"debug"}=1;}
	elsif ($arg=~/^skip$/)                  { $par{"doSkipExisting"}=1;}
	elsif ($arg=~/^noskip$/)                { $par{"doSkipExisting"}=0;}
#	elsif ($arg=~/^=(.*)$/) { $=$1;}
	elsif (-e $arg)                         { push(@fileIn,$arg); push(@chainIn,"*");}
	elsif ($arg=~/^(.*\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
	elsif (defined %par && $#kwd>0)         { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
	else { print "*** wrong command line arg '$arg'\n"; 
	       die;}}
	
    $fileIn=$fileIn[1];
    die ("missing input $fileIn\n") if (! -e $fileIn);
    if (! defined $fileOut){
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
				# --------------------------------------------------
				# (0) read list (if list)
    if (! &is_hssp($fileIn)){	# --------------------------------------------------
	print "--- $scrName: read list '$fileIn'\n";
	$#fileIn=$#chainIn=0;
	$fhin="FHIN_$scrName";
	&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {
	    $_=~s/\n|\s//g;
	    next if (length($_)<5);
	    if ($_=~/^(.*\.hssp)\_([A-Z0-9])/){
		push(@fileIn,$1); push(@chainIn,$2);}
	    else {
		push(@fileIn,$_); push(@chainIn,"*");} 
	} close($fhin);}
				# ------------------------------
				# trace file
    &open_file("$fhTrace",">".$par{"fileTrace"});
    $par{"fileScreen"}=0        if (defined $par{"debug"} && $par{"debug"} && 
				    $par{"fileScreen"} eq "DB-SCREEN".$$.".tmp");

				# --------------------------------------------------
				# (1) loop over file(s)
				# --------------------------------------------------
    foreach $itfile(1..$#fileIn){
	next if (! -e $fileIn[$itfile]);
	($Lok,$msg)= 
	    &dbMatFromHssp_hsspRdLoc;
	if (! $Lok) {print "*** ERROR $scrName: file=$itfile\n",$msg,"\n";
		     next;}
    }
				# --------------------------------------------------
				# (2) normalise mat
				# --------------------------------------------------
    foreach $it1 (1..$#aa){
	$sum[$it1]=0;
	foreach $it2 (1..$#aa){	# sam all rows
	    $sum[$it1]+=$mat{"$aa[$it1]","$aa[$it2]"}; }
				# ------------------------------
	foreach $it2 (1..$#aa){	# compile percentages
	    if ($sum[$it1]<=1){
		$matPerc{"$aa[$it1]","$aa[$it2]"}=0;}
	    else {
		$matPerc{"$aa[$it1]","$aa[$it2]"}=100*($mat{"$aa[$it1]","$aa[$it2]"}/$sum[$it1]);} }
				# ------------------------------
	foreach $it2 (1..$#aa){	# log odds
	    if ($matPerc{"$aa[$it1]","$aa[$it2]"}>0){
		$matOdds{"$aa[$it1]","$aa[$it2]"}=
		    ($matPerc{"$aa[$it1]","$aa[$it2]"}/100)*
			log($matPerc{"$aa[$it1]","$aa[$it2]"}/100); }
	    else { $matOdds{"$aa[$it1]","$aa[$it2]"}=0;} }}
				# --------------------------------------------------
				# (3) arrays to write
				# --------------------------------------------------
				# counts
    $#tmpNum=0;
    $tmp=sprintf ("%5s$sep%5s","num","x->y");
    foreach $it1 (1..$#aa){ $tmp.=sprintf ("$sep%5s",$aa[$it1]);} $tmp.= "\n";  
    push(@tmpNum,$tmp);

    foreach $it1 (1..$#aa){
	$tmp= sprintf ("%5s$sep%5s","num",$aa[$it1]);
	foreach $it2 (1..$#aa){
	    $tmp.=sprintf ("$sep%5d",$mat{"$aa[$it1]","$aa[$it2]"});} $tmp.= "\n";
	push(@tmpNum,$tmp); }
    $#tmpPerc=0;		# percentages
    $tmp=sprintf ("%5s$sep%5s","perc","x->y");
    foreach $it1 (1..$#aa){ $tmp.=sprintf ("$sep%5s",$aa[$it1]);} $tmp.= "\n";  
    push(@tmpPerc,$tmp);
    foreach $it1 (1..$#aa){
	$tmp= sprintf ("%5s$sep%5s","perc",$aa[$it1]);
	foreach $it2 (1..$#aa){
	    $tmp.=sprintf ("$sep%5d",int($matPerc{"$aa[$it1]","$aa[$it2]"}));} $tmp.= "\n";
	push(@tmpPerc,$tmp); }
    $#tmpOdds=0;		# log odds
    $tmp=sprintf ("%5s$sep%5s","odds","x->y");
    foreach $it1 (1..$#aa){ $tmp.=sprintf ("$sep%5s",$aa[$it1]);} $tmp.= "\n";  
    push(@tmpOdds,$tmp);
    foreach $it1 (1..$#aa){
	$tmp= sprintf ("%5s$sep%5s","odds",$aa[$it1]);
	foreach $it2 (1..$#aa){
	    $tmp.=sprintf ("$sep%5.2f",$matOdds{"$aa[$it1]","$aa[$it2]"});} $tmp.= "\n";
	push(@tmpOdds,$tmp); }
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
    &open_file("$fhout",">$fileOut"); 
    foreach $tmp (@tmpNum,@tmpOdds,@tmpPerc){
	print        $tmp if ($par{"verb2"} || $par{"debug"});
	print $fhout $tmp;}
    close($fhout);
    close($fhTrace);
				# ------------------------------
				# clean up
    if (! $par{"debug"}){
	push(@fileRm,$par{"fileTrace"});
	push(@fileRm,$par{"fileScreen"});
	foreach $file (@fileRm){ 
	    next if (! defined $file);
	    next if (! -e $file);
	    print "--- remove $file\n";
	    unlink ($file); }}
    print "--- output in $fileOut\n";
    return(1,"ok $sbrName");
}				# end of dbMatFromHssp

#===============================================================================
sub dbMatFromHssp_hsspRdLoc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dbMatFromHssp_hsspRdLoc     reads stuff: (1) call conv_hssp2saf, (2) read SAF
#                               reason: save memory!
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-scr::"."dbMatFromHssp_hsspRdLoc";$fhinLoc="FHIN_"."dbMatFromHssp_hsspRdLoc";

    $fileIn=$fileIn[$itfile]; $chainIn=$chainIn[$itfile];
    if (! -e $fileIn){ print "-*- WARN $scrName: no fileIn=$fileIn\n";
		       die '*** '.$sbrName.' input file='.$fileIn.' missing  ';}
    print "--- $scrName: working on $itfile =$fileIn $chainIn\n";
    $pdbid= $fileIn;$pdbid=~s/^.*\/|\.hssp//g; 
    $pdbid.="_".$chainIn        if ($chainIn ne "*");
    $fileOutLoc="$pdbid".".saf";
    $fileInTmp=$fileIn;
    $fileInTmp.="_".$chainIn    if ($chainIn ne "*");

				# ------------------------------
				# build up argument for calling scr
				# 
    $cmdFin="";			# avoid warnings

    $cmd= $par{"exeConvHssp2saf"};
				# skip if existing
    if (! -e $fileOutLoc && ! $par{"doSkipExisting"}){
	$cmd.=" ".$fileInTmp." fileOut=$fileOutLoc noScreen ";
	$cmd.=" "."len1Min=".$par{"len1Min"}." "."laliMin=".$par{"laliMin"}." "."pideMax=".$par{"pideMax"};
	eval "\$cmdFin=\"$cmd\""; 

	($Lok,$msg)=
	    &sysRunProg($cmdFin,$par{"fileScreen"},$fhTrace);
	return(0,"*** ERROR $sbrName: failed to convert hssp to MSF\n".$msg."\n")
	    if (! $Lok || ! -e $fileOutLoc);
    }
                                # ------------------------------
                                # read in
    undef %tmp;
    ($Lok,$msg,%tmp)=
	&safRd($fileOutLoc);
    return(&errSbrMsg("failed reading saf ($fileOutLoc)",$msg)) if (! $Lok);
    push(@fileRm,$fileOutLoc);

#    foreach $it (1..$tmp{"NROWS"}){printf "xx rdSaf %3d %-10s %-s\n",$it,$tmp{"id","$it"},$tmp{"seq","$it"};}

				# ------------------------------
				# compile exchange counts
    @guide=  split(//,$tmp{"seq","1"});
    foreach $it (2..$tmp{"NROWS"}){
 	@ali=split(//,$tmp{"seq","$it"});
	foreach $itres (1..$#guide){
	    next if (! defined $aa{$guide[$itres]});
	    last if ($#ali < $itres);
	    next if (! defined $aa{$ali[$itres]});
	    ++$mat{"$guide[$itres]","$ali[$itres]"};}}

    undef %tmp; undef @guide; undef @ali; # slick-is-in !

    return(1,"ok $sbrName");
}				# end of dbMatFromHssp_hsspRdLoc



