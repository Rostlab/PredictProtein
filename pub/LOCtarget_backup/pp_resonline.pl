#! /usr/bin/perl  

# predictNLS interface to pp.
#usage fileIn='fileIn' dirOut='dirOut' fileOut='fileOut' html='0|1|2' fileTrace='fileTrace'
#html=0 ; 1 email output file
#html=1 ; 1 html output file
#html=2 ; 2 output files, html followed by email
#output: 2 files: 1)with html output 2) email output
# Set $dirOut in iniDef() to working dir 
# Set correct path to grep_NLS_update in system call
# all other command line arguments are specified in initialization subroutine iniDef

$scr=$0;
&iniDef();

# open inFile and read in seq

open($fhin,$inFile)|| eval{ print STDOUT "Input file=$inFile unreadable. Execution terminated.\n";
			    print STDERR "Input file=$inFile unreadable. Execution terminated.\n";
			    exit;
			  };
$sequence= ""; # the var with seq in one letter amino acid code
while(<$fhin>){
  chomp($_);
  if($_=~ /^>/){
    $protId= "$_";
    next;
  }
  $_=~s/\s//g;
  $sequence.=$_;
}

close($fhin);
$sequence=~tr /[a-z]/[A-Z]/;# translating sequence to capital letters.
#---------------------------------------------------------------------------
#inFile readable! open filehandles for html and email output

if(defined $fileHtml){
  open($fhout1,">".$fileHtml) || eval{print STDOUT "Output file=$fileHtml cannot be opened. Dir not writable.Execution terminated\n";
				      print STDERR  "Output file=$fileHtml cannot be opened. Dir not writable.Execution terminated\n";
				      exit;};
  #
  print $fhout1 "<html><head><title>Results for $inFile</title></head>\n";
  
  print $fhout1 "<BODY BGCOLOR='#FFFFFF'>";
  print $fhout1 "<H3><STRONG>Results of Nuclear Localization Signal Prediction(NLS):</STRONG></H3>";
  print $fhout1 "<LI><A HREF='http://maple.bioc.columbia.edu/predictNLS/doc/help.html#H_Res' TARGET='http://maple.bioc.columbia.edu/predictNLS/doc/help.html#H_Res'>Help </A> on interpretation of results.</LI><BR><BR>";
}
if(defined $fileEmail){
  open($fhout2,">".$fileEmail) || eval{print STDOUT "Output file=$fileEmail cannot be opened. Dir not writable.Execution terminated\n";
				       print STDERR  "Output file=$fileEmail cannot be opened. Dir not writable.Execution terminated\n";
				       exit;};
  print $fhout2 "Results of Nuclear Localization Signal Prediction(NLS)\n";
  print $fhout2 "The NLS server can be directly accessed at: http://cubic.bioc.columbia.edu/predictNLS/\n";
  print $fhout2 "For help on interpretation of results visit the predictNLS help page: http://cubic.bioc.columbia.edu/predictNLS/doc/help.html\n"; 
  print $fhout2 "-----------------------------------------------------------------\n";
}
if(defined $fileSummary){
    open($fhout3,">".$fileSummary) || eval {print STDOUT "Output file=$fileSummary cannot be opened. Dir not writable.Execution terminated\n";
				       print STDERR  "Output file=$fileSummary cannot be opened. Dir not writable.Execution terminated\n";
				       exit;};
}
#---------------------------------------------------------------------------


system("$exeNLS mode=$mode '$sequence'  out  '$dirOut'  '$jobId'  >'$runOut'"); # system call to main program   
 

 $filein= $FoundNlsOut;
		      
 if(-e  "$filein"){
      open($fhin,$filein) ||eval{ print STDOUT "$filein not readable. Check dir permissions..Check problems with system call\n\n";
				  print STDERR "$filein not readable. Check dir permissions.Check problems with system call\n";
				system("rm -f  $FoundNlsOut $MotifOut $NlsDat $ProtLoc $Fasta $runOut");
				  exit;};

 
# open file for reading
      while(<$fhin>){
	next if /^\#/;
	if ($_=~ /input/) {
	  $out=$_;
	}
      }
      close ($fhin);
  }

