#! /bin/env perl5
use Graph;
for($i=0;$i<@ARGV;){
  if($ARGV[$i] eq '-comment'){
    $AddComments = 1;
    splice(@ARGV,$i,1);
  }else{
    $i++;
  }
}

while (<>) {
  if (/^\#/) { 
    next;
  }else{
    $_=<>;
    last;
  }
}

@table = <>;


  
$style{"server"} = "rhomb" ;
$style{"viewer"} = "ellipse" ;

#$biggraph = new Graph "GQ flowchart";

#initialize the big graph
$graphs{''} = new Graph ("GeneQuiz flowchart"); 

foreach $entry (@table) {
  $color = "white" ;
  $Color = '';
  chop $entry ;
  my ($nr,$name,$depend,$note,$type,$module) = split('\t',$entry,6) ;
  $node = new Node ($name);
  # decode hirarchy of modules
  my (@modules)  = split /:/ , $module;

  my ($module,$m);
  $module=$m= pop @modules;
  # generate new graph if required
  unless (defined $graphs{$m}){
    ($title="+++++   " . $m . "   +++++" )=~ tr /a-z/A-Z/;
    $graphs{$m}= new Graph ($title);
    # put it in the necessary supergraph:
    my($supermodule)= undef;
    while($m){
      $supermodule =  pop @modules;
      unless (defined $graphs{$supermodule}){
	($title="+++++   " . $supermodule . "   +++++" )=~ tr /a-z/A-Z/;
	$graphs{$supermodule}= new Graph ($title);
	$graphs{$supermodule}->add_content($graphs{$m});
	$m = $supermodule;
      }else{
	$graphs{$supermodule}->add_content($graphs{$m});
	last;
      }
    }
  }

  $graphs{$module}->add_content($node);

  # encode the type of program
   if ($type =~ m/program/ ) {
    $node->bordercolor("blue");
  } elsif ($type =~ m/perl/ ) {
    $node->bordercolor("red");
  } elsif ($type =~ m/data/ ) {
    $node->bordercolor("green");
  } elsif ($type =~ m/method/ ) {
    $node->bordercolor("cyan");
  }
 

  $hash{"$nr"} = $name ;
  $module{$nr} = $module;
}


foreach $entry (@table) {
  
  my($nr,$name,$depend,$note,$type,$module) = split('\t',$entry,6) ;
  foreach $edge (split (';',$depend)) {
    next if($edge =~ /\?\?/);
    $ed = new Edge ($name , $hash{$edge});
    my (@dummy)= split /:/, $module;
    $module = pop @dummy;
    if($module && $module eq $module{$edge}){
      $ed->priority(50);
      $ed->{thickness} = 4;
    }
    $graphs{$module}->add_content($ed);

    # encode connection by color:
    if ($name =~ m/extract/ ) {
      $ed->color("red");
      $ed->linestyle("dashed" );
    }elsif ($hash{$edge} =~ m/perl5/ ) {
      $ed->color("cyan");
      $ed->linestyle("dashed" );
    }elsif ($hash{$edge} =~ m/do_one/ ) {
    }elsif ($hash{$edge} =~ m/do_all/ ) {
    }elsif ($hash{$edge} =~ m/perl4/ ) {
    }elsif ($hash{$edge} =~ m/cgi_lib/ ) {
      $ed->color("red" );
    }elsif ($name =~ m/r2h_gq/ ) {
      $ed->color("gold" );
    }elsif ($hash{$edge} =~ m/R2H_ENV/ ) {
      $ed->color("magenta" );
      $ed->linestyle("dotted" );
    }elsif ($hash{$edge} =~ m/gqf_fromRDB/ ) {
      $ed->color("magenta");
      $ed->linestyle("dashed") ;
      $ed->priority(1);
    }elsif ($hash{$edge} =~ m/rdb/ ) {
      $ed->color("blue");
      $ed->linestyle("dotted" );
    }elsif ($hash{$edge} =~ m/db_update/ ) {
      $ed->color("green");
#      $priority("100" unless ($name =~ m/pdb|dssp|SRS|get_db_info/);
    }


  }
}

$biggraph = $graphs{''};

#while(($module,$graph)= each %graphs){
#  next if ($module eq '');
#  $biggraph->add_content($graph);
#}

$biggraph->height(700);
$biggraph->width(1000);
$biggraph->orientation(left_to_right);
$biggraph->xspace(15);
$biggraph->yspace(80);
$biggraph->layout_downfactor(40);
$biggraph->layout_upfactor(1);
$biggraph->layout_nearfactor(20);
$biggraph->manhattan_edges('no');
$biggraph->layoutalgorithm('maxdepthslow');
$biggraph->shrink(3);
$biggraph->stretch(1);
$biggraph->color('white');
$biggraph->Print;
