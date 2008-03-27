#!/usr/bin/perl -w
##!/usr/sbin/perl -w
$[ =1 ;

# ============================================================
# grep on SWISSPROT:
#
# egrep "^ID|^TRANSMEM"
#
# resulting file will be analysed here:
#
# - minimal number of HTM
# - topology known
# - topology known as 'probable'
#
# ============================================================

$min_tm=3;
$file_in=$ARGV[1];
$fhin="FHIN";
open($fhin, $file_in) || die "*** ERROR $0: failed opening file=$file_in!\n";

$#tmp=0;
while (<$fhin>) {		# read file
    $tmp=$_;$tmp=~s/\n//g;
    if (length($tmp)==0) { next; }
    push(@tmp,$tmp);
}
close($fhin);

$#tmp2=0;
foreach $it (1..$#tmp) {
    $line=$tmp[$it];
    if ($line !~ /^ID/) { push(@tmp2,$line);}
    else {
	if ($tmp[$it+1]=~/^ID/){
	    next;}
	else { push(@tmp2,$line);} }}

$#tmp=0;			# save storage
$it=1;
while ($it<=$#tmp2){
    $line=$tmp2[$it];
    $#tmp3=0;
    $Lis_top=$Lis_unk=0;
    if ($tmp2[$it]=~/^ID/){
#	print "x.x $tmp2[$it],\n";
	push(@tmp3,$tmp2[$it]);
	++$it;}
    else {
	print "*** ERROR for it=$it, it=$it, line=$tmp2[$it],\n";
	exit;}
    $Lok=0;
    $ct_tm=0;
    while ($tmp2[$it] =~/^FT/){
#	print "x.x $tmp2[$it],\n";
	$Lok=1;
	push(@tmp3,$tmp2[$it]);
	if ($tmp2[$it]=~/PLASMIC \(PROBABLE\)/){
	    $Lis_top=1;}
	if ($tmp2[$it]=~/TRANSMEM / ){
	    ++$ct_tm; }
	if ($tmp2[$it]=~/TRANSMEM .*\?/){
	    $Lis_unk=1;}
	++$it;}
    if ($Lis_top && (! $Lis_unk) && ($ct_tm>=$min_tm) ){
	foreach $tmp(@tmp3){
	    print "$tmp\n";}}
}
    
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================



1;