@result= split(/[\s]+/,$out); # the results
# print STDOUT "<LI>@result<BR>";
# processing starts here
if($out=~ /\w/){		# if true, this seq has NLS. 
    if(defined $fileSummary){
	print $fhout3 "1\n";
    }
  @nlsList= split(/;/,$result[3]);
  @posList=split(/;/,$result[4]); # list of positions
  if(defined $fileHtml){
    print $fhout1 "<TABLE COLS=2 CELLPADDING=2 WIDTH='100%'>\n";
    print $fhout1 "<TR VALIGN=TOP>\n",
    "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>\n",
    "<B><FONT COLOR='#FFFFFF'> Input Sequence (NLS's in Red)</FONT></B></TD>\n",
    "<TD VALIGN=TOP WIDTH='85%'>\n",
    "<PRE>";
  }
  &sortNlsList();		# sub sorts the positions of NLS's in numerical order. Used for highlighting NLS residues
  #print out highlighted regions to htmlfile
  @sequence= split(//,$sequence);
  foreach $x (0..($shadeMin[0]-1)){
    if(defined $fileHtml){
      print $fhout1 "$sequence[$x]"; # the unhighlighted region at the N-terminal.
    }
    if((($x+1)%60)==0) {
      if(defined $fileHtml){
	print $fhout1 "\n";
      }
    }
  }
     foreach $k (0..$#shadeMin){
     foreach $x ($shadeMin[$k]..$shadeMax[$k]){
      if(defined $fileHtml){
	print $fhout1 "<B><FONT COLOR='RED'>$sequence[$x]</FONT></B>"; # highlighted region
      }
      if((($x+1)%60)==0) {
	if(defined $fileHtml){
	  print $fhout1 "\n";
	}
      }
    }
	     if($k<$#shadeMin){
      $last=$shadeMin[$k+1]-1;
    }
    else{
      $last= $#sequence;
    }
    foreach $x (($shadeMax[$k]+1)..$last){
      if(defined $fileHtml){
	print $fhout1 "$sequence[$x]"; #unshaded
      }
      if((($x+1)%60)==0) {
	if(defined $fileHtml){
	  print $fhout1 "\n";
	}
      }
    }
   }
  if(defined $fileHtml){
    print $fhout1 "</PRE>";
    print $fhout1 "</TD></TR>";
    print $fhout1 "<TR VALIGN=TOP>",
    "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>",
    "<B><FONT COLOR='#FFFFFF'> Sequence Length</FONT></B></TD>",
    "<TD VALIGN=TOP WIDTH='85%'>",
    "<EM>$result[2]</EM>",
    "</TD></TR>";
  }
  # print to email file
  if(defined $fileEmail){
    foreach $j (1..70){
    print $fhout2 "-";
  }
    print $fhout2 "\n";
  }
     if(defined $protId){
       if(defined $fileEmail){
	 print $fhout2 "Input sequence Id: $protId\n";
       }
     }
  if(defined $fileEmail){
    #print $fhout2 "Input Sequence : $sequence\n";
    print $fhout2 "Sequence Length: $result[2]\n";
    foreach $j (1..70){
    print $fhout2 "-";
  }
    print $fhout2 "\n";
 
  }
  if(defined $fileHtml){
    print $fhout1 "<TR VALIGN=TOP>\n",
    "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>\n",
    "<B><FONT COLOR='#FFFFFF'> NLS's found.<I> No gives position of Motif </I></FONT></B></TD>\n",
    "<TD VALIGN=TOP WIDTH='85%'>\n",
    "<UL>\n";  
  }
  if(defined $fileEmail){
    print $fhout2 "List of NLS's found in sequence\n";
    foreach $i (1..70){
    print $fhout2 "-";
  }
    print $fhout2 "\n";
    printf $fhout2 "%1s%19s%1s%20s%1s\n","|","NLS","|","Position in sequence","|";
    
  }
  foreach $i (0..$#nlsList) {
    if(defined $fileHtml){
      print $fhout1 "<LI> <EM> $nlsSeq[$i] </EM><EM> $posList[$i]  </EM> </LI>\n";
    }
    if(defined $fileEmail){
      printf $fhout2 "%1s%19s%1s%20s%1s\n","|",$nlsSeq[$i],"|",$posList[$i],"|";
     
    }
    
  }
   if(defined $fileHtml){
    print $fhout1 "</UL></TD></TR></TABLE>\n";
  }
   if(-e "$NlsDat"){
     if(defined $fileHtml){
       print $fhout1 "<H3><B>Statistical data for Nuclear Localization Signals present in the Input Sequence</B></H3>\n";
       print $fhout1 "<TABLE BORDER=2>";
       print $fhout1 "<TR ><TD  COLSPAN=3 ALIGN=CENTER>\n",
       "<B><FONT >Generalized NLS<BR> ( <A HREF=\'#H_Res_NLS\'> notation </A>)</FONT></B></TD>\n",
       "<TD COLSPAN=1>Type</TD>",
       "<TD COLSPAN=1>No with NLS</TD>",
       "<TD COLSPAN=1>%Nuc Proteins</TD>",
       "<TD COLSPAN=1>%NonNuc Proteins</TD>",
       "<TD COLSPAN=3>Protein Swiss Id</TD>",
       "<TD COLSPAN=1>Protein Localizations(Swiss anno.)</TD></TR>\n";
     }
     if(defined $fileEmail){
         foreach $i (1..70){
	 print $fhout2 "-";
       }
	 print $fhout2 "\n";
       print $fhout2 "\n\nStatistcal data for the NLS's found in the Input Sequence:\n\n";
        foreach $i (1..70){
	  print $fhout2 "-";
	}
	 print $fhout2 "\n\n";
       printf $fhout2 "%10s%25s%15s%10s%20s%10s\n","NLS","Type","NumWithNLS","%NucProt","ProtList","Prot.Loci";
     }
    open($fhin,$NlsDat);
    while(<$fhin>){
      next   if /^\#/;
      $nlsData=$_;
	     if ($_=~ /input/){
	@tmp=split(/[\s]+/,$_);
	@nlsList= split(/,/,$tmp[6]);
	@locList=split(/,/,$tmp[7]);
	$nlsNo=$#nlsList+1;	   #no of NLS's found.
	if(defined $fileHtml){
	  print $fhout1 "<TR >",
	  "<TD COLSPAN=3 ROWSPAN='$nlsNo'  VALIGN='TOP'>",
	  "<B><FONT><EM>$tmp[1]</EM></FONT></B></TD>\n";
	}
	
	
	
	     if($tmp[2]=~ /Exp/) {
	  undef $exp;
	  $expNls= $tmp[1];
	  $expNls=~s/\[/\\[/g ;
	  $expNls=~s/\{/\\{/g ;
	  $expNls=~s/\]/\\]/g;
	  $expNls=~s/\}/\\}/g;
	  $fileRdb= $dirData."ExptNls.rdb";

	  $exp=`grep -E '$expNls' '$fileRdb'`;
	  
	     if(defined $exp){
	    $exp=~ m/(\d+)$/;
	    $uid=$1;
	    if(defined $fileHtml){
	    print $fhout1 "<TD COLSPAN=1 ROWSPAN='$nlsNo'  VALIGN='TOP'><A HREF=\"http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=$uid&dopt=Abstract\" TARGET=\"http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=$uid&dopt=Abstract\">$tmp[2]</A></TD>\n";
	  }
	  }
	  else {
	    if(defined $fileEmail){
	    print $fhout1 "<TD COLSPAN=1 ROWSPAN='$nlsNo'  VALIGN='TOP'>$tmp[2] </TD>";
	  }
	  }
	}
	else{
	  $potNls= $tmp[1];
	  $fileData= $dirData."nlsTree";
	  undef $flagExp;
	  open($fhdata,$fileData) || print STDERR "Server Error: Tree file not found. Report to admin\n";
	  
	  while(<$fhdata>){
	    @tmpdata= split(/[\s]+/,$_);
	     if($tmpdata[1] eq $potNls){
	      $flagExp=1;
	    }
	  }
	  close $fhdata;
	     if($flagExp==1){
	       if(defined $fileHtml){
	    print $fhout1 "<TD COLSPAN=1 ROWSPAN='$nlsNo'  VALIGN='TOP'><A HREF='http://cubic.bioc.columbia.edu/cgi/var/nair/potNls.pl?potNls=$potNls'  TARGET='http://cubic.bioc.columbia.edu/cgi/var/nair/potNls.pl?potNls=$potNls'>$tmp[2]</A></TD>\n";
	  }
	  }
	  else{
	    if(defined $fileHtml){
	    print $fhout1 "<TD COLSPAN=1 ROWSPAN='$nlsNo'  VALIGN='TOP'>$tmp[2] </TD>\n";
	  }
	  }
	}
	foreach $i (3..5){
	 if(defined $fileHtml){ 
	  print $fhout1 "<TD COLSPAN=1 ROWSPAN='$nlsNo'  VALIGN='TOP'>$tmp[$i] </TD>";
	}
	}

	  if(defined $fileEmail){
	    
	    	
		  printf $fhout2 "%25s%15s%10s%10s%20s%5s\n", $tmp[1],$tmp[2],$tmp[3],$tmp[4],$nlsList[0],$locList[0];
		  foreach $j (1..$#nlsList){
		    foreach $k (1..60){
		      print $fhout2  " ";
		    }
		    printf $fhout2 "%20s%5s\n",$nlsList[$j],$locList[$j];
		  }
		}
	  
	if(defined $fileHtml){
	print $fhout1 "<TD COLSPAN=3 ROWSPAN=1><A HREF='$urlSrs?-id+on291EKHQt+-e+[SWISSPROT-ID:$nlsList[0]]' >$nlsList[0]</TD>\n";
	print $fhout1 "<TD COLSPAN=1 ROWSPAN=1>$locList[0]</TD></TR>\n";
      }
	foreach $j (1..$#nlsList){
	  if(defined $fileHtml){
	  print $fhout1 "<TR><TD COLSPAN=3 ROWSPAN=1><A HREF='$urlSrs?-id+on291EKHQt+-e+[SWISSPROT-ID:$nlsList[$j]]' >$nlsList[$j]</A></TD>\n";
	  print $fhout1 "<TD COLSPAN=1 ROWSPAN=1>$locList[$j]</TD></TR>\n";
	}
	}
	if(defined $fileHtml){
	print $fhout1 "</TR>\n";
      }
	     if($tmp[8]=~ /DNA_BIND/){
	  chomp($nlsData);
	  $dnaBind{$tmp[1]}= $nlsData;
	  $dnaFlag=1;
	} 
	if(defined $fileEmail){
	print $fhout2 "\n";
      }
	
      }
    }
    
    close $fhin;
  }
  if(defined $fileHtml){
  print $fhout1 "</TABLE>";
} 
	     if($dnaFlag==1){
    # DNA binding protein.
	       if(defined $fileHtml){
    print $fhout1 "<H3><B><I> This protein is predicted to bind to DNA.</I></B></H3>\n";
    print $fhout1 "<TABLE COLS=5 CELLPADDING=2 WIDTH='100%'>\n";
    print $fhout1 "<TR VALIGN=TOP>",
    "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='25%'>\n",
    "<B><FONT COLOR='#FFFFFF'><EM>DNA Binding signals.</EM></FONT></B></TD>\n";
  }
	       if(defined $fileEmail){
		 foreach $j (1..70){
		   print $fhout2 "=";
		 }
		 
		 print $fhout2 "\nThis protein is predicted to bind DNA\n";
		  foreach $j (1..70){
		   print $fhout2 "=";
		 }
		 print $fhout2 "\nDNA Binding signals:\t";
  }
    
    foreach $key (keys %dnaBind){
      if(defined $fileHtml){
      print $fhout1 "<TD VALIGN=TOP WIDTH='17%'>$key </TD>\n";
    }
      if(defined $fileEmail){
      print $fhout2 "$key\t";
    }
    }
	        
	       if(defined $fileHtml){
    print $fhout1 "</TR></TABLE>\n";
    print $fhout1 "<H3> DNA binding statistics for the binding NLS signals.</H3>\n";
  }
	       if(defined $fileEmail){
    print $fhout2 "\n\nDNA binding statistics for the binding NLS  signals\n";
    printf $fhout2 "%25s%15s%10s%20s%10s%30s\n","DnaBindNLS","NumBindingDNA","%bindDNA","NumInBindDomain","%InBindDom","%Associated Binding Domains";
  }
	       if(defined $fileHtml){
    print $fhout1  "<TABLE COLS=6 CELLPADDING=2 WIDTH='100%'>\n";
    print $fhout1 "<TR VALIGN=TOP><TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>\n",
    "<B><FONT COLOR='#FFFFFF'><EM>DnaBindNLS</EM></FONT></B></TD>\n",
    "<TD VALIGN=TOP WIDTH='15%'>No binding DNA</TD>\n",
    "<TD VALIGN=TOP WIDTH='15%'>%binding DNA</TD>\n",
    "<TD VALIGN=TOP WIDTH='15%'>No in binding Domain</TD>\n",
    "<TD VALIGN=TOP WIDTH='15%'>%in binding Domain</TD>\n",
    "<TD VALIGN=TOP WIDTH='25%'>% of associated DNA binding domains</TD></TR>\n";
  }
    foreach $key (keys %dnaBind){
      if(defined $fileHtml){
      print $fhout1 "<TR VALIGN=TOP>",
      "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>\n",
      "<B><FONT COLOR='#FFFFFF'><EM>$key</EM></FONT></B></TD>\n";
    }
     
      @tmp=split(/\t/,$dnaBind{$key});
      foreach $i (9..12){
	if(defined $fileHtml){
	print $fhout1 "<TD VALIGN=TOP WIDTH='15%'>$tmp[$i]</TD>\n";
      }
      }
	if(defined $fileEmail){
	printf $fhout2 "%25s%15s%10s%20s%10s",$key,$tmp[9],$tmp[10],$tmp[11],$tmp[12];
      }
      
      if(defined $fileHtml){
      print $fhout1 "<TD VALIGN=TOP WIDTH='25%'>";
    }
      if(defined $fileEmail){
      print $fhout2 "    ";
    }
      foreach $i (13..$#tmp){
	$tmp[$i]=~m /(.+):(.+)/;
	if(defined $fileHtml){
	print $fhout1 "$binAnno{$1}:$2";
      }
	if(defined $fileEmail){
	print $fhout2 "$binAnno{$1}:$2";
      }
      }
      if(defined $fileEmail){
      print $fhout2 "\n";
    }
      if(defined $fileHtml){
      print $fhout1 "</TD></TR>";
    }
    }
	       if(defined $fileHtml){
    print $fhout1 "</TABLE>\n"; 
}
	   }
  if(defined $fileHtml){
  print $fhout1 "<H3><A NAME= 'H_Res_NLS'>  Symbols</A> used in representing the NLS are explained below:</H3>\n",
    
      "An x (or X) implies any amino acid residue can be present at this position.<BR>
     <BR> <TABLE BORDER='2' >",
     "<TR>",
     "<TD COLSPAN='3' ALIGN='CENTER' ><strong> Example Motifs </strong></TD>",
     "</TR>\n",
     "<TR>",
     "<TD> Example</TD>",
     "<TD> Read</TD>",
     "<TD> Equivalent Motifs </TD>",
     "</TR>\n",
     "<TR>",
     "<TD> [KR]KRKK </TD>",
     "<TD> \"K or R\" KRKK </TD>",
     "<TD> KKRKK,RKRKK",
     "</TR>\n",
     "<TR>",
     "<TD> K{5} </TD>",
     "<TD> 5 times K </TD>",
     "<TD> KKKKK </TD>",
     "</TR>\n",
     "<TR>",
     "<TD> [KR]{3,5} </TD>",
     "<TD> between 3 and 5 times K or R </TD>",
     "<TD> KKRR, RRKKR, RRR,KKK ...</TD>",
     "</TR>\n",
     "<TR>",
     "<TD> K{3,}? </TD>",
     "<TD> 3 or more K's </TD>",
     "<TD> KKK,KKKK,KKKKK ... </TD>",
     "</TR>",
     "</TABLE>";
}
  if(defined $fileEmail){
      print $fhout2 "\n\n";
      foreach $i (1..70){
	  print $fhout2 "=";
      }
      print $fhout2 "Symbols used in representing the NLS are explained below:\n\n";
      print $fhout2 "An x (or X) implies any amino acid residue can be present at this position.\n";
      foreach $i (1..50){
	  print $fhout2 ".";
      }
      print $fhout2 "\n";
      print $fhout2 "\t\tExample Motifs\n";
       foreach $i (1..50){
	  print $fhout2 ".";
      }
      print $fhout2 "\n";
      printf $fhout2  "%10s%25s%40s\n","Example","Read","Equivalent Motifs";
      printf $fhout2  "%10s%25s%40s\n","[KR]KRKK ","\"K or R\" KRKK","KKRKK,RKRKK";
      printf $fhout2  "%10s%25s%40s\n","K{5}     ","   5 times K "," KKKKK     ";
      printf $fhout2  "%10s%25s%40s\n","[KR]{3,5} ","between 3 and 5 times K or R ","KKRR,RRKKR,RRR,KKK ..";
      printf $fhout2  "%10s%25s%40s\n","K{3,}?   ","   3 or more K's ","KKK,KKKK,KKKKK ..";
  }
}  #if($out=~ /\w/){
else {
    if(defined $fileSummary){
	print $fhout3 "0\n";
    }
  if(defined $fileHtml){
  print $fhout1 "<TABLE COLS=2 CELLPADDING=2 WIDTH='100%'>\n";
  print $fhout1 "<TR VALIGN=TOP>\n",
  "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>\n",
  "<B><FONT COLOR='#FFFFFF'> Input Sequence</FONT></B></TD>\n",
  "<TD VALIGN=TOP WIDTH='85%'>\n",
  "<EM>$sequence</EM>",
  "</TD></TR>\n";
}
  if(defined $fileEmail){
  print $fhout2 "Input Sequence: $sequence\n";
}
  if(defined $fileHtml){
  print $fhout1 "<TR VALIGN=TOP>",
  "<TD VALIGN=TOP BGCOLOR='#0000FF' WIDTH='15%'>",
  "<B><FONT COLOR='#FFFFFF'> Output</FONT></B></TD>",
  "<TD VALIGN=TOP WIDTH='85%'>",
  "This protein does not contain a nuclear localization signal.",
  "</TD></TR>";
  print $fhout1 "</UL></TD></TR></TABLE>";
  print $fhout1 "</BODY>\n";
}
  if(defined $fileEmail){
  print $fhout2 "This sequence does not contain any nuclear localization signal in database\n";
}
}

close $fhout1;
close $fhout2;
system("rm -f  $FoundNlsOut $MotifOut $NlsDat $ProtLoc $Fasta $runOut");



#=====================================================================

sub iniDef {

#--------------------------------------------------------------------- 
#  iniDef       initialize defaults
#---------------------------------------------------------------------
    # first initialize command line arguments
  
#    # $html =0=> only email file; $html=1 => only html file

  foreach $i (0..$#ARGV){
    $ARGV[$i]=~m /(\w+)=(\S+)/;
    $arg=$1;
    $par=$2;
    if($arg=~ /fileIn/){
      $inFile= $par; # the fasta file
    }
    elsif($arg=~ /dirOut/){
      $dirOut= $par;
      if(!($dirOut=~ /\/$/)){
	 # print STDOUT "yes\n";
	  $dirOut=$dirOut."/";
      }
    }
    elsif($arg=~ /fileOut/){
      $fileOut= $par;
    }
    elsif($arg=~ /html/){
      $html=$par;
    }
    elsif($arg=~ /fileTrace/){
      $fileTrace= $par;
    }
    elsif($arg=~ /fileSummary/){
	$fileSummary= $par; #if defined a summary file is produced with 1 if NLS is present else 0.
    }
    elsif($arg=~ /fileOut1/){
      $fileOut1= $par;
    }
    else{
      print STDOUT "unacceptable command line argument\n";
      print STDERR "unacceptable command line argument\n";
      print STDOUT "usage fileIn='fileIn' dirOut='dirOut' fileOut='fileOut' html='0|1|2' fileTrace='fileTrace'\n";
      print STDERR "usage fileIn='fileIn' dirOut='dirOut' fileOut='fileOut' html='0|1|2' fileTrace='fileTrace'\n";
    }
    
  }

  if(! defined $inFile){
    print STDOUT "please provide input file (protein sequence)\nExiting script\nStart again\n";
    exit;
  }
  if($inFile=~/(.*)\.(.*)/){
      $head=$1;
      $tail=$2;
    }
  else{
    $head=$inFile;
  }
  
  if(! defined $html){
    $html=1;#by default generate html output
  }

  if(! defined $fileOut){
    if($html==0){
      $fileOut=$head.".txt";
    }
    else{
      $fileOut= $head.".html";
    }
  }

  if(! defined $fileOut1){
    $fileOut1=$head.".txt";
  }

  if(!defined $dirOut){
    $dirOut= "./";
    print STDOUT "Output directory set to current directory\n";
  }

  print STDOUT "html set to $html\n";
 # if(!(defined $fileTrace)){
 #  $fileTrace=$head.".trace"; #the trace file to track errors
 # }

  if(defined $fileTrace){
    $fileErr= $fileTrace;
    open(STDERR,">".$fileErr) || eval{ print STDOUT "specified dir not writable. Could not open $fileErr\n";
				       print STDERR "specified dir not writable. Could not open $fileErr\n";
				       exit;
				   };
  }
  
  if(!(defined $inFile)){
    print STDERR "Input fasta file not defined\n";
    exit;
  }
  elsif(!(defined $fileOut)){
     print STDERR "OutFile not defined\n";
     exit;
   }
  elsif(!(defined $html) ){
    print STDERR "define Output file type. html=0 =>email o/p; html=1 => html o/p; html=2 => both\n";
    exit;
  }
  
  
  # get a random job_id (between 1 and 10000)
  $jobId=int(rand 30000) + 1;
  # initialize working directories and files.

  $scr=~m /(.*\/).*?/;
  $dirPrg = $1;
  $dirData= $dirPrg."data/";
  $exeNLS = $dirPrg."grep_NLS_update.pl";
  $urlSrs = "http://cubic.bioc.columbia.edu/srs6bin/cgi-bin/wgetz";

  # files generated by grep_NLS_update
  $FoundNlsOut= $dirOut."FoundNLS".$jobId;# random id tags to output files
  $MotifOut= $dirOut."Motif_Stat".$jobId;
  $NlsDat=$dirOut."MotifDat".$jobId;
  $ProtLoc= $dirOut."Prot_Loc".$jobId;
  $Fasta= $dirOut."Fasta_Not_Found".$jobId;
  $runOut= $dirOut."run.out".$jobId;
  $mode=2; # sequence mode in grep_NLS_update
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # in and out files and vars
  $fhin= "FHIN";
  $fhdata="FHDATA";
  $fhout1= "FHOUT1";
  $fhout2= "FHOUT2";
  $fhout3= "FHOUT3";
  undef $fileEmail;
  undef $fileHtml;
  if($html==0){
    $fileEmail =$fileOut;
  }
  elsif($html==1){
    $fileHtml =$fileOut;
  }
  else{
    
    $fileHtml =$dirOut.$fileOut;
    $fileEmail =$dirOut.$fileOut1;
  }
  
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # used to interpret annotations.
  #------------------------------------------------------------------------------------------
  #DNA Bind Motif anno list
  $binAnno{'hbox'}="HOMEOBOX";$binAnno{'bas'}= "BASIC DOMAIN";
  $binAnno{'fork'}= "FORK-HEAD"; $binAnno{'hlh'}= "HELIX-LOOP-HELIX";
  $binAnno{'myb'}= "MYB"; $binAnno{'hmg'}="HMG BOX";
  $binAnno{'znc'}= "ZINC FINGERS"; $binAnno{'ets'}="ETS-DOMAIN";
  $binAnno{'fun'}="FUNGAL-TYPE"; $binAnno{'hook'}= "A.T HOOK";
  #--------------------------------------------------------------------------------------------
  undef $protId;
  undef $sequence;
  undef $out;
  undef %dnaBind;# var used to record dna binding
  $dnaFlag=0;

}
#end of iniDef
#--------------------------------------------------------------------

#=====================================================================
sub sortNlsList {
#---------------------------------------------------------------------
#   sortNlsList     sorts the NLS's according to position of their occurrences.
#---------------------------------------------------------------------

 #buble sort
  $tag=$#posList;
  for ($tag=$#posList;$tag>0;$tag--){
    
    foreach  $k (0..($tag-1)){
      if ( $posList[$k] > $posList[($k+1)] ){
	
	$savPos=$posList[$k+1];
	$savNls=$nlsList[$k+1];
	$posList[$k+1]=$posList[$k];
	$nlsList[$k+1]= $nlsList[$k];
	$posList[$k]=$savPos;
	$nlsList[$k]=$savNls;
      }
    }
    
  }
  # end sort
  #print $fhout1 "<LI>@posList";
  foreach $k (0..$#posList){
    $tmpnls=$nlsList[$k];
    $tmpnls=~s /x/[A-Z]/g; # replace x with [A-Z]. Perl syntax.
    $sequence=~m /^\w+($tmpnls)/;
    $nlsSeq[$k]=$1;
       
    $len= length $1;
    $highLightMax[$k]=$posList[$k]+$len-1;
    #     print $fhout1 "<LI>$nlsList[$k] $1 $posList[$k] $highLightMax[$k]";
  }
  $cnt=0;
  $shadeMin[$cnt]=$posList[$cnt];#start pos for highlighting.
  $shadeMax[$cnt]=$highLightMax[$cnt];# finish for highlighting
  foreach $k (1..$#posList){
    if($posList[$k]<=$shadeMax[$cnt]){
      if($highLightMax[$k]>$shadeMax[$cnt]){
	$shadeMax[$cnt]=$highLightMax[$k];
      }
    }
    else{
      $cnt++;
      $shadeMin[$cnt]=$posList[$k];
      $shadeMax[$cnt]=$highLightMax[$k];
    }
  }
     
}
# end of sub sortNlsList     
#----------------------------------------------------------------------------
