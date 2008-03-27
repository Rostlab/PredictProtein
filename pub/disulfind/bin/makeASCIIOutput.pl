#!/usr/bin/perl

if( @ARGV<2 ) {
  printf STDERR "Usage: $0 <sequence> <pred_file> <alternatives> [<id>]\n";
  exit -1;
}

#primary sequence
my $sequence = $ARGV[0];
my $noaa = length($sequence);
my $nobonded = 0;

#parse prediction file
open(BONDFILE,'<',$ARGV[1]) or die("can't open file $ARGV[1]: $!");

# read alternatives
my $alternatives = $ARGV[2];

#read protein id
my $idseq = (@ARGV>=4) ? $ARGV[3] : "";

#read bonding states
my @bondstate;
my @bondconfidence;
my @bondflipped;
while(defined($row = <BONDFILE>)) {
  chomp($row);
  if( $row =~ "bonds" ) {
    next;
  }
  if( $row =~ "bridges" ) {
      last;
  }
  my @fields = split(" ",$row);
  my $currstate = $fields[0];
  push(@bondstate,($currstate));
  $nobonded += $currstate;
  if(int(@fields) > 1){
    my $currprob = $fields[2];
    my $confidence = int(abs($currprob - 0.5)*20);
    $confidence = ($confidence < 10) ? $confidence : 9; # single digit of confidence
    push(@bondconfidence, $confidence);
    my $flipped = ((2*$currstate-1)*($currprob-0.5) > 0 || ($currprob-0.5  == 0 && $currstate == 1)) ? 0 : 1;
    push(@bondflipped, $flipped);
  }
}

#find bonded cysteines in protein
my @bonded_cysteines;
for( my $c=0,$b=0; $c<$noaa; $c++) {
    $aa = substr($sequence,$c,1);
    if( $aa eq 'C' ) {
	if( $bondstate[$b]==1 ) {
	    push(@bonded_cysteines,($c));
	}
	$b++;    
    }
}  

#make output

printf "----------------------------------------------------------------------------------------\n";
printf "                                    DISULFIND                                  \n";
printf "              Cysteines Disulfide Bonding State and Connectivity Predictor     \n";
printf "----------------------------------------------------------------------------------------\n";
printf "\n\n";

if( $idseq ne ""  ) {
  printf "Query Name: $idseq\n\n\n";
}

#read bridges 
my @bridges = read_bridges(\$bridgesconfidence,$nobonded);
my @bridges_rulers = make_rulers(@bridges);

my ($i,$c,$j,$b,$l);
$b = 0;
for( $i=0; $i<$noaa; ) {

  #print bridges
  print_bridges($i,$noaa,@bridges_rulers);
  
  #print sequence  
  print "AA       ";
  for( $j=0,$c=$i; $j<79 && $c<$noaa; $j++,$c++) {
    print substr($sequence,$c,1);
  }  
  print "\n";

  #print bonds
  print "DB_state ";
  for( $j=0,$c=$i,$bb=$b; $j<79 && $c<$noaa; $j++,$c++) {
    my $aa = substr($sequence,$c,1);
    if( $aa eq 'C' ) {
      print "$bondstate[$bb]";
      $bb++;
    }
    else {
      print " ";
    }   
  }  
  print "\n";

  if(@bondconfidence){
    #print confidence
    print "DB_conf  ";
    for( $j=0,$c=$i,$bb=$b; $j<79 && $c<$noaa; $j++,$c++) {
      my $aa = substr($sequence,$c,1);
      if( $aa eq 'C' ) {
	print "$bondconfidence[$bb]";
	$bb++;
      }
      else {
	print " ";
      }   
    }  
    print "\n";
    
    #print flipping
    print "DB_flip  ";
    for( $j=0,$c=$i,$bb=$b; $j<79 && $c<$noaa; $j++,$c++) {
      my $aa = substr($sequence,$c,1);
      if( $aa eq 'C' ) {
	if($bondflipped[$bb] == 1){
	  print "*";
	}	
	$bb++;
      }
      else {
	print " ";
      }   
    }  
    print "\n";
  }
  print "\n";
  $b = $bb;
  $i=$c;
}

if( @bridges ) {
  printf "Conn_conf $bridgesconfidence\n\n";
}

# print connectivity pattern alternatives 
$alt = 0;
@altname = ("SECOND","THIRD");

