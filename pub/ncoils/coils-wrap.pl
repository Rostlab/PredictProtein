#!/usr/bin/perl -w
#!/usr/local/bin/perl -w

$|=1;
use Getopt::Long;


# Runs coils multiply to give you a three-window output
# Rob Russell 
# Contact: russelr1@mh.uk.sbphrd.com
# You may need to change these, in addition 
# to the "/usr/local/bin/perl" above if necessary
#
$ARCH=$ARCH || &getSysARCH();	# 

if (!defined $ENV{"COILSDIR"}) {
	$ENV{"COILSDIR"} = "/nfs/data5/users/$ENV{USER}/server/pub/ncoils/src";
}

$coils_root = "/nfs/data5/users/$ENV{USER}/server/pub/ncoils/src";
# GY 2003_9_10 Commented out IRIX ver 
# ARCH is now determined dynamically
#$coils_exec = "/home/$ENV{USER}/server/bin/ncoils.SGI64";
$coils_exec = "/nfs/data5/users/$ENV{USER}/server/bin/ncoils.".$ARCH;

$tmpdir = "";

undef($in_seq);
undef($id);
$mode = "threewin";
$weighted = "";
$matrix = "MTK";
#$win    = "21";
$extra  =  "";


$nameScr = $0;
$nameScr =~ s/.*\///g;

$Lok = GetOptions ("m=s"    => \$matrix,
		   "w!"   => \$opt_weight,
		   "i=s" => \$fastafile,
		   "o=s" => \$outfile,
		   "r=s" => \$fileRaw,
		   #"debug"    => \$opt_debug,
		   #'help'     => \$opt_help);
		   );


if ( ! $Lok ) {
    print STDERR 
	"Invalid arguments found, -h or --help for help\n",
	"Usage: $nameScr [options]  -i fastafile -o out_file -r raw_file\n",
	"   -m [matrix type]  set matrix (MTK or MTIDK)\n",
	"   -w                weight a&d = b,c,e,f&g\n",
        "Try $nameScr --help for more information\n";
    
    exit(1);
}


if ( ! $fastafile or ! $outfile ) {
    print STDERR
        "Usage: $nameScr [options]  -i fastafile -o out_file -r raw_file\n",
	"   -m [matrix type]  set matrix (MTK or MTIDK)\n",
	"   -w                weight a&d = b,c,e,f&g\n",
        "Try $nameScr --help for more information\n";
    exit(1);
}

if ( ! -f $fastafile ) {
    print STDERR
        "input file '$fastafile' not found, exiting..\n";
    exit(1);
}

$fileRaw = $outfile."_raw" if ( ! defined $fileRaw );

$matrix = uc($matrix);
if ( $opt_weight ) {
    $weighted = " -w ";
}




# russell's way to parse argument

#for($i=0; $i<=$#ARGV; ++$i) {
#   if($ARGV[$i] eq "-m") { # matrix file
#      if(($i+1)>($#ARGV)) { exit_error(); }
#      $matrix = uc($ARGV[$i+1]);
#      $i++;
#   } elsif($ARGV[$i] eq "-w") { # matrix file
#        $weighted = " -w ";
#   } elsif(!defined($fastafile)) {
#        $fastafile = $ARGV[$i];
#   } else {
#        exit_error();
#   }
#}

sub exit_error {
   print STDERR "coils-wrap.pl [options] [fasta file] [output file]\n";
   print STDERR "   -m [matrix type]  set matrix (MTK or MTIDK)\n";
   print STDERR "   -w                weight a&d = b,c,e,f&g\n";
   exit;
}

@data = read_align($fastafile,$type);
if($type ne "f") {
   die "Error file must be in FASTA format\n";
}

$extra .= $weighted;

if($matrix eq "MTK") {
   $extra .= " -m " . $coils_root . "/old.mat";
} elsif($matrix ne "MTIDK") {
   die "Error matrix must be one of MTK or MTIDK\n";
}

$seqfile = $tmpdir . "coils." . $$ . ".fasta";

$seqs = get_afasta(@data);

#print "What should appear below is the result of running COILS three \n";
#print "times with windows of 14,21 & 28.\n`frame' denotes the predicted \n";
#print "position of the heptad repeat for the highest scoring window that \n";
#print "overlaps each position.\n`prob' gives a single integer value \n";
#print "representation of P (where 0-9 covers the range 0.0-1.0)\n";
#print "This will be repeated for each sequence \n\n\n";

