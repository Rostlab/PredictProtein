#!/usr/pub/bin/perl4 
#----------------------------------------------------------------------
# run_xevalsec
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"run_xevalsec.pl sec_file"
#
# task:		Evaluating identity of two exposure strings
# 		written like sec str, but with n**2 = rel exp
#
#----------------------------------------------------------------------
#                                                                      #
#----------------------------------------------------------------------#
#	Burkhard Rost			November,	1993           #
#			changed:	March,      	1994           #
#			changed:	August,      	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name = "run_xevalsec.pl";
$script_input= "sec_file";
$script_opt_ar[1] = "2nd = executable";
$script_opt_ar[2] = "any after 1st: do_exclude  -> exclusion of proteins (for old 126 only)";
$script_opt_ar[3] = "any after 1st: is_phdgrep  -> file from old(sic) program secstron";
$script_opt_ar[3].= "\n--- \t \t reason: use pred file with fault: 80 + empty -> not_phdgrep";
$script_opt_ar[5] = "any after 1st: not_secstr  -> no secondary structure read";
$script_opt_ar[6] = "any after 1st: not_rel     -> no reliability index";
$script_opt_ar[7] = "any after 1st: not_conv    -> no conversion of DSSP";
$script_opt_ar[8] = "any after 1st: is_pdb      -> is from PDB comparison";
$script_opt_ar[9] = "any after 1st: is_old      -> assumes old version, i.e. 80 = 1 empty";
$script_opt_ar[10]= "any after 1st: out=x       -> output file called 'x' (for PPcol)";
$script_opt_ar[11]= "any after 1st: dirdef=x    -> default directory 'x'  (for PPcol)";
$script_opt_ar[12]= "any after 1st: title=x     -> title for files 'x'    (for PPcol)";
#$script_opt_ar[13]= "any after 1st: tmp=x       -> temporary file 'x'     (for PPcol)";

# push (@INC, "/home/rost/perl") ;
require "/home/phd/ut/perl/ctime.pl";
# require "rs_ut.pl" ;
# require "lib-ut.pl"; 
# require "lib-prot.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; $date = join(':',@Date) ;

$path= $ENV{'PATH'} ;
$ARCH= $ENV{'ARCH'} ;

$Lscreen=0;

                                # trouble with environment
if ( length($ARCH) == 0 ) {$ARCH = $ENV{'CPUARC'} ; }
if ( $ARCH =~ /SGI/ ) {$ARCH="IRIS";}
				# ------------------------------
				# about script
				# ------------------------------
if ($Lscreen) { 
    &myprt_line; &myprt_txt("perl script to run xevalsec");
    &myprt_empty; &myprt_txt("usage: \t $script_name $script_input"); &myprt_empty;
    for ($i=1; $i<=$#script_opt_ar; ++$i) {
	print"--- option $i: \t $script_opt_ar[$i] \n"; }}
				# ------------------------------
				# number of arguments ok?
				# ------------------------------
if ($#ARGV < 1) {
    print "number of arguments:  \t$ARGV \n";
    die "*** ERROR: \n*** usage: \t $script_name $script_input \n";}
				# ------------------------------
				# read input
				# ------------------------------
$file_in= $ARGV[1]; 	        
$file_out="PPOUT.tmp";		# file for converting Tableqils to PP output
if ($Lscreen) { &myprt_empty; &myprt_txt("file here: \t \t $file_in"); }

				# ------------------------------
				# defaults
				# ------------------------------