while(@bridges > 0){

    if($alt+1 >= $alternatives){
	last;
    }

    @bridges = read_bridges(\$bridgesconfidence,$nobonded);
    if(@bridges == 0){last;}

    printf "----------------------------------------------------------------------------------------\n";
    printf "\n$altname[$alt] best ranking connectivity pattern\n\n\n";
    $alt++;

    #make rulers 
    my @bridges_rulers = make_rulers(@bridges);

    my ($i,$c,$j,$b,$l);
    
    for( $i=0; $i<$noaa; ) {
	
	#print bridges
	print_bridges($i,$noaa,@bridges_rulers);
	
	#print sequence  
	print "AA       ";
	for( $j=0,$c=$i; $j<79 && $c<$noaa; $j++,$c++) {
	    print substr($sequence,$c,1);
	}  
	print "\n\n";
		
	$i=$c;
    }
    printf "Conn_conf $bridgesconfidence\n\n";
}

close(BONDFILE);

if( $nobonded > 10){
	printf "Connectivity Pattern can be predicted for up to 5 bonds.\n\n";
}

printf "----------------------------------------------------------------------------------------\n";
printf "\nAbbreviations used:\n\n";
printf "AA        = amino acid sequence\n";
printf "DB_state  = predicted disulfide bonding state\n"; 
printf "            (1=disulfide bonded, 0=not disulfide bonded)\n";
if(@bondconfidence){
  printf "DB_conf   = confidence of disulfide bonding state prediction (0=low to 9=high)\n";
  printf "DB_flip   = an asterisk (*) indicates that the viterbi aligner overruled the\n";
  printf "            most likely predition for that residue in order to achieve a\n";
  printf "            consistent prediction at a protein level (even number of disulfide\n";
  printf "            bonded cysteines, as interchain bonds are ignored).\n";
}
if( @bridges ) {
  printf "Conn_conf = confidence of connectivity assignment given the predicted disulfide\n";
  printf "            bonding state (real value in [0,1])\n\n";
}
printf "----------------------------------------------------------------------------------------\n";
printf "\nPlease cite:\n\n";
printf "A. Vullo and P. Frasconi, \"Disulfide Connectivity Prediction using Recursive\n"; 
printf "Neural Networks and Evolutionary Information\", Bioinformatics,20,653-659,2004.\n\n";
printf "P. Frasconi, A. Passerini, and A. Vullo, \"A Two-Stage SVM Architecture for\n"; 
printf "Predicting the Disulfide Bonding State of Cysteines\", Proc. IEEE Workshop on\n";
printf "Neural Networks for Signal Processing, pp. 25-34, 2002.\n\n";
printf "A.Ceroni, P.Frasconi, A.Passerini and A.Vullo, \"Predicting the Disulfide\n";
printf "Bonding State of Cysteines with Combinations of Kernel Machines\", Journal of\n";
printf "VLSI Signal Processing, 35, 287-295, 2003.\n\n";
printf "----------------------------------------------------------------------------------------\n";
printf "\nQuestions and comments are very appreciated.\n";
printf "Please, send email to: cystein\@dsi.unifi.it\n\n";

printf "Copyright 2003-2006, Machine Learning and Neural Network Group\n";
printf "Universita' di Firenze\n\n";

printf "The server is hosted at Dipartimento di Sistemi e Informatica\n";
printf "Universita' di Firenze, Italy\n\n";
printf "----------------------------------------------------------------------------------------\n";