#print "A total of $seqs->{nseq} sequences found in $fastafile\n\n\n";
for($n=0; $n<$seqs->{nseq}; ++$n) {
   $id = $seqs->{list}[$n];
   $in_seq = $seqs->{ids}{$id}{seq};
   $in_seq =~ s/[\s\-\.]//g;
#   print "ID $id seq $seq\n";

   &write_fasta($seqfile,$id,$in_seq);
   @result = ();
   push @result, ">$id\n\n";
   if($mode eq "threewin") {
           # Runs threewin style mode
           # Three windows 14,21,28
           # printf("%4d %c %c %7.3f %7.3f (%7.3f %7.3f)\n",i+1,seq[i],hept_seq[i],score[i],P[i],Gcc,Gg);
           $align = {};
           $align->{file} = "";
           $align->{ids}  = ();
           $align->{list} = ();

           $align->{nseq} = 7;
           $align->{ids}{$id}{seq} = $in_seq;
           $align->{alen} = length($in_seq);
           $align->{list}[0] = $id;

           for($i=14; $i<=28; $i+=7) {
               $j=($i-14)/7;
               $command = $coils_exec . $extra . " -win " . $i . " < " . $seqfile;
	       if ( $i == 28 ) {
		   open (RAW,">$fileRaw") or die "cannot write to $fileRaw:$!";
	       }
   	       print "Command is $command\n";
               open(IN,"$command|");

               $fid = "frame-" . $i;
               $pid = "prob-" . $i;
               $align->{ids}{$fid}{seq} = "";
               $align->{ids}{$pid}{seq} = "";
               $align->{ids}{$pid}{Ps} = ();
               $align->{list}[1+$j] = $fid;
               $align->{list}[4+$j] = $pid;

               $p=0;
               while(<IN>) {
		   if ( $i == 28 ) { # print the raw file if window is 28
		       print RAW $_;
		   }
		   if ( /^\#/ ) {
		       chomp($result = $_);
		       $result =~ s/.*aas//;
		       $result =~ s/in coil\s*//g;
		       $result = "window size = $i ".$result." residues in coiled coil".
			   " domain\n";
		       push @result, $result;
		       next;
		   } else {
                       $_ =~ s/^ *//;
                       @t=split(/ +/);
                       $align->{ids}{$fid}{seq} .= $t[2];
                       $align->{ids}{$pid}{Ps}[$p] = $t[4]; # Raw P value
                       $p++;
                       $P = $t[4]*10;
                       if($P>=10) { $sP = "9"; }
                       else { $sP = substr($P,0,1); }
                       if($sP eq "0") { $sP = "-"; }
                       $align->{ids}{$pid}{seq} .= $sP;
                   } 
               }
               close(IN);
           }
	   
  
	   if ( defined($outfile)) { # Write output to file
	       write_clustal($align,\@result, $outfile);
	   } else {
	       write_clustal($align,\@result, "-");
	   }
       }
}  
unlink $seqfile;	     

exit;

sub write_fasta {
   my($fn,$id,$seq) = @_;
   open(SEQ,">$fn") || die "$fn wouldn't open\n";
   print SEQ ">$id\n";
   $i=0;
   while($i<length($seq)) {
      $aa = substr($seq,$i,1);
      print SEQ $aa;
      if((($i+1)%50)==0){ print SEQ "\n" }
      $i++;
   }
   print SEQ "\n";
   close SEQ;
}
sub write_clustal {

        my($align) = $_[0];
        my($i,$j,$k,$id);

	my($header)= $_[1];
        my($outfile) = $_[2];
        open(OUT,">$outfile") || die "Error opening output file $outfile\n";

#        print OUT "CLUSTAL W(1.60) multiple sequence alignment\n\n";
	
	print OUT @$header;
	print OUT "\n";

        foreach $id (keys %{$align->{ids}}) {
                if(defined($align->{ids}{$id}{start})) {
                        $align->{ids}{$id}{newid} = $id . "/" . ($align->{ids}{$id}{start}+1) . "-" . ($align->{ids}{$id}{end}+1);
                        if(defined($align->{ids}{$id}{ranges})) {
                                $align->{ids}{$id}{newid} .= $align->{ids}{$id}{ranges};
                        }
                } else {
		    if ( $id !~ /frame/ and $id !~ /prob/) {
			$align->{ids}{$id}{newid} = "seq";
		    } else {
			$align->{ids}{$id}{newid} = $id;
		    }
                }		# 
	    }
    				# 
	$i=0;

        while($i<$align->{alen}) {
	    #printf OUT "%-10s ";
	    for ($z = 1; $z <=50; $z++) {
		if ($z == 50) {
		    print OUT ($i+50)/10 ;
		} elsif ($z % 10 == 0) {
		    print OUT ":";
		} elsif ($z % 5 == 0) {
		    print OUT ".";
		} else {
		    print OUT " ";
		}
	    }
	    print OUT "\n";
	    
	    for($k=0; $k<$align->{nseq}; ++$k) {
		$id = $align->{list}[$k];
	#	printf(OUT "%-10s ", "seq");
		printf(OUT "%-10s ",$align->{ids}{$id}{newid});
		for($j=0; $j<50; ++$j) {
		    last if(($i+$j)>=$align->{alen});
		    print OUT substr($align->{ids}{$id}{seq},($i+$j),1);
		}
		print OUT "\n";
	    }
	    $i+=50;
        }
	print OUT "// End\n\n"; 
        close OUT;
}