$title="unk";
$dir_def= "/purple1/rost/prog/$ARCH/";
if ( ($#ARGV >= 2) && ($ARGV[2] !~ /not_/) && ($ARGV[2] !~ /is_/) && ($ARGV[2] !~ /do_/) && 
     ($ARGV[2] !~ /=/) ) { 
    $evalsec_exe = $ARGV[2];
} else { $evalsec_exe = $dir_def . "xevalsec." . "$ARCH"; }
if ($Lscreen) { &myprt_txt("executable: \t $evalsec_exe"); }

$opt_passed = "";
for ( $i=2; $i <= $#ARGV; ++$i ) {
    $opt_passed .= " " . "$ARGV[$i]";
}
if ($Lscreen) {  &myprt_txt("options passed: \t $opt_passed"); }
				# ------------------------------
				# check existence of file
if ( ! -e $file_in ) {&myprt_empty; &myprt_txt("ERROR: \t file $file_in does not exist"); exit;}
				# ------------------------------
				# read input arguments
				# ------------------------------
$numfilesread=  1;
				# excluding protein chains from analysis ?
if($opt_passed=~/do_excl/){$lexcludechains="Y";}else{$lexcludechains="N";}
				# assuming len=80 does not give an empty section
if($opt_passed=~/is_phdgr|is_grep/){$lread_predgrep="Y"}else{$lread_predgrep="N";}
				# reading reliability index?
if($opt_passed=~/not_rel/){$lread_relind="N";}else{$lread_relind="Y";}
				# assuming pdb comparions
if($opt_passed=~/is_pdb/){$lpdb="Y";$lread_relind="N";}else{$lpdb="N";}
				# converting dssp
if($opt_passed=~/not_conv/){$lconvdssp="N";}else{$lconvdssp="Y";}
				# assuming old files = 80 produces empty
if($opt_passed=~/is_old/){$lold_version="Y";}else{$lold_version="N";}
				# PP specific
foreach $_ (@ARGV){
    if    ($_=~/^out=(.*)$/)   { $file_out=$1;} # PP output file
    elsif ($_=~/^dirdef=(.*)$/){ $dir_def=$1; } # PP default directory
    elsif ($_=~/^title=(.*)$/) { $title=$1;   } # PP default title
#    elsif ($_=~/^tmp=(.*)$/)   { $fileTmp=$1; } # PP temporary title
}
if ($title=~/unk/){
    $tmp=$file_in; $tmp=~s/\.predrel|\.pred//g; $title=$tmp;
    $title=$tmp;}
				# ------------------------------
				# is from PP-server (PP column)?
				# ------------------------------
$Lis_ppcol=$Lis_rel=0;
if (&is_ppcol($file_in)){
    $Lis_ppcol=   1;
    $title=       "EVALSEC_$$" if ($title =~/unk/);
    if (defined $fileTmp){$file_dotpred=$fileTmp;}
    else                 {$file_dotpred="$title".".pred";}
				# convert to required input format
    ($Lis_ok,$Lis_rel)= &ppcol_2_dotpred($file_in,$file_dotpred);

    if ($Lis_rel) { $file_tmp=$file_dotpred."rel";
                    system"\\mv $file_dotpred $file_tmp";
                    $file_dotpred=$file_tmp;}
    $file_in=$file_dotpred;     # change input file name
}
				# ----------------------------------------
				# execute fortran program xevalsec
				# ----------------------------------------
				# ------------------------------
				# automatically assign relindex
if ( ($file_in =~ /predrel|relpred|PREDREL/) || $Lis_rel ) {
    $lread_relind="Y";
    if ($Lscreen) { &myprt_txt("assume file with reliabity index !"); } }
else {
    $lread_relind="N"; }
				# ------------------------------
				# further defaults
$devnom=     50;
$ltable_po=  "N";		
$ltable_seg= "N";		
$ltable_qils="Y";		
				# ==================================================
				# now do it with arguments: 
				#           numfiles,title, devnom,excl,convdssp,
                                #           readpredgrep,readrelin,tablepo,seg,qils,
				# ==================================================
eval "\$command=\"$evalsec_exe,$numfilesread,$title,$devnom,$lexcludechains,$lconvdssp,$lread_predgrep,$lread_relind,$lold_version,$ltable_po,$ltable_seg,$ltable_qils,$lpdb\"";

&run_program($command ,"STDOUT","die") ;
				# ----------------------------------------
				# now write new if PPcol
				# ----------------------------------------
$file_table="Tableqils-".$title;
if (! $Lis_ppcol){
    open("FHIN","$file_table");$#NAME=0;
    while(<FHIN>){
	if (/^ \|\s*\w+\s*\:\s+\d+\s+\| method\:/){
	    $_=~s/\n//g;
	    $name=$_;$name=~s/^ \|\s+(\w+)\s.*$/$1/g;
	    push(@NAME,$name);}}close(FHIN);}

&evalsec_rd_tableqils($file_table,$file_out);

				# ------------------------------
				# if normal input write 'bad'
if (! $Lis_ppcol){$#NAME=0;
		  $file_gr="Grqali-".$title;$file_grTmp="xx$$_".$file_gr;
		  system("\\cp $file_gr $file_grTmp");
		  open("FHIN","$file_grTmp");open("FHOUT",">$file_gr");
		  print FHOUT 
		      "No. ,PDBID  ,Q3chain,ov\/loos,strict ,SOV \%o ,SOV \%p ,",
		      "Taylor,  bad,under,over\n";
		  while(<FHIN>){
		      $_=~s/\n//g;
		      @tmp=split(/,/,$_);
		      $name=$tmp[2];$name=~s/\s//g;
		      print FHOUT $_,",";
		      foreach $des("bad","under","over"){
			  printf FHOUT "%5.1f,",$res{"$name","$des"};}print FHOUT "\n";
		  }close(FHIN);
		  system("\\rm $file_grTmp");}
				# clean up
if ($Lscreen) { 
    print "EVALSEC: clean up, i.e., remove: 'Gr*$title', 'Tab*$title', '$title *'\n";}

if ($Lis_ppcol){
    system("\\rm Ta*$title");
    system("\\rm $title*");
    system("\\rm Gr*$title");}
system("\\rm xx.tmp");      # somehow from FORTRAN ...
exit;

#==========================================================================================
sub ppcol_2_dotpred {
    local ($file_in,$file_out) = @_ ;
    local (@des,%rd,$Lfalse_sec,$Lfalse_obs,$name,$ct,$Lis_rel,$des,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppcol_2_dotpred            converts the input from PP (column format) into
#                               the format required for evalsec
#--------------------------------------------------------------------------------
				# ------------------------------
				# defaults and ini
				# ------------------------------
#    @des=("NAME","AA","SEC","OBS","RI");
    @des=("NAME","AA","PHEL","OHEL","RI");
				# ------------------------------
				# read PP-column format
				# ------------------------------
    %rd= &ppcol_rd($file_in,@des);

				# ------------------------------
				# error check
				# ------------------------------
    foreach $name (@NAME) {
	$ct=1;$Lfalse_sec=$Lfalse_obs=0;
	while (defined $rd{"$name","NAME","$ct"}){
	    if ($rd{"$name","PHEL","$ct"}=~/[^HEL \.]/) {$Lfalse_sec=1;}
	    if ($rd{"$name","OHEL","$ct"}=~/[^HEL \.]/) {$Lfalse_obs=1;}
	    if ($Lfalse_sec && $Lfalse_obs) {last;}
	    ++$ct;
	}
	if ($Lfalse_sec){
	    print "*** extract_seq: COLUMN format: wrong predicted secondary structure, \n";
	    print "***              allowed are: H,E,L\n"; }
	if ($Lfalse_obs){
	    print "*** extract_seq: COLUMN format: wrong observed secondary structure, \n";
	    print "***              allowed are: H,E,L\n"; }
    }
				# ------------------------------
				# is RI?
				# ------------------------------
    $Lis_rel=0;
    foreach $des (@DESRD){if($des=~/RI/){$Lis_rel=1;last;}}

				# --------------------------------------------------
				# write file in dotpred format for evalsec
				# --------------------------------------------------
    if ((! $Lfalse_sec)&&(! $Lfalse_obs)){
	&dotpred_wrt($file_out,%rd);
	$Lok=1;
    } else { $Lok=0;}
    return($Lok,$Lis_rel);
}				# end of ppcol_2_dotpred

#==========================================================================================
sub ppcol_rd {
    local ($file_in,@des) = @_ ;
    local ($fhin,$ct,%seq,%sec,%ri,%obs,%name,$Lis_name,$Lfst,@tmp,$tmp,$des,
	   $Lok,$it,%ptr,$ctprot,$ctres,$name,$ptr);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppcol_rd                   read the PP column format
#       in:                     $file_in,@des
#       out:                    %rd (returned)
#                               @name, @DESRD (global)
#--------------------------------------------------------------------------------
    $fhin="FHIN_PPCOL";

    $ct=0;			# initialise arrays asf
    %seq=%sec=%ri=%obs=%name=0;
    $#DESRD=$Lis_name=0;
    $Lfst=1;
				# ------------------------------
				# read file
				# ------------------------------
    open($fhin,"$file_in")  || warn "Can't open '$file_in' (ppcol_rd) $!\n";
    while ( <$fhin> ) {
	$_=~tr/[a-z]/[A-Z]/;	# upper caps
	$_=~s/\n//g;		# purge newline
	$_=~s/^[ ,\t]*|[ ,\t]*$//g; # purge leading blanks, tabs, commata
	if ( (length($_)<1)|| (/^\#/) ) {
	    next;}
	if ($Lfst){		# how many columns, and which?
	    $Lfst=$#tmp=0;
	    @tmp=split(/[\s\t,]+/,$_);
	    foreach $des (@des){
		$Lok=0;
		foreach $it (1..$#tmp) {
		    if ($tmp[$it]=~/$des/) { $Lok=1; $ptr{"$des"}=$it; push(@DESRD,$des); }
		    if ($Lok) {last;} }}
	    foreach $des (@DESRD){
		if ($des =~ /NAME/) { $Lis_name=1; last; }}
	} else {		# expected to be sequence info now!
	    ++$ct; 
	    $#tmp=0;@tmp=split(/[\s\t,]+/,$_); # split spaces, tabs, or commata
	    if ($ct==1){	# get name
		$ctprot=1;$ctres=0;
		if ($Lis_name){$ptr=$ptr{"NAME"};$name=$tmp[$ptr]; }
		else {$name="name1";} 
		push(@NAME,$name);
	    }elsif ($Lis_name){ # new protein?
		$ptr=$ptr{"NAME"};$tmp=$tmp[$ptr]; 
		if ($tmp ne $name){
		    ++$ctprot;$ctres=0;
		    $name=$tmp;push(@NAME,$name); }}
	    ++$ctres;
	    foreach $des (@DESRD) {
		$ptr=$ptr{"$des"};
		$rd{"$name","$des","$ctres"}=$tmp[$ptr];
	    }
	}
    }
    close($fhin);
    return(%rd);
}				# end of ppcol_rd

#==========================================================================================
sub dotpred_wrt {
    local ($file_in,%rd) = @_ ;
    local ($fhout,$name,$ct,$aa,$sec,$obs,$ri);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    dotpred_wrt                write dotpred format (for evalsec)
#    in:                        $file_out, %rd{}
#                 GLOBAL        @NAME,@DESRD
#--------------------------------------------------------------------------------
    $fhout="DOTPRED_OUT";
    if ($fhout !~ /STDOUT/){
	open($fhout,">$file_out")  || warn "Can't open '$file_out' (dotpred_wrt) $!\n";
    }
    print  $fhout "# PHD DOTPRED 8.95 \n";
    printf $fhout "num %4d \n", $#NAME;
    %Lok=0;
    foreach $des (@DESRD){$Lok{"$des"}=1;}

    foreach $name (@NAME) {
	$ct=1;$aa=$sec=$obs=$ri="";
	while (defined $rd{"$name","NAME","$ct"}){
	    foreach $des (@DESRD){
		if   (($des=~/AA|SEQ/)  &&(defined $Lok{"$des"})){
		    $aa.= $rd{"$name","$des","$ct"};}
		elsif(($des=~/SEC|PHEL/)&&(defined $Lok{"$des"})){
		    $sec.=$rd{"$name","$des","$ct"};}
		elsif(($des=~/OBS|OHEL|OSEC/) &&(defined $Lok{"$des"})){
		    $obs.=$rd{"$name","$des","$ct"};}
		elsif(($des=~/RI/)  &&(defined $Lok{"$des"})){
		    $ri.= $rd{"$name","$des","$ct"};}
		elsif(($des=~/NAME/)&&(defined $Lok{"$des"})){
		    $name=$rd{"$name","$des","$ct"};}
	    }
	    ++$ct;
	}
				# correction
	if (! defined $Lok{"AA"}){foreach $it (1..length($sec)){$aa.="U";}}
	
	printf $fhout "\# 1 %10d %-s\n",length($aa),$name;
				  
	if (! defined $Lok{"RI"}){
	    &write80_data_prepdata($aa,$obs,$sec);
	    &write80_data_preptext("AA ","Obs","Prd");  
	} else {
	    &write80_data_prepdata($aa,$obs,$sec,$ri);
	    &write80_data_preptext("AA ","Obs","Prd","Rel");  
	}
	&write80_data_do("$fhout");
    }
    print $fhout "END\n";
    if ($fhout !~ /STDOUT/ ){close($fhout);}
}				# end of dotpred_wrt

#==========================================================================================
sub evalsec_rd_tableqils {
    local ($file_in,$file_out) = @_ ;
    local ($fhin,$fhout,@des_sec,$des,$des1,$des2,$name,$len,$ctprot,$ctline,$ctfin,
	   $Lok,$Lend,$Lfin,$Lextra,$tmp,@tmp,$num_res,$bad,$under,$over,);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils       first reads, then writes content of Tableqils
#                               as generated by evalsec
#       in:          GLOBAL     @NAME, %rd
#--------------------------------------------------------------------------------
    $fhin="FHIN_TABLEQILS";
    $fhout="FHOUT_TABLEQILS";
    @des_sec=("H","E","L");	# secondary structure symbols
				# key-words for averages at end of file
    @des_sec2=("H","E");

    if ($#NAME > 1) { push(@NAME,"Average over all residues");}

				# --------------------------------------------------
				# read and write file
				# --------------------------------------------------
    open($fhin,"$file_in")   || warn "Can't open '$file_in' (evalsec_rd_tableqils) $!\n";
    open($fhout,">$file_out")|| warn "Can't open out: '$file_out' (evalsec_rd_tableqils) $!\n";
    $ctprot=$ctfin=$Lok=$Lend=$Lfin=0;
    while(<$fhin>){
	$_=~s/\n//g;
	$tmp=$_;$tmp=~s/\s//g;
	if (length($tmp)<1){$Lok=0;
			    next;}
	if ((!$Lok)&&(/^\s+\+\-/)&&(!$Lfin)&&(!$Lend)){
	    $Lok=1;
	    if ( ($ctprot>0)&&($ctprot<=$#NAME) ) {
				# ------------------------------
				# write
				# ------------------------------
				# compute sums
		$num_res=$rd{"num","Sprd","Sobs"};

		$bad=0;		# bad predictions H->E, E->H
		foreach $des1 ("H","E"){foreach $des2 ("H","E"){
		    if ($des1 !~ $des2) { $bad+=$rd{"num","$des1","$des2"}; }}}
		$under=0;	# under predictions H->L, E->L
		foreach $des1 ("H","E"){$under+=$rd{"num","$des1","L"};}
		$over=0;	# over predictions L->H, E->H
		foreach $des2 ("H","E"){$over+=$rd{"num","L","$des2"};}
		if ($num_res != 0) { 
		    $rd{"bad"}=  100*($bad/$num_res);
		    $rd{"under"}=100*($under/$num_res);
		    $rd{"over"}= 100*($over/$num_res);
		}else{
		    $rd{"bad"}=$rd{"under"}=$rd{"over"}=0;}

		$name=$NAME[$ctprot];
		foreach $des("bad","under","over"){$res{"$name","$des"}=$rd{"$des"};}

		$Lextra=1;
		print  $fhout "# \n# ","*" x (length($NAME[$ctprot])+24),"\n";
		printf $fhout "# Prediction accuracy for %-40s\n",$NAME[$ctprot];
		print  $fhout "# ","*" x (length($NAME[$ctprot])+24),"\n";
			
		if ($ctprot==$#NAME) {$tmp="ALL";}
		else                 {$tmp="$ctprot";}
		    
		&evalsec_wrt_num($fhout,$Lextra,@des_sec);
		&evalsec_wrt_state($fhout,$Lextra,@des_sec);
		&evalsec_wrt_tot($fhout,$Lextra,@des_sec);
	    }			# end of writing
				# ------------------------------
	    if ($ctprot==$#NAME) {
		$Lok=0;$Lend=1; }
	    $ctline=0;
	    ++$ctprot;}
	if ($Lok){
	    ++$ctline;
	    if ($ctline==2){
		$name=$NAME[$ctprot];
		$len= substr($_,12,5);$len=~s/\s//g;}
	    elsif ( ($ctline>=8)&&($ctline<=10) ) {
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\|+|\|+$//g; # purging and "| .... |"
		$#tmp=0;@tmp=split(/\|/,$_);
		
		$des1=$tmp[1];$des1=~s/DSSP//;$des1=~s/C/L/;
				# reading numbers for H, E, O
		&evalsec_rd_tableqils_1st($des1,$_,@des_sec);
		&evalsec_rd_tableqils_2nd($des1,$_,@des_sec); }
	    elsif ($ctline==12) {
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\||\|$//g;	# purging and "| .... |"
				# reading sums of numbers for H, E, O
		$des1="Sprd";
		&evalsec_rd_tableqils_1st($des1,$_,@des_sec);}
	    elsif ($ctline==13) { # correlation, Q3
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\|+|\|+$//g;	# purging and "| .... |"
		&evalsec_rd_tableqils_3rd($_,@des_sec);}
	    elsif ($ctline==19){ # SOV, entropy
		~s/\s//g;	# purging blanks
		~s/^\||\|$//g;	# purging and "| .... |"
		&evalsec_rd_tableqils_4th($_,@des_sec);
	    }
	}			# end of reading per protein stuff
				# ------------------------------
	if ($Lend){		# now read averages over all proteins
	    if ($#NAME>1){
		if (/Q3mean =/){            
		    $_=~s/[\s-|]|Q3mean.*=//g;
		    $rd{"q3ave"}=$_;}
		elsif (/sqrt\( Q3var \) =/){
		    $_=~s/[\s-|]|sqrt.*\(Q3var.*\).*=//g;
		    $rd{"q3var"}=$_; } }
	    if (/all sets: contav /){
		$_=~s/[\s-|]|all sets: contav//g;
		foreach $des(@des_sec2){
		    if (/$des.*=/) {
			$_=~s/^.*$des=//g;
			$tmp1=$_;$tmp1=~s/(\d+\.\d+).+/$1/g;
			$tmp2=$_;$tmp1=~s/sqrt \(var\).*=(\d+\.\d+).+/$1/g;
			$rd{"contave","$des"}=$tmp1;
			$rd{"contvar","$des"}=$tmp2;} }}
	    if (/Sorting into structure class according to paper of Zhang Chou/){
		$Lfin=1; $ctfin=0; $Lend=0;}
	}			# end of reading overall averages
				# ------------------------------
	if ($Lfin){		# read class prediction
	    $_=~s/^ ---\s+//g; ~s/rest /other/;
	    $_=~s/DSSP/ obs/; ~s/\%DSSP/\%obs /; ~s/PRED/ prd/; ~s/\%PRED/\%prd /;
	    if (/^[\+\|]/){
		++$ctfin;
		$rd{"class","$ctfin"}=$_; }}
    }
    close($fhin);
				# ----------------------------------------
				# finally writing averages and class stuff
				# ----------------------------------------
    if ($#NAME>1){
	$tmp=$#NAME-1;
	&evalsec_wrt_ave($fhout,$tmp,$rd{"q3ave"},$rd{"q3ave"}); }
    &evalsec_wrt_class($fhout,@des_sec2); 
    print $fhout "END\n";
    close($fhout);
}				# end of evalsec_rd_tableqils

#==========================================================================================
sub evalsec_rd_tableqils_1st {
    local ($des1,$line,@des_sec) = @_ ;
    local ($ct,$it,$des2,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_1st   read line:
# |        |net H |net E |net C |sum DS|
# | DSSP H |    8 |    0 |    2 |   10 |
#--------------------------------------------------------------------------------
    $#tmp=0;@tmp=split(/\|/,$line);
				# numbers
    foreach $it (1..$#des_sec) {$des2=$des_sec[$it];
				$rd{"num","$des1","$des2"}=$tmp[$it+1]; }
				# reading sum of numbers
    $ct=$#des_sec+2;$des2="Sobs";$rd{"num","$des1","$des2"}=$tmp[$ct];
}				# end of evalsec_rd_tableqils_1st

#==========================================================================================
sub evalsec_rd_tableqils_2nd {
    local ($des1,$line,@des_sec) = @_ ;
    local ($ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_2nd   read line:
#   H  |  E  |  C  | H | E | C |DSSP| Net|DSSP| Net|
#  80.0|  0.0| 20.0|100|  0| 28|   2|   2| 5.0| 4.0|
#--------------------------------------------------------------------------------
    $ct=$#des_sec+2;
				# percentage of observed
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it];
				$rd{"qobs","$des1","$des2"}=$tmp[$ct]; }
				# percentage of predicted
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it];
				$rd{"qprd","$des1","$des2"}=$tmp[$ct]; }
				# segment: obs numb, prd num, obs av, prd av
    ++$ct;$des2="nsegobs";  $rd{"seg","$des1","$des2"}=$tmp[$ct];
    ++$ct;$des2="nsegprd";  $rd{"seg","$des1","$des2"}=$tmp[$ct];
    ++$ct;$des2="nsegavobs";$rd{"seg","$des1","$des2"}=$tmp[$ct];
    ++$ct;$des2="nsegavprd";$rd{"seg","$des1","$des2"}=$tmp[$ct];
}				# end of evalsec_rd_tableqils_2nd

#==========================================================================================
sub evalsec_rd_tableqils_3rd {
    local ($line,@des_sec) = @_ ;
    local ($ct,$it,$des2,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_3rd   read line:
#--------------------------------------------------------------------------------
    $#tmp=0;@tmp=split(/\|+/,$line);
				# correlation
    foreach $it (1..$#des_sec) {$des2=$des_sec[$it];
				$rd{"cor","$des2"}=$tmp[$it]; }
				# Q3
    $rd{"q3"}=$tmp[$#des_sec+1];
}				# end of evalsec_rd_tableqils_3rd

#==========================================================================================
sub evalsec_rd_tableqils_4th {
    local ($line,@des_sec) = @_ ;
    local ($ct,$it,$des2,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_4th   read line:
#--------------------------------------------------------------------------------
    $#tmp=0;@tmp=split(/\|+/,$line);
    $ct=1;
				# SOV %obs
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it]."obs";
				$rd{"sov","$des2"}=$tmp[$ct]; }
    ++$ct;$des2="Sobs";$rd{"sov","$des2"}=$tmp[$ct]; 
				# SOV %prd
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it]."prd";
				$rd{"sov","$des2"}=$tmp[$ct]; }
    ++$ct;$des2="Sprd";$rd{"sov","$des2"}=$tmp[$ct]; 
				# entropy
    ++$ct;$des2="obs";$rd{"entropy","$des2"}=$tmp[$ct]; 
    ++$ct;$des2="Pobs";$rd{"entropy","$des2"}=$tmp[$ct]; 
    ++$ct;$des2="prd";$rd{"entropy","$des2"}=$tmp[$ct]; 
    ++$ct;$des2="Pprd";$rd{"entropy","$des2"}=$tmp[$ct]; 
}				# end of evalsec_rd_tableqils_4th

#==========================================================================================
sub evalsec_wrt_num {
    local ($fh,$Lextra,@des_sec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_num            writes numbers (Aij)
#--------------------------------------------------------------------------------

    print  $fh "# \n# A(i,j): number of residues observed in state i, predicted in j:\n# \n";
    if ($Lextra) { &evalsec_wrt_num_extra($fh,$#des_sec); }
				# 1. row: symbols
    printf $fh "DAT | NUMBERS |";
    foreach $des1 (@des_sec){printf $fh "  %3s  %1s |","prd",$des1;}
    print $fh " obs Sum | \n";

    if ($Lextra) { &evalsec_wrt_num_extra($fh,$#des_sec); }
    
    foreach $des1 (@des_sec,"Sprd"){ # 2.-5. row: numbers
	if ($des1 =~ /Sprd/) {
	    if ($Lextra) { &evalsec_wrt_num_extra($fh,$#des_sec); }
	    print  $fh "DAT | prd Sum |";}
	else                 {printf $fh "DAT |  obs  %1s |",$des1;}
	
	foreach $des2 (@des_sec,"Sobs"){
	    printf $fh " %7d |",$rd{"num","$des1","$des2"}; }
	print $fh "\n";
    }
    if ($Lextra) { &evalsec_wrt_num_extra($fh,$#des_sec); }
}				# end of evalsec_wrt_num

#==========================================================================================
sub evalsec_wrt_num_extra {
    local ($fh,$num_sec) = @_ ;
    local ($it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_num_extra      writes line: +--------+ ...
#--------------------------------------------------------------------------------
    print $fh "DAT +---------+";
    foreach $it (1..($num_sec+1)) {
	print $fh "---------+";
    }
    print $fh "\n";
}				# end of evalsec_wrt_num_extra

#==========================================================================================
sub evalsec_wrt_state {
    local ($fh,$Lextra,@des_sec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_state            writes numbers (Aij)
#--------------------------------------------------------------------------------
    print  $fh "# \n# Per-residue and Per-segment scores:\n# \n";
    print $fh "DAT +---------------------------------+ +---------------------------------------+\n";
    print $fh "DAT |        Per-residue scores       | |           Per-segment scores          |\n";
    print $fh "DAT +---------+-------+-------+-------+ +---------+---------+---------+---------+\n";
    print $fh "DAT | SCORES  |Q(i)obs|Q(i)prd| COR(i)| |SOV(i)obs|SOV(i)prd|avL(i)obs|avL(i)prd|\n";
    if ($Lextra) { &evalsec_wrt_state_extra($fh,$#des_sec); }

    foreach $des1 (@des_sec){
				# per-residue
	printf $fh "DAT | i =  %1s  |",$des1;
	printf $fh "%6d |",int($rd{"qobs","$des1","$des1"}); # Qi %obs
	printf $fh "%6d |",int($rd{"qprd","$des1","$des1"}); # Qi %prd
	printf $fh "%6.2f |",$rd{"cor","$des1"};	# correlation
				# per-segment
	print $fh  " |";
	foreach $des2("obs","prd"){
	    $des_tmp=$des1.$des2;
	    printf $fh " %7.1f |",$rd{"sov","$des_tmp"};
	}
	foreach $des2 ("nsegavobs","nsegavprd"){
	    printf $fh "  %6.1f |",$rd{"seg","$des1","$des2"};
	}
	print $fh " \n";
    }
    if ($Lextra) { &evalsec_wrt_state_extra($fh,$#des_sec); }
}				# end of evalsec_wrt_state

#==========================================================================================
sub evalsec_wrt_state_extra {
    local ($fh) = @_ ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_state_extra      writes line: +--------+ ...
#--------------------------------------------------------------------------------
    print $fh "DAT +---------+-------+-------+-------+ +---------+---------+---------+---------+\n";
}				# end of evalsec_wrt_state_extra

#==========================================================================================
sub evalsec_wrt_tot {
    local ($fh,$Lextra,@des_sec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_tot            writes numbers (Aij)
#--------------------------------------------------------------------------------
    print  $fh "# \n# Overall scores:\n# \n";
    print $fh "DAT +---------------------------------+ +---------------------------------------+\n";
    print $fh "DAT |   Overall per-residue scores    | |       Overall per-segment scores      |\n";
    print $fh "DAT +-------+--------+-------+--------+ +---------+---------+---------+---------+\n";
    printf 
	$fh "DAT | OVER  | %5.1f  | UNDER | %5.1f  | |                                       |\n",
	$rd{"over"},$rd{"under"};
    printf 
	$fh "DAT | I obs |  %5.2f | I prd |  %5.2f | |                                       |\n",
	$rd{"entropy","obs"},$rd{"entropy","obs"};
    printf 
	$fh "DAT |  Q3   | %5.1f  |  BAD  | %5.1f  | | SOV3obs | %6.1f  | SOV3prd | %6.1f  |\n",
	$rd{"q3"},$rd{"bad"},$rd{"sov","Sobs"},$rd{"sov","Sprd"};
    if ($Lextra) { 
	print 
	    $fh "DAT +-------+========+-------+--------+ ",
	    "+---------+=========+---------+---------+\n";
    }
}				# end of evalsec_wrt_tot

#==========================================================================================
sub evalsec_wrt_ave {
    local ($fh,$numprot,$q3ave,$q3var) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_ave            writes final averages over sets
#--------------------------------------------------------------------------------
    printf $fh "# \n# Per-residue accuracy averaged over all %5d proteins:\n# \n",$numprot;
    print  $fh "+---------------------+---------------------------------+\n";
    printf $fh "| <Q3>/prot  = %6.2f | one standard deviation = %6.2f |\n",$q3ave,$q3var;
    print  $fh "+---------------------+---------------------------------+\n";
}				# end of evalsec_wrt_ave

#==========================================================================================
sub evalsec_wrt_class {
    local ($fh,@des) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_class            writes final class values
#--------------------------------------------------------------------------------
    print  $fh "# \n# Accuracy of predicting secondary structural content:\n# \n";
    print  $fh "DAT +---------------------+---------------------------------+\n";
    foreach $des(@des){
	printf 
	    $fh "DAT | Dcontent %1s = %6.2f | one standard deviation = %6.2f |\n",
	    $des,$rd{"contave","$des"},$rd{"contvar","$des"};
    }
    print  $fh "DAT +---------------------+---------------------------------+\n";
				# class
    print  $fh "# \n# Accuracy of predicting secondary structural class:\n# \n";
    print  
	$fh "#        Sorting into structure class according to \n",
	"#        Zhang, C.-T. and Chou, K.-C., Prot. Sci. 1:401-408, 1992:\n",
	"#           all-H: percentage of H >= 45% , percentage of E <  5%\n",
	"#           all-E: percentage of H <   5% , percentage of E >=45%\n",
	"#           mix  : percentage of H >= 30% , percentage of E >=20%\n# \n";
    $ct=1;
    while ( defined $rd{"class","$ct"} ){
	print $fh "DAT ",$rd{"class","$ct"},"\n";
	++$ct;
    }
}				# end of evalsec_wrt_class


#==========================================================================================
sub is_ppcol {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format
#   input:                file
#--------------------------------------------------------------------------------
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$file_in");
    while ( <$fh> ) {$_=~tr/[A-Z]/[a-z]/;
		     if (/^\# pp.*col/) {$Lis=1;}else{$Lis=0;}last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol



#==========================================================================
#    sub: write80_data_prepdata
#==========================================================================
sub write80_data_prepdata {
    local ( @data_in) = @_;
    local ( $i);
    $[=1;

#----------------------------------------------------------------------
#   writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_data = 0;
    for ( $i=1; $i <=$#data_in ; $i ++ ) {
	$write80_data[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data


#==========================================================================
sub write80_data_preptext {
    local (@data_in) = @_;
    local ( $i, $it2);
    $[=1;

#----------------------------------------------------------------------
#   writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_text = 0;
    for ( $i=1; $i <= $#data_in ; $i ++ ) {
	$write80_text[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data


#==========================================================================
sub write80_data_do {
    local ( $fh_out) = @_;
    local ( $seq_intmp, $i, $it2);
    $[=1;

#----------------------------------------------------------------------
#   writes hssp seq + sec str + exposure(projected onto 1 digit) into 
#   file with 80 characters per line
#----------------------------------------------------------------------
    $seq_intmp =  "$write80_data[1]";
    $seq_intmp =~ s/\s//g;
    if ( length($seq_intmp) != length($write80_data[1]) ) {
	print "*** ERROR in write_hssp_..: passed: sequence with spaces! \n";
	print "*** in: \t |$write80_data[1]| \n";
	exit;
    }

    for( $i=1; $i <= length($seq_intmp) ; $i += 80 ) {
	&myprt_points80 ($i);	
	print $fh_out "    $myprt_points80 \n";
	for ( $it2=1; $it2<=$#write80_data; $it2 ++) {
	    print $fh_out "$write80_text[$it2]", "|", substr($write80_data[$it2],$i,80), "|\n";
	}

#	print $fh_out "AA |", substr($seq_in,$i,80), "|\n";
#	print $fh_out "DSP|", substr($secstr_in,$i,80), "|\n";
#	print $fh_out "Exp|", substr($exp_in,$i,80), "|\n";
    } 
}				# end of: write80_data

#======================================================================
#    sub: myprt_points
#======================================================================
sub myprt_npoints {
   local ($npoints,$num_in) = @_; 
   local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
   $[=1;

   if ( int($npoints/10)!=($npoints/10) ) {
       print "*** ERROR in myprt_npoints (lib-prot.pl): \n";
       print "***       number of points passed should be multiple of 10!\n"; exit; }

   $ct=int(($num_in-1)/$npoints);
   $beg=$ct*$npoints; $num=$beg;
   for ($i=1;$i<=($npoints/10);++$i) {
       $numprev=$num; $num=$beg+($i*10);
       $ctprev=$numprev/10;
       if ( $i==1 ) { $tmp=substr($num,1,1); $out="....,....".$tmp; 
       } elsif ( $ctprev<10 ) {  $tmp=substr($num,1,1); $out.="....,....".$tmp; 
       } elsif ( ($i==($npoints/10))&&($ctprev>=9) ) { 
           $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
           $out.=$tmp1.$tmp2.",....".substr(($num/10),1); 
       } else {
           $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
           $out.=$tmp1.$tmp2.",....".substr($num,1,1); 
       }
   }
   $myprt_npoints=$out;
}
				# end of myprt_npoints

#======================================================================
#    sub: myprt_points80
#======================================================================
sub myprt_points80 {
   local ($num_in) = @_; 
   local ($tmp9, $tmp8, $tmp7, $tmp, $out, $ct, $i);
   $[=1;

   $tmp9 = "....,...."; $tmp8 =  "...,...."; $tmp7 =   "..,....";
   $ct   = (  int ( ($num_in -1 ) / 80 )  *  8  );
   $out  = "$tmp9";
   if ( $ct == 0 ) {
       for( $i=1; $i<8; $i++ ) {
	   $out .= "$i" . "$tmp9" ;
       }
       $out .= "8";
   } elsif ( $ct == 8 ) {
       $out .= "9" . "$tmp9";
       for( $i=2; $i<8; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp8" ;
       }
       $out .= "16";
   } elsif ( ($ct>8) && ($ct<96) ) {
       for( $i=1; $i<8; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp8" ;
       }
       $tmp = $ct+8;
       $out .= "$tmp";
   } elsif ( $ct == 96 ) {
       for( $i=1; $i<=3; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp8" ;
       }
       for( $i=4; $i<8; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp7" ;
       }
       $tmp = $ct+8;
       $out .= "$tmp" ;
   } else {
       for( $i=1; $i<8 ; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp7" ;
       }
       $tmp = $ct+8;
       $out .= "$tmp" ;
   }
   $myprt_points80=$out;
}
				# end of myprt_points80

#======================================================================
sub myprt_line { print "-" x 70, "\n", "--- \n"; }

#======================================================================
sub myprt_empty { print "--- \n"; }

#======================================================================
sub myprt_txt { local ($string) = @_; print "--- $string \n"; }


#======================================================================
sub run_program {
    local ($cmd, $log_file, $action) = @_ ;
    local ($out_command,$cmdtmp);

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    print "--- running command: $cmdtmp, do='$action'\n" ;
    open (TMP_CMD, "|$cmdtmp") || ( do {
	if ( $log_file ) {print $log_file "Can't run command: $cmdtmp\n" ;}
	warn "Can't run command: '$cmdtmp'\n" ;
	$action ;
    } );
    foreach $command (@out_command) {
# delete end of line, and spaces in front and at the end of the string
	$command =~ s/\n// ;
	$command =~ s/^ *//g ;
	$command =~ s/ *$//g ; 
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;
}

#======================================================================
sub open_file {
    local ($file_handle, $file_name, $log_file) = @_ ;
    local ($temp_name) ;

#    close ("$file_handle") ;
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
       print "*** \t INFO: file $temp_name does not exist; create it\n" ;
       open ($file_handle, ">$temp_name") || ( do {
             warn "***\t Can't create new file: $temp_name\n" ;
             if ( $log_file ) {
                print $log_file "***\t Can't create new file: $temp_name\n" ;
             }
       } );
       close ("$file_handle") ;
    }
  
    open ($file_handle, "$file_name") || ( do {
             warn "*** \t Can't open file '$file_name'\n" ;
             if ( $log_file ) {
                print $log_file "*** \t Can't create new file '$file_name'\n" ;
             }
             die ;
       } );
}

1;