sub make_bridges {

  my @bridges;  
  
  my ($nobridges,$noaa,@ind_bridges) = @_;
  if( $nobridges==0 ) {
    return @bridges;
  }

  my @start_bridge;
  my @end_bridge;   
  for( my $i=0; $i<$nobridges; $i++ ) {
    $start_bridge[$i] = $ind_bridges[$i][0];
    $end_bridge[$i] = $ind_bridges[$i][1];
  }
  
  # count maximum number of crossing bridges
  my $nocrossings = 0;
  my $noactivebridges = 0;
  for( my $i=0; $i<$noaa; $i++ ) {
    # look for starting bridges
    for( my $j=0; $j<$nobridges; $j++ ) {
      if( $start_bridge[$j]==$i ) {
	$noactivebridges++;
      }
    }    
    # look for ending bridges
    for( my $j=0; $j<$nobridges; $j++ ) {
      if( $end_bridge[$j]==$i ) {
	$noactivebridges--;
      }
    }    
    if( $noactivebridges>$nocrossings ) {
      $nocrossings = $noactivebridges;
    }
  }

  # make bridges representations
  my @activebridges;
  for( my $i=0; $i<$nocrossings; $i++ ) {
    $activebridges[$i] = 0;
    $bridges [$i] = "";
  }
  $bridges[$nocrossings] = "";

  for( my $i=0; $i<$noaa; $i++ ) {
    my $vertical = 0;

    # look for starting bridges
    for( my $j=0; $j<$nobridges; $j++ ) {
      if( $start_bridge[$j]==$i ) {
	# occupy a line
	for( my $l=0; $l<$nocrossings; $l++ ) {
	  if( $activebridges[$l]==0 ) {
	    $activebridges[$l] = $j+1;
	    $vertical = $l+1;
	    last;
	  }
	}
      }
    }    
    # look for ending bridges
    for( my $j=0; $j<$nobridges; $j++ ) {
      if( $end_bridge[$j]==$i ) {
	# free a line
	for( my $l=0; $l<$nocrossings; $l++ ) {
	  if( $activebridges[$l]==($j+1) ) {
	    $activebridges[$l] = 0;
	    $vertical = $l+1;
	    last;
	  }
	}
      }
    }

    # look for busy lines
    if( $vertical>0 ) {
      $bridges[0] .= '|' ;
    }
    else {
      $bridges[0] .= ' ';
    }
    for( my $l=1; $l<=$nocrossings; $l++ ) {
      if( $l==$vertical ) {
	$bridges[$l] .= '+';
      }
      elsif( $l<$vertical ) {
	$bridges[$l] .= '|';	
      }
      elsif( $activebridges[$l-1]==0 ) {
	$bridges[$l] .= ' ';	
      }
      elsif( $activebridges[$l-1]>0 ) {
	$bridges[$l] .= '-';	
      }
    }
  }

  #my $bridges_ruler = "";
  #for( my $l=$nocrossings; $l>0; $l-- ) {
  #  $bridges_ruler .= "$bridges[$l]\n";
  #}
  #$bridges_ruler .= "$bridges[0]";  
  #return $bridges_ruler;

  return @bridges;
}

sub print_bridges {

    my ($i,$noaa,@bridges_rulers) = @_;

    #print bridges
    for( my $l=@bridges_rulers-1; $l>=0; $l-- ) {
	print "         ";
	for( $j=0,$c=$i; $j<79 && $c<$noaa; $j++,$c++) {	  
	    print substr($bridges_rulers[$l],$c,1);
	}
	print "\n";
    }	
    
    
    #print ruler  
    print "         ";
    my $wait = 0;
    for( $j=0,$c=$i; $j<79 && $c<$noaa; $j++,$c++) {
	if( $wait>0 ) {
	    $wait--;
	}	
	my $ca = $c+1;
	if( $ca%10==0 ) {
	    print $ca;
	    $wait=1;
	    if( $ca>=10 ) {
		$wait++;
	    }	
	    if( $ca>=100 ) {
		$wait++;
	    }	
	    if( $ca>=1000 ) {
		$wait++;
	    }	
	}
	elsif( $wait==0 ) {
	    print "."
	    }   
    }  
    print "\n";
    
}


sub make_rulers {

    my (@bridges) = @_;

    my $nobridges = int(@bridges);

    #read bridges (<index first cysteine> <index second cysteine>)
    my @ind_bridges;
    for( my $i=0; $i<$nobridges; $i++ ) {
	push(@ind_bridges,[$bonded_cysteines[$bridges[$i][0]-1],$bonded_cysteines[$bridges[$i][1]-1]]);
    }

    return make_bridges($nobridges,$noaa,@ind_bridges);
}


sub read_bridges {
    
    my $bridgesconfidence = shift;
    my $nobonded = shift;
    my $nobridges = $nobonded/2;

    my @bridges;
    while(defined($row = <BONDFILE>)) {
	chomp($row);
	@bridge = split(" ",$row);
	if( @bridge<1 ) {
	    next;
	}
	if( @bridge==1 ) {  
	    $$bridgesconfidence = $bridge[0];
	}
	if( $bridge[0] < $bridge[1] ) {
	    push(@bridges,[$bridge[0],$bridge[1]]);
	}
	if (@bridges == $nobridges){
	    last;
	}
    }
    return @bridges;
}
