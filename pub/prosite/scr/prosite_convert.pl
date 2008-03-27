#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl
#
# This program converts a PROSITE-release (prosite.dat) file into a 
# file that can be used with prosite_scan.
#
# The call syntax is:
#        prosite_convert infile outfile
#

# some auxiliary procedures:

  sub initialize{
    $id="";
    $ac="";
    $de="";
    $pa="";
    $do="";
    $sk=0;
  }

  sub convert_out{
    
    if ($pa =~ /\.$/) {chop $pa} 
    $pa =~ tr/a-z/A-Z/;
    $newpa = '';
    
    while($pa) {
      ($part,$pa) = split(/-/,$pa,2);
      $beginflag=0;
      $endflag=0;
      $newpart='';
      
      if ($part =~ /^(\S+)\((\d+),(\d+)\)$/) {   # find xxx(n1,n2) 
        $mincount=$2;
	$maxcount=$3;
	$part=$1;
      }
      elsif ($part =~ /^(\S+)\((\d+)\)$/) {      # find xxx(n1)
        $mincount=$2;
	$maxcount=$2;
	$part=$1;
      }
      else {
        $mincount=1;
	$maxcount=1;
      }
      
      if ($part =~ /^\<(\S*)$/) {                # find <xxx
        $beginflag=1;
	$part=$1;
      }
      if ($part =~ /^(\S*)\>$/) {                # find xxx>
        $endflag=1;
	$part=$1;
      }
    
      if ($beginflag)                 {$newpart='^'};    
      
      if ($part eq 'X')               {$newpart .= '.'}     # find x
      elsif ($part=~/^[A-Z]$/)        {$newpart .= $part}   # find single res.
      elsif ($part=~/^\[[A-Z]*\]$/)   {$newpart .= $part}   # find [xxx]
      elsif ($part=~/^\{([A-Z]*)\}$/) {$newpart .= "[^$1]"} # find {xxx}
      else {warn "invalid pattern part $part\n"};
      
      if (($mincount!=1) || ($maxcount!=1)) {
        if ($mincount==$maxcount)     {$newpart .= "{$mincount}"}
	else                          {$newpart .= "{$mincount,$maxcount}" };
      }
      
      if ($endflag)                   {$newpart .= '$'};    
    
      $newpa .= $newpart;
    }
    print OUTFILE "$newpa $id $ac $do $sk \"$de\"\n";
  }

# test command line arguments and open files:
  
  if($#ARGV!=1)        {die "SYNTAX: prosite_convert infile outfile\n"};
  unless (-T $ARGV[0]) {die "$ARGV[0] no valid input file\n"};  
  open(INFILE,"$ARGV[0]")   || die "can't open $ARGV[0]: $!\n"; 
  open(OUTFILE,">$ARGV[1]") || die "can't open $ARGV[1]: $!\n";
 
# work loop
  
  &initialize;
  
  while (<INFILE>) {
    if (/^ID\s+(\w+);/) {                                #process ID-line
      $id=$1;
      print "$id\n";
    }
    elsif (/^DE\s+(.+)$/)          { $de=$1; chop $de }  #process DE-line
    elsif (/^AC\s+(\w+);/)         { $ac=$1 }            #process AC-line
    elsif (/^DO\s+(\w+);/)         { $do=$1 }            #process DO-line
    elsif (/^PA\s+(\S+)[\.\s]*$/)  { $pa.=$1 }           #process PA-line
    elsif (/SKIP-FLAG=TRUE/)       { $sk=1 }             #process Skip-flag
    elsif (/^\/\//) {                                    #process //-line
      if ($pa && $id) {&convert_out};
      &initialize;
    }
  }
  close(INFILE);
  close(OUTFILE);
    