sub get_afasta {


# Get aligned FASTA data (i.e. afasta = aligned fasta)
#
# Assumes that only "-" characters are gaps (treats as spaces internally)
#  (actually, of course this means spaces will be gaps, or maybe they should be ignored
#  strange dilemma that I have got myself into.  For the minute they will just be kept as is
#  (spaces are gaps as well).  This could lead to some problems.

   my(@data) = @_;
   my($align,$i,$j,$k,$n);

   $align = {};

   $align->{ids}  = ();
   $align->{list} = ();
   $align->{nseq} = 0;

   my($name_count) = 0;
   for($n=0; $n<=$#data; ++$n) {
	$_ = $data[$n];
	chop;
	if(/^>/) {
		$label = substr($_,1);
		$label =~ s/ .*//;
		$postbumpf = $_; $postbumpf =~ s/>[^ ]* //;
	  	if(defined($align->{ids}{$label})) {
			$label = $label . "-" . $name_count;
	  	}
	  	$align->{list}[$name_count]=$label;
		$align->{ids}{$label}{seq} = "";
		$align->{ids}{$label}{postbumpf} = $postbumpf;
		$name_count ++;
	} else {
		if(defined($align->{ids}{$label})) {
			$_ =~ s/-/ /g;
			$align->{ids}{$label}{seq} .= $_;
#			print "Adding $_ to $label\n";
		}
	}
   }
   $align->{nseq} = $name_count;
   $align->{alen} = length($align->{ids}{$align->{list}[0]}{seq});
   $align->{id_prs} = get_print_string($align);
   return $align;
}

