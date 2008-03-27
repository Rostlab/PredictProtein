#!/usr/sbin/perl -w
#
#  takes the references in one line and writes list
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   takes the references in one line and writes list\n";
	      print"usage:  script line ol (or ul: ordered/unordered list)\n";
	      exit;}

$fileIn=$ARGV[1];$fhin="FHIN";$fhout="FHOUT";$fileOut="Out-".$fileIn;
if   ($ARGV[2]=~/^ol/){$Lorder=1;}
elsif($ARGV[2]=~/^ul/){$Lorder=0;}else{print "*** give ol or ul\n";
								       exit;}
&open_file("$fhin", "$fileIn");
$rd="";
while (<$fhin>) {$_=~s/\n//g;$rd.=$_;}close($fhin);
				# split
print "xx rd=|$rd| end of read\n";
				# normal...
@tmp=split(/\s*\d+\.\s+/,$rd);
				# now hack:
$tmp=$rd;		# no numbers given (e.g. JMB style)
$tmp=~s/\.[0-9]+\. ([A-Z])/\t$1/g; # split '121-123.3. Bairoch'
print "xx now=$tmp\n";
@tmp=split(/\t/,$tmp);

if ($#tmp==1){$tmp=$rd;		# if no numbers given (e.g. JMB style)
	      $tmp=~s/([a-z][a-z]\.)([A-Z][a-z])/$1\t$2/g; # split 'new york.Bairoch'
	      $tmp=~s/(\d+\-\d+\.)([A-Z][a-z])/$1\t$2/g; # split '121-123.Bairoch'
	      @tmp=split(/\t/,$tmp);}


&open_file("$fhout",">$fileOut"); 
print $fhout "<HTML>\n","<BODY>\n";
    
if ($Lorder){print $fhout "<OL>\n";}else{print $fhout "<UL>\n";}
foreach $tmp(@tmp){
    print $fhout "<LI> $tmp\n";
    print "$tmp\n";
}
if ($Lorder){print $fhout "</OL>\n";}else{print $fhout "</UL>\n";}
print $fhout "</BODY>\n","</HTML>\n";
close($fhout);

print "--- output in $fileOut\n";
exit;
