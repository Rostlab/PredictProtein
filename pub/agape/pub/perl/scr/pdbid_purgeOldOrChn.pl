#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="purges 7fab if 7fab_A found, or 7fab if 8fab|8fab_A found!";
#  
#

$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib("lib-ut.pl","lib-br.pl"){
    require $dir.$lib ||
	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
undef $dir;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName list or *file*'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s= %-20s %-s\n","","fileOut",  "x",       "";

    printf "%5s %-15s  %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";
    printf "%5s %-15s  %-20s %-s\n","","dir",      "x",      "give directory name if not ids";
    printf "%5s %-15s  %-20s %-s\n","","ext",      "x",      "give extension (hssp) if not ids (NO dot!!)";

#    printf "%5s %-15s  %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s  %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
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
$LisList=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^list$/i)               { $LisList= 1;}
    elsif ($arg=~/^dir=(.*)$/)            { $dir=    $1;}
    elsif ($arg=~/^ext=(.*)$/)            { $ext=    $1; $ext=~s/\.//g if ($ext=~/\./); }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);

if    (! defined $fileOut && $#fileIn==1){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
elsif (! defined $fileOut){
    $fileOut="Out-merge".$#fileIn.".tmp";}

$dir.="/"                       if (defined $dir && $dir !~ /\/$/);

				# ------------------------------
				# read list of files?
				# ------------------------------
if (! $LisList && $fileIn[1]=~/\.list/) {
    $#fileTmp=0;
    foreach $fileIn (@fileIn){
	if ($fileIn !~ /\.list/){
	    push(@fileTmp,$fileIn);
	    next; }
	
	&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {$_=~s/\s|\n//g; 
			 push(@fileTmp,$_);}close($fhin); }
    @fileIn=@fileTmp;}

				# ------------------------------
				# (1) all ids
				# ------------------------------
undef %ok; 
$#id=0;
foreach $fileIn (@fileIn){
				# get id
    $id=$fileIn; 
    $id=~s/$dir//               if (defined $dir);
    $id=~s/\.$ext//             if (defined $ext);

				# already there?
    if (! defined $ok{$id}) { $ok{$id}=1;
			      push(@id,$id); } }

				# ------------------------------
				# sort to have higher number on
				#    top

@id = reverse sort @id;		# reverse sort

				# ------------------------------
				# (2) skip 7fab if 8fab there
				# ------------------------------
foreach $id (@id) {
    next if (! $ok{$id});	# already excluded
    $num= substr($id,1,1);
    $name=substr($id,2);

				# check version
    if ($num > 1) {
	for ($it=($num-1); $it>=1; --$it) {
	    $tmpid=$it.$name;
				# get out older version!!
	    if (defined $ok{$tmpid}) {
		$ok{$tmpid}=0;
		printf "%-6s kills %-6s\n",$id,$tmpid; 
	    }} 
    }
}
				# ------------------------------
				# (3) skip 7fab if 7fab_A there
				# ------------------------------
foreach $id (@id) {
    next if (! $ok{$id});	# already excluded
    $num= substr($id,1,1);
    $name=substr($id,2);
    next if (length($name)==3);
    $tmpid=substr($id,2,3);	# 1pdb_C -> tmp='pdb'

				# get out older version!!
    if (defined $ok{$tmpid}) {
	$ok{$tmpid}=0;
	printf "%-6s kills %-6s\n",$id,$tmpid; 
    } 
}
				# ------------------------------
				# (4) new array with GOOD ones
				# ------------------------------
$#id2=0;
foreach $id (@id) {
    next if (! $ok{$id});	# already excluded
    push(@id2,$id); }
@id=@id2; $#id2=0;
				# ------------------------------
				# sort by PDBid (1aaa,2aab,1aac)
@id=&sort_by_pdbid(@id);

				# ------------------------------
				# (5) write output
				# ------------------------------
&open_file("$fhout",">$fileOut"); 
foreach $id (@id) { $tmp="";
		    $tmp.=$dir      if (defined $dir);
		    $tmp.=$id;
		    $tmp.=".".$ext  if (defined $ext);
		    print $fhout $tmp,"\n"; }
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
exit;