sub read_align { # Just read in text and modify format if necessary

#
# Likely format is determined by looking for signs of one format over another
#  and storing them in %votes.  This won't always work, of course, but
#  generally the user can force one format over another, check to see
#  if the second variable passed to the routine is "x", and complain
#  if so. 
#

    my(%votes) = ( "m" => 0, 
                   "c" => 0, 
                   "b" => 0, 
                   "f" => 0, 
                   "p" => 0,
                   "s" => 0,
		   "h" => 0,  
		   "e" => 0,
                   "y" => 0 );

   my($file) = $_[0];
   my(@data);
   my($i,$type);
   my($winner,$highest);

   @data=();


   open(IN,$file) || die "$file wouldn't open in read_align\n";

   $block_start=0; $block_end=0; 
   while(<IN>) { push(@data,$_); }
   close(IN);

   for($i=0; $i<=$#data; ++$i) {
	$_ = $data[$i];
        if(($i==0) && ($_  =~ / *[0-9]+ +[0-9]+ */)) { $votes{"y"}+=1000; }
	elsif(($_ =~ /^ *Name:/) || ($_ =~ /pileUp/) || ($_ =~ /MSF.*Check.*\.\./)) { $votes{"m"}++; last; }
	elsif($_ =~ /^CLUSTAL/) { $votes{"c"}+=10; last; }
	elsif($_ =~ /^>P1;/) { $votes{"p"}+=10;  last; }
   	elsif($_ =~ /HMMER/) { $votes{"h"}+=10; last; }
   	elsif(($_ =~ /^#=SQ/) || ($_ =~ /^#=RF/)) { $votes{"h"}++; }
	elsif($_ =~ /^>/) { $votes{"f"}++; $votes{"b"}++;  }
	elsif($_ =~ /^ *\* iteration [0-9]*/) { $votes{"b"}++; $block_start++; }
	elsif($_ =~ /^ *\*/) { $votes{"b"}++; $block_end++; }
	elsif(($_ =~ /^ID  /) || ($_ =~ /^CC  /) || ($_ =~ /^AC  /) || ($_ =~ /^SE  /)) { $votes{"s"}++; }
        elsif(($_ =~ /^HSSP .*HOMOLOGY DERIVED SECONDARY STRUCTURE OF PROTEINS/)) { $votes{"e"}+=1000; }

   }

   # Block and FASTA are quite hard to tell apart in a quick parse,
   #  This hack tries to fix this
   if(($votes{"f"} == $votes{"b"}) && ($votes{"f"}>0)) {
	if($block_start==0) { $votes{"f"}++; }
    	if($block_end==0) { $votes{"f"}++; }
   }

   $winner = "x";
   $highest = 0;
   foreach $type (keys %votes) {
#	print $type," ", $votes{$type},"\n";
	if($votes{$type}>$highest) { $winner = $type; $highest = $votes{$type}; }
   }
#   print "File is apparently of type $winner\n";
   $_[1] = $winner;
   return @data;
}
sub get_print_string {
        my($align) = $_[0];
        my($max_len);
        my($i);

        $max_len = 0;
        for($i=0; $i<$align->{nseq}; ++$i) {
                $this_len = length($align->{list}[$i]);
                if($this_len > $max_len) { $max_len = $this_len; }
        }
        return $max_len;
}

#===============================================================================
sub getSysARCH {
    local($exePvmgetarch,@argLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSysARCH                  tries to get the system architecture
#                               
#       in:                     $exePvmgetarch:  bin-shell script to get ARCH
#                                  = 0           to not execute that one..
#       in:                     @argLoc:         all arguments passed to program, checks
#                                                for one with:
#                                  ARCH=SGI64    .. or so
#       out:                    <0,$ARCH>
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."getSysARCH";

    $archFound=0;
    $exePvmgetarch=0            if (! defined $exePvmgetarch);

				# ------------------------------
				# (1) find in arguments passed
				# ------------------------------
    if (defined @argLoc && $#argLoc > 0) {
	foreach $arg (@argLoc) {
	    if ($arg=~/^ARCH=(\S+)/i) {
		$archFound=$1;
				# archs are upper case: convert
		$archFound=~tr/[a-z]/[A-Z]/;
		last; }} }
    return($archFound)          if ($archFound);
	
				# ------------------------------
				# (2) try env asf
				# ------------------------------
    $archFound=$ENV{'ARCH'} || $ENV{'CPUARC'} || 0;
    return($archFound)          if ($archFound);

				# ------------------------------
				# (3) run bin shell script given
				# ------------------------------
    if ($exePvmgetarch && (-e $exePvmgetarch || -l $exePvmgetarch)) {
	$scr=$exePvmgetarch;
	$archFound=`$scr`;	# system call
	$archFound=~s/\s|\n//g; 
	$archFound=0            if (length($archFound < 3) || $archFound !~ /[A-Z][A-Z]/);}
    return($archFound)          if ($archFound);

				# ------------------------------
				# (4) search bin shell script 
				# ------------------------------
    foreach $possible ("/nfs/data5/users/ppuser/server/pub/phd/scr/pvmgetarch.sh",
		       "/home/rost/pub/phd/scr/pvmgetarch.sh",
		       "/home/rost/etc/pvmgetarch.sh") {
	if (-e $possible || -l $possible) {
	    $exePvmgetarch=$possible; 
	    last; }}
				# somewhere in relative paths
    if (! $exePvmgetarch) {
	$dirRelative=$0; $dirRelative=~s/\.\///g; $dirRelative=~s/^(.*\/).*$/$1/;
	foreach $possible ("scr/pvmgetarch.sh","scr/which_arch.sh",
			   "bin/pvmgetarch.sh","bin/which_arch.sh",
			   "etc/pvmgetarch.sh","etc/which_arch.sh",
			   "pvmgetarch.sh","which_arch.sh") {
	    $tmpPossible= "$dirRelative$possible";
	    if (-e $tmpPossible || -l $tmpPossible) {
		$exePvmgetarch=$tmpPossible; 
		last; }}}

				# ******************************
				# script not found
    return(0)                   if (! $exePvmgetarch);
				# ******************************
	
				# ------------------------------
				# (5) run bin shell script 
				# ------------------------------
    $scr=$exePvmgetarch;
    $archFound=`$scr`;		# system call
    $archFound=~s/\s|\n//g; 
    $archFound=0               if (length($archFound) < 3 || $archFound !~ /[A-Z][A-Z]/);
    return($archFound);
}				# end of getSysARCH
#===============================================================================
