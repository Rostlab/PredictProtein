#!/usr/bin/perl
#
# Author: Kay Hofmann (khofmann@isrec-sun1.unil.ch) November 1994
#
# This program scans a protein sequence or database with a collection
# of regular expression patterns (like the one generated by prosite_convert).
# supported sequence formats are: 
# EMBL : single or multiple sequences 
# FASTA: single or multiple sequences
# GCG  : single sequences
#
# The call syntax is:
#        prosite_scan [-h -s] patternfile sequencefile
# 
#        -h : HTML output will be created
#        -s : abundant patterns will be skipped
#

$http_dat = 'HREF="http://www.expasy.ch/cgi-bin/get-prosite-entry?';
$http_doc = 'HREF="http://www.expasy.ch/cgi-bin/get-prodoc-entry?';
$htmlmode=0;
$skipmode=0;

# --------- Program starts here -----------------------------------

###################################################################
# test command line arguments and open files:
###################################################################
  
while ($ARGV[0]=~/^-/) {
    $agm = shift(@ARGV);
    $htmlmode=1 if ($agm=~/^\-?h/);
    $skipmode=1 if ($agm=~/^\-?s/); }

die "SYNTAX: prosite_scan [-h -s] patternfile sequencefile\n"   if ($#ARGV!=1);
die "$ARGV[0] no valid input file\n"  unless (-T $ARGV[0]);
die "$ARGV[1] no valid input file\n"  unless (-T $ARGV[1]);
open(PATFILE,"$ARGV[0]")   || die "can't open $ARGV[0]: $!\n"; 
open(SEQFILE,"$ARGV[1]")   || die "can't open $ARGV[1]: $!\n";
				# 
print "<pre>\n"                 if ($htmlmode);

###################################################################
# determine sequence file format
###################################################################

$line=<SEQFILE>;
if    ($line =~ /^\>/)        {$format="FASTA"}
elsif ($line =~ /^ID\s/)      {$format="EMBL"}
else  {
    while (! ($line =~ /\.\./) && ($line=<SEQFILE>)) {}
    if ($line=~/\.\./)        {
	$format="GCG"}
    else {
	die "Sequence format not recognized\n"}
}
close(SEQFILE);

###################################################################
# read all patterns from file
###################################################################

$ct=0;
while (<PATFILE>) {
    $ct=$ct+1;
    ($pattern[$ct], $patID[$ct], $patAC[$ct], $patDO[$ct], 
     $patSK[$ct],   $patDE[$ct]) = split(' ',$_,6);
				# 
    $patDE[$ct]=$1              if ($patDE[$ct] =~ /^\"(.*)\"$/);
				# SKIP this pattern!
    $ct=$ct-1                   if ($skipmode && ($patSK[$ct]==1));
}
$maxpat=$ct;
				#print "$maxpat patterns read\n";  
close(PATFILE);

###################################################################
# scan all patterns for each sequence found in file
###################################################################

open(SEQFILE,$ARGV[1])   || die "cannot reopen $ARGV[1]: $!\n";

				# for br: label
# $#matchesGlobal=0;
# $#seq=0;
				# store sequence

do {
    &getseq();
				# for br: label
#    @seq=split(//,$Seq)         if ($#seq<1);
    if ($Seq) {

	if ($htmlmode) { 
	    print "<B>-------------------------------------------------------------</B>\n";
	    if (length($SeqID)>0) {
		print "<B>$SeqID  $SeqDE</B>\n";
		print "<B>-------------------------------------------------------------</B>\n\n";}}
	else {
	    print "--------------------------------------------------------\n";
	    if (length($SeqID)>1) {
		print "$SeqID $SeqDE\n";
		print "--------------------------------------------------------\n\n";}}
				# ------------------------------
				# extract pattern (and write)
	&getpattern();

	print "\n";
    }
} until ($Seq eq "");
close(SEQFILE);


				# ------------------------------
				# for HTML mode: links

				# for br: label
# if ($htmlmode) {
#     foreach $match (@matchesGlobal) {
# 	next if ($match !~ /\d+\_\d+/);
# 	($beg,$end)=split(/_/,$match);
# 	$beg=~s/\D//g;$end=~s/\D//g;
# #	next if ($beg < 1 || $end > $len);
# 	$seq[$beg]="<A NAME=\"".$beg."_".$end."\">".$seq[$beg];
# 	$seq[$end]=$seq[$end]."</A>";
#     }
#     print "patterns in sequence:\n";
#     print "\n";
#     print join('',@seq),"\n";
#     print "\n";
# }

print "</pre>\n" if ($htmlmode);

exit;

##################################################################
# extract the pattern
##################################################################
sub getpattern {
    # --------------------------------------------------
    # GLOBAL in: $maxpat=     number of prosite patterns
    #            $pattern[$i]=ith pattern
    #            $Seq=        sequence from getseq
    # --------------------------------------------------
    for ($i=1; $i<=$maxpat; $i++) {
	@matches=();
	$end=$beg=1;
	while ($Seq =~ /$pattern[$i]/g) {
				# '$`' is the part before pattern
	    $beg= 1+length($`);
				# '$&' is the pattern
	    $end= $beg+length($&);
				# for br: label
#	    $beg_end=$beg."_".$end;
	    $beg="   $beg";
				# fill up blanks
	    while(length($beg)<=10) {
		$beg .= " "}
	    $match= "$beg ";
				# for br: label
#	    $match.="<A HREF=\"#".$beg_end."\">" if ($htmlmode);
	    $match.="$&";
				# for br: label
#	    $match.="</A>"                       if ($htmlmode);

	    push(@matches,$match);
				# for br: label
#	    push(@matchesGlobal,$beg_end)        if ($htmlmode);
	}
				# pattern found
	if (@matches) {
	    if ($htmlmode) {
		$outAC="<A $http_dat$patAC[$i]\">$patAC[$i]</A>" ;
		$outDO="<A $http_doc$patDO[$i]\">$patDO[$i]</A>" ;
		$outID="<B>$patID[$i]</B>"; }
	    else {
		$outAC=$patAC[$i];	  
		$outDO=$patDO[$i];	  
		$outID=$patID[$i]; }
	    print "Pattern-ID: $outID $outAC $outDO\n";
	    print "Pattern-DE: $patDE[$i]\n";
	    print "Pattern:    $pattern[$i]\n";
	    foreach $line (@matches) {
		print "$line\n"}
	    print "\n";}
    }
}

##################################################################
# get sequence in any format and put it into Seq, SeqID and SeqDE
##################################################################

sub getseq {
    if    ($format eq "FASTA") {
	&getfasta();
	$Seq   = $fastabuffer;
	$SeqID = $FastaID;
	$SeqDE = $FastaDE; }
    elsif ($format eq "EMBL")  {
	&getembl();
	$Seq   = $emblbuffer;
	$SeqID = $EmblID;
	$SeqDE = $EmblDE; }
    else                       {
	&getgcg();
	$Seq   = $gcgbuffer;
	$SeqID = $gcgid;
	$SeqDE = $gcgde; }
}
  
###################################################################
# read Pearson/FASTA format sequence (not to be called externally) 
###################################################################
  
sub getfasta {
    $fastabuffer="";
    $FastaID="";
    $FastaDE="";
    $line="";
    until (($fastaline =~ /^\>/) || 
	   eof(SEQFILE)) {
	$fastaline=<SEQFILE>};
    if ($fastaline=~/^\>(\S+)\s(.*)$/) {
	$FastaID=$1;
	$FastaDE=$2;
    }
    until (($line =~ /^\>/) || 
	   eof(SEQFILE)) {
	$line=<SEQFILE>;
	if (!($line =~ /^\>/)) {$fastabuffer .= $line}
    }
    if ($line =~ /^\>/) {$fastaline=$line}
    else {$fastaline=""};
    $fastabuffer =~ tr/a-z/A-Z/;
    $fastabuffer =~ s/[^A-Z]//g;
  }

###################################################################
# read EMBL/Swissprot format sequence (not to be called externally) 
###################################################################
    
sub getembl {
    $emblbuffer="";
    $EmblID="";
    $EmblDE="";
    $line="";
    until (($line =~ /^ID\s/) || eof(SEQFILE)) {$line=<SEQFILE>};
    if ($line=~/^ID\s+(\w+).*$/)          {$EmblID=$1;}
    until (($line =~ /^SQ\s/) || eof(SEQFILE)) {
      $line=<SEQFILE>;
      if ($line =~ /^DE\s+(.*)/) {
        if($EmblDE) {$EmblDE.=" "};
	$EmblDE .= $1
      }
    }
    if ($line =~ /^SQ\s/) {
      until (($line =~ /^\/\//) || eof(SEQFILE)) {
        $line=<SEQFILE>;
        if   (!($line =~ /^\/\//)) {$emblbuffer .= $line}
      }
    }
    $emblbuffer =~ tr/a-z/A-Z/;
    $emblbuffer =~ s/[^A-Z]//g;
  }
    
###################################################################
# read GCG format sequence (not to be called externally) 
###################################################################
  
sub getgcg {
    $gcgbuffer="";
    $gcgid=    "";
    $gcgde=    "";
    $line=     "";
    until (($line =~ /\.\./) || eof(SEQFILE)) {$line=<SEQFILE>};
    if ($line=~/^(\w*).*\.\./)                {$gcgid=$1;}
    until (eof(SEQFILE)) {
      $line=<SEQFILE>;
      $gcgbuffer .= $line
    }
    $gcgbuffer =~ tr/a-z/A-Z/;
    $gcgbuffer =~ s/[^A-Z]//g;
  }
    
