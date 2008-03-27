#!/usr/bin/perl

if( @ARGV<3 ) {
  printf STDERR "Usage: $0 <sequence> <pred_file> <alternatives> [<id>]\n";
  exit -1;
}

#font colors
@grey = ("#9f9e9e","#8f8e8e","#7f7e7e","#6f6e6e","#5f5e5e","#4f4e4e","#3f3e3e","#2f2e2e","#1f1e1e","#0f0e0e");
@red = ("#ffd7d7","#ffbfbf","#ffa1a1","#ff8686","#ff6b6b","#ff5353","#ff3c3c","#ff2929","#ff1515","#ff0000");

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
if( $idseq ne ""  ){
  printf "<table><tr><td><br><font size=5>Results for <b>$idseq</b></font>\n</td></tr>\n";
}
printf "<br><br><tr><td><div style=\"FONT-FAMILY: Courier\"><PRE>\n";

#read bridges 
my @bridges = read_bridges(\$bridgesconfidence,$nobonded);
my @bridges_rulers = make_rulers(@bridges);

my ($i,$c,$j,$b,$l);
$b=0;
for( $i=0; $i<$noaa; ) {

  #print bridges
  print_bridges($i,$noaa,@bridges_rulers);
    
  #print sequence  
  print "<a href=\"#DISULFIND_AA\">AA</a>       ";
  for( $j=0,$c=$i; $j<79 && $c<$noaa; $j++,$c++) {
    print substr($sequence,$c,1);
  }  
  print "\n";

  #print bonds
  print "<a href=\"#DISULFIND_DB_state\">DB_state</a> ";
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
    print "<a href=\"#DISULFIND_DB_conf\">DB_conf</a>  ";
    for( $j=0,$c=$i,$bb=$b; $j<79 && $c<$noaa; $j++,$c++) {
      my $aa = substr($sequence,$c,1);
      if( $aa eq 'C' ) {
	if($bondflipped[$bb] == 0){print "<FONT style=\"color:$grey[$bondconfidence[$bb]]\">";}
	else{print "<FONT style=\"color:$red[$bondconfidence[$bb]]\"";}
	print "$bondconfidence[$bb]";
	print "</FONT>";
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

if (@bridges){
  printf "<a href=\"#DISULFIND_Conn_conf\">Conn_conf</a> $bridgesconfidence<br>\n\n";
}

# print connectivity pattern alternatives 
$alt = 0;
@altname = ("Second","Third");

while(@bridges > 0){

    if($alt+1 >= $alternatives){
	last;
    }

    @bridges = read_bridges(\$bridgesconfidence,$nobonded);
    if(@bridges == 0){last;}

    printf "</PRE></div></td></tr>\n";
    printf "<tr><td><br><font size=5><b>$altname[$alt]</b> best ranking connectivity pattern</font>\n</td></tr>\n";
    printf "<br><br><br><tr><td><div style=\"FONT-FAMILY: Courier\"><PRE>\n";    
    $alt++;

    #make rulers 
    my @bridges_rulers = make_rulers(@bridges);

    my ($i,$c,$j,$b,$l);

    for( $i=0; $i<$noaa; ) {
	
	#print bridges
	print_bridges($i,$noaa,@bridges_rulers);
	
	#print sequence  
	print "<a href=\"#DISULFIND_AA\">AA</a>       ";
	for( $j=0,$c=$i; $j<79 && $c<$noaa; $j++,$c++) {
	    print substr($sequence,$c,1);
	}  
	print "\n\n";
		
	$i=$c;
    }
    printf "<a href=\"#DISULFIND_Conn_conf\">Conn_conf</a> $bridgesconfidence<br>\n";
}

close(BONDFILE);

if( $nobonded > 10){
	printf "Connectivity Pattern can be predicted for up to 5 bonds.\n\n";
}

printf "</PRE></div></td></tr><br><br>\n";

printf "<tr><td><UL>\n";
printf "<LI><b>Please cite:</b>\n";
printf "<UL>\n";
printf "<LI>A. Vullo and P. Frasconi, <i>Disulfide Connectivity Prediction using Recursive Neural Networks and Evolutionary Information</i>, Bioinformatics, 20, 653-659, 2004.\n";
printf "<LI>P. Frasconi, A. Passerini, and A. Vullo, <i>A Two-Stage SVM Architecture for Predicting the Disulfide Bonding State of Cysteines</i>, Proc. IEEE Workshop on Neural Networks for Signal Processing, pp. 25-34, 2002.\n";
printf "<LI>A.Ceroni, P.Frasconi, A.Passerini and A.Vullo, <i>Predicting the Disulfide Bonding State of Cysteines with Combinations of Kernel Machines</i>, Journal of VLSI Signal Processing, 35, 287-295, 2003.\n";
printf "</UL>\n";
printf "<LI><b>Contact information:</b>\n";
printf "<UL>\n";
printf "<LI>Questions and comments are very appreciated. Please, send email to: <A href=\"mailto:cystein\@dsi.unifi.it\">cystein\@dsi.unifi.it</a>\n";
#printf "<LI>Created by members of the Machine Learning and Neural Networks Group, Universita' di Firenze\n";
#printf "<LI>The server is hosted at the Department of Systems and Computer Science (DSI), Faculty of Engineering, Universita' di Firenze, Italy\n";
printf "</UL>\n";
printf "<LI><b>Abbreviations used:</b>\n";
printf "<UL>\n";
printf "<LI><b><a NAME=\"DISULFIND_AA\">AA</a></b>\n";
printf "amino acid sequence\n";
printf "<LI><b><a NAME=\"DISULFIND_DB_state\">DB_state</a></b>\n";
printf "predicted disulfide bonding state (1=disulfide bonded, 0=not disulfide bonded)\n";
if(@bondconfidence){
  printf "<LI><b><a NAME=\"DISULFIND_DB_conf\">DB_conf</a></b>\n";
  printf "confidence of disulfide bonding state
prediction (0=low to 9=high)<br> A red colour means that the viterbi
aligner overruled the most likely predition for that residue in order
to achieve a consistent prediction at a protein level (even number of
disulfide bonded cysteines, as interchain bonds are ignored). See papers for details.\n";
}
if (@bridges){
  printf "<LI><b><a NAME=\"DISULFIND_Conn_conf\">Conn_conf</a></b>\n";
  printf "confidence of connectivity assignment given the predicted disulfide bonding state (real value in [0,1])\n";
}
printf "</UL>\n";
printf "</UL></td></tr></table>\n";

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
