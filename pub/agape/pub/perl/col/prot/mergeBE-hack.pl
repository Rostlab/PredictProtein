#!/usr/sbin/perl -w
#
# merges the files for buried and exposed into 40 aas
#
$[ =1 ;

				# include libraries
# push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<2){print"goal:   merges the files for buried and exposed into 40 aas\n";
	      print"usage:  script y4-swissExp.rdb y4-swissBur.rdb (out y4-both.rdb)\n";
	      exit;}

$fileInE=$ARGV[1];
$fileInB=$ARGV[2];

$fhin="FHIN";$fhout="FHOUT";
$AA="VLIMFWYGAPSTCHRKQEND";@aa=split(//,$AA);

$fileOut=$fileInE; $fileOut=~s/Exp/EB/;
if (($fileOut eq $fileInE) || ($fileOut eq $fileInB)){
    print"*** $fileOut wrong file out\n";exit;}

print "-- reading $fileInE\n";
&open_file("$fhin", "$fileInE");
$ct=$#idE=$#lineE=$#idB=$#lineB=0;$#header=0;
while (<$fhin>) {$_=~s/\n//g;$line=$_;
		 if (/^\#/)   {push(@header,$line);}
		 elsif ($ct<3){++$ct;push(@header,$line);}
		 else {++$ct;
		       $_=~s/^[\s\t]|[\s\t]$//;
		       @tmp=split(/\t+/,$_);$tmp[3]=~s/\s//g;$tmp[4]=~s/\s//g;
		       $id="$tmp[3],$tmp[4]";$id1=$tmp[3];
		       push(@idE,$id);push(@lineE,$line);}}close($fhin);

print "-- reading $fileInB\n";
&open_file("$fhin", "$fileInB");$ct=0;
while (<$fhin>) {$_=~s/\n//g;$line=$_;
		 if    (($_ !~ /^\#/)&&($ct<3)){++$ct;}
		 elsif ($_!~/^\#/){
		     $_=~s/^[\s\t]|[\s\t]$//;
		     @tmp=split(/\t+/,$_);$tmp[3]=~s/\s//g;$tmp[4]=~s/\s//g;
		     $id="$tmp[3],$tmp[4]";$id1=$tmp[3];
		     push(@idB,$id);push(@lineB,$line);}}close($fhin);
		 
print "--- read idE=",$#idE,", idB=",$#idB,",\n";
				# consistency check
$Lerr=0;
foreach $it (1..$#idE){
    if ($idB[$it] ne $idE[$it]){
	$Lerr=1;
	print "--- differ it=$it, idE=$idE[$it],idB=$idB[$it],\n";}
    else {
	print "--- ok ($idE[$it])\n";}}
if ($Lerr){
    exit;}

&open_file("$fhout", ">$fileOut");
				# header
print $fhout "# Perl-RDB\n# merging buried and exposed\n";
				# names
print $fhout "no\tloci\tid1\tid2\tlen1\tlen2\tlali\tnres\t";
foreach $aa (@aa){ print $fhout "b$aa\t"; }
foreach $aa (@aa){ if ($aa eq $aa[$#aa]){$sep="\n";}else{$sep="\t";}
		   print $fhout "e$aa$sep";}
				# formats
print $fhout "5N\t15S\t10s\t6N\t6N\t6N\t6N\t6N\t";
foreach $it (1..39){print $fhout "5.2F\t";}print $fhout "5.2F\n";
				# lines
foreach $it(1..$#idE){
    $lineE[$it]=~s/^[\s\t]*|[\s\t]$//g;
    $lineB[$it]=~s/^[\s\t]*|[\s\t]$//g;
    @t1=split(/\t/,$lineE[$it]);
    @t2=split(/\t/,$lineB[$it]);
    foreach $itc(1..8){		# general stuff
	print $fhout "$t1[$itc]\t";}
    foreach $itc (9..28){	# aa buried
	print $fhout "$t2[$itc]\t";}
    foreach $itc (9..27){	# aa exposed
	print $fhout "$t1[$itc]\t";}
    print $fhout "$t1[28]\n";
}
close($fhout);
print "-- output in $fileOut\n";

exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
