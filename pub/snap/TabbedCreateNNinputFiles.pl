#!/usr/local/bin/perl

#This is the latest version of this file
#June 09, 2005
#written by Yana Bromberg

use POSIX qw(ceil floor);
#command line inputfile innodes outnodes samples hiddennodes hiddenlayers aminoTF stepNumber

#this is an attempt to automate creation of needed NN files
#zeroth command line parameter contains the name of the input file
$name = $ARGV[0];
if ($name eq "help"){
	print "#first contains number of input nodes (digit)\n#second contains number of hidden nodes\n";
	print "#third contains number of output nodes\n#fourth contains the number of hidden layers plus output\n";
	print "#fifth contains number of samples (digit)\n#sixth contains the number of times output is written\n";
	print "#seventh contains the maximum number of times that any given sample in the training set is presented to the network STPSWPMAX\n";	
	print "#eight value contains the total number of samples in one repeat of training\n";
	print "#ninth value indicates junction file (NEW for training on random)\n#tenth value indicates balanced or unbalanced training or testing [bal, unbal, test]\n";
	print "#eleventh value is alpha\n#twelvth value is epsilon\n#Thirteenth value means only par is written if set to 0 and only Sam and par if set to 2\n";
	print "#fourteenth contains the input dir\n";
	print "#fifteenth contains the output dir\n";
	exit;
}

#first contains number of input nodes (digit)
$innodes = $ARGV[1];
#second contains number of hidden nodes
$hidden = $ARGV[2];
#third contains number of output nodes
$outnodes = $ARGV[3];
#fourth contains the number of hidden layers plus output
$Hlayers = $ARGV[4];
#fifth contains number of samples (digit)
$samples = $ARGV[5];
#sixth contains the number of times output is written
$stpout = $ARGV[6];
#seventh contains the maximum number of times that any given sample in the training set is presented to the network STPSWPMAX
$totrepsam = $ARGV[7];
#eight value contains the total number of samples in one repeat of training
$stpmax = $ARGV[8];
#ninth value indicates junction file (NEW for training on random)
$file_test = $ARGV[9];
#tenth value indicates balanced or unbalanced training or testing [bal, unbal, test]
$bal = $ARGV[10]; 
#eleventh value is alpha
$alpha = $ARGV[11];
#twelvth value is epsilon
$eps = $ARGV[12];
#Thirteenth value means only par is written if set to 0, everything if set to 1, par and sam if set to 2, and in-out and par if set to 3
$rewr = $ARGV[13];
#fourteenth contains the input files dir -- here are all files to be input into the network except the par file
$diri = $ARGV[14];
#fifteenth contains the output files dir -- all output files + par file
$diro = $ARGV[15];

if (!($diri =~ /\w/)){
	$diri = `pwd`;
}
if (!($diro =~ /\w/)){
	$diro = $diri;
}

$count_p = 0;
$count_m = 0;
$count_t = 1;

print "rerite is $rewr\n";
$name_dir = $name;
$name =~ s/^.+\/(.+)/$1/;
print $name."\n";
&writePar();
if ($rewr >= 1){
	&writeInOut();
}


####################################
#print the input and output files
####################################
sub writeInOut{
	open (DATA, $name_dir) || die "Can't open file $name_dir\n";
	print "writing In Out\n";
	$plus = "";
	$minus = "";
	$counr_p = 0;
	$count_m = 0;
	if (($rewr == 1 ) or ($rewr == 3)){
		print "printing in$name-in and in$name-out ";
		open (IN, ">$diri/in$name-in");
		open (OUT, ">$diri/in$name-out");

		print IN "* overall (A,T25,I8)\n";
		print IN "NUMIN                 : ";
		print IN &Node_Convert($innodes,"8");
		print IN "NUMSAMFILE            : ";
		print IN &Node_Convert($samples,"8");
		print IN "* --------------------\n";
		print IN "* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)";
	
	
		print OUT "* overall: (A,T25,I8)\n";
		print OUT "NUMOUT                : ";
		print OUT &Node_Convert($outnodes,"8");
		print OUT "NUMSAMFILE            : ";
		print OUT &Node_Convert($samples,"8");
		print OUT "* --------------------\n";
		print OUT "* samples: count (I8) SPACE 1..NUMOUT (25I6)\n";
	}
	#gencount is the sample count variable 
	$gencount = 1;
	
	foreach $part (<DATA>){
		$part =~ s/\n| //g;
		@line = split (/\t/, $part);
		foreach $line (@line){
			if ($line =~ /\>/){
				#entrycount is the node count variable no more than 25 are allowed per line
				$entrycount = 0;
				#inout is the the separator count of input and output
				$inout = 0;	
				if (($rewr == 1 ) or ($rewr == 3)){
					#print sample number in input file
					print IN "\nITSAM:  ";
					print IN &Node_Convert($gencount,"8");
					#print sample number in output file
					#node_convert automatically adds a line break after the converted numeral
					#this line break need to be removed for the output file numbering
					$t = &Node_Convert($gencount,"8");
					$t =~ s/\n//;
					print OUT $t." ";
				}
				#increase the sample number
				$gencount++;
			}
			else{
				#check first if we are dealing with input --> number of user defined input nodes
				#is larger than the number of the node we are currently concerned with 
				if ($inout < $innodes){
					#this is assuming that input can only be numerical
					#so if there is a word, it shouldn't be there
					if ($line =~ /[^0-9]/){
						print "Character line encountered: $line\n";
						exit;
					}
					#else this is not a character line so just print it out
					else{
						if (($rewr == 1 ) or ($rewr == 3)){
							if ($entrycount < 25){	
								$entrycount++;
							}
							else{
								print IN "\n";
								$entrycount = 1;
							}
							$pr = &Node_Convert($line,6);
							$pr =~ s/\n//;
							print IN $pr;
						}
						$inout++;		
					}
				}
				#if dealing with output (always numeric)
				elsif ($inout == $innodes){
					if ($line =~ /100/){
						if (($rewr == 1 ) or ($rewr == 3)){
							if ($outnodes == 1){
								print OUT "   100\n";
							}
							else{
								print OUT "   100     0\n";
							}
						}
						#this is for creating array of positive ouput values
						$plus .= "$count_t ";
						$count_p++;
					}
					elsif ($line == 0){
						#this is for creating array of negative output values
						$minus .= "$count_t ";
						$count_m++;
						if (($rewr == 1 ) or ($rewr == 3)){
							if ($outnodes == 1){
								print OUT "     0\n";
							}
							else{
								print OUT "     0   100\n";
							}
						}
					}
					else{
						print "Output is $line not 0/1 -- please correct ($gencount)\n";
						exit;
					}	
					$count_t++;
					$innout++;
					#print $count_t."\n";
					#print "$innodes $line\n";
				}
				else{
					print "Error -- too much output\n";
					<STDIN>;
				}
			}	
		}
	}
	if (($rewr == 1 ) or ($rewr == 3)){
		print IN "\n//";
		print OUT "//";
		close IN;
		close OUT;
	}
	close DATA;
	print "end\n";	


	########################
	#print the sample file
	#######################
	if ($rewr < 3){
		open (SAM, ">$diri/in$name-sam");
		print "Printing in$name-sam .";
		print SAM "* overall: (A,T25,I8)\n";
		print SAM "STPMAX                : ";
		print SAM &Node_Convert($stpmax*$stpout,"8");
		print SAM "* --------------------\n";
		print SAM "* positions: (25I8)\n";

		$entrycount = 0;
		$temp = "";

		#if this is testing or training on unbalanced data,
		#the sample file is in the same order as the input file
		#else mix it ip
		if ($bal =~ /test/){
			$j = 1;
			while ($j <= $samples){
				if ($entrycount < 25){
        	        		$entrycount++;
        	        	}	
        	        	else{
        	        	 	print SAM "\n";  
        	        	 	$entrycount = 1;
        	        	}
        	        	$l = &Node_Convert($j,"8");
        	        	$l =~ s/\n//;
        	        	print SAM $l;
        	        	$j++;
			}
		}
		elsif($bal =~ /unbal/){
			$j = 0;
			while ($j < $stpout){
				$r = 1;
				while ($r <= $stpmax){
					$k = 1;
					while (($k <= $samples) and ($r <= $stpmax)){
						if ($entrycount < 25){   
				                	$entrycount++;
		        			}
		      			  	else{
	        			  	        print SAM "\n";
	        	 		       		$entrycount = 1;
	       					}	
						$l = &Node_Convert($k,"8");
						$l =~ s/\n//;
						print SAM $l;
						$k++;
						$r++;
					}
				}
				$j++;
			}	 	
		}
		elsif ($bal =~ /bal/){
			$j = 0;
			$arr = "";
			$y = 0;
			$once_flag =0;
			#print $plus."\n";
			while ($j < $stpout){
				$r = 1;
				if ($once_flag == 0){	
					$c_p = $count_p;
					$c_m = $count_m;
					$p = $plus;
					$m = $minus;
					$turn = 0;
					$once_flag = 1;
					while ($r <= $stpmax){
						#print $r."\n";
						if ($turn == 0){
							if ($m =~ /\d/){
								$now = $m;
							}
							else{
								$now = $minus;
							}
						}
						else{
							if ($p =~ /\d/){
								$now = $p;
							}
							else{
								$now = $plus;
							}
						}
						if ($now =~ /^(\d+) $/){
							$y = $1;
							$now = "";
						}
						elsif ($y/2 == int($y/2)){
							$now =~ s/^(\d+) (.*)/$2/;
		                			$y = $1;
							#print "even for $turn\n";
						}
						else{
							$now =~ s/(.* )(\d+) $/$1/;
	                				$y = $2;
							#print "odd for $turn\n";
						}			
						if (!($y =~ /\d/)){				
							print "y = $y\n";
							print "turn is $turn and remaining is \-$now\-\n";
							<STDIN>;
						}
                				$l=&Node_Convert($y,"8");
                   				$l =~ s/\n//;
						$once_f[$r] = $l;
						if ($entrycount < 25){
        						$entrycount++;
        					}
        					else{
        	      					print SAM "\n";  
        	      					$entrycount = 1;
        					}
                   				print SAM $l;
	                	   		if ($turn == 0){
							$m = $now;
							$c_m--;
							$turn = 1;
						}
						else{
							$p = $now;
							$c_p--;
							$turn = 0;
						}
						$r++;
					}
				}
				else{
					while ($z <= $stpmax){
						if ($entrycount < 25){
        						$entrycount++;
        					}
        					else{
        	      					print SAM "\n";  
        	      					$entrycount = 1;
        					}
                   				print SAM $once_f[$z];
						$z++;
					}
				}
				$z = 1;
				print $j;
				$j++;
			}						
		}
		print SAM "\n//";
		close SAM;
	}
}

sub Node_Convert
{
	my ($var, $space) = @_;
	my ($temp, $countVar, @temp, $j, $string);
	$temp = $var;
	$temp =~ s/(\d)/$1 /g;
	@temp = split (/ /, $temp);
	$countVar = @temp;
	$j = $countVar;
	$string = "";
	while ($j < $space){
		$string .=" ";
		$j++;
	}
	$string .= "$var\n"; 
	return $string;
}


##############################
#print the parameters file
##############################
sub writePar{
	open (PAR, ">$diro/in$name-par");
	print PAR "* I8\n";
	print PAR "NUMIN                 : ";
	print PAR &Node_Convert($innodes,"8");
	print PAR "NUMHID                : ";
	print PAR &Node_Convert($hidden,"8");
	print PAR "NUMOUT                : ";
	print PAR &Node_Convert($outnodes,"8");
	print PAR "NUMLAYERS             : ";
	print PAR &Node_Convert($Hlayers,"8");
	print PAR "NUMSAM                : ";
	print PAR &Node_Convert($samples,"8");

	#hardcoding # of input/output files for training
	#number of files of input
	print PAR "NUMFILEIN_IN          :        1\n";
	#number of files of output for training pusposes
	print PAR "NUMFILEIN_OUT         :        1\n";
	
	
	#number of files of output from neural net
	print PAR "NUMFILEOUT_OUT        : ";
	print PAR &Node_Convert($stpout,"8");
	#number of junction\weight files
	print PAR "NUMFILEOUT_JCT        : ";
	print PAR &Node_Convert($stpout,"8");
	#max number of times the entire set of samples i presented to the net
	print PAR "STPSWPMAX             : ";
	if($bal =~ /test/){
		print PAR &Node_Convert("0","8");
	}
	else{
		print PAR &Node_Convert($totrepsam*$stpout,"8");
	}
	#total number of samples to learn from
	print PAR "STPMAX                : ";
	print PAR &Node_Convert($stpmax*$stpout,"8");
	#number of samples after which the error is compiled and output printed
	print PAR "STPINF                : ";
	print PAR &Node_Convert($stpmax,"8");

	#hardcode other stuff
	print PAR "ERRBINSTOP            :        0\n";
	print PAR "BITACC                :      100\n";
	print PAR "DICESEED              :   100025\n";
	print PAR "DICESEED_ADDJCT       :        0\n";
	print PAR "LOGI_RDPARWRT         :        1\n";
	print PAR "LOGI_RDINWRT          :        0\n";
	print PAR "LOGI_RDOUTWRT         :        0\n";
	print PAR "LOGI_RDJCTWRT         :        0\n";
	print PAR "* --------------------\n";
	print PAR "* F15.6\n";
	
	print PAR "EPSILON               :        ";
	if ($eps =~ /def/){
		$eps = 0.100500;
	}
	$k = length($eps);	
	print PAR $eps;
	if (!($eps =~ /\./)){
		print PAR ".";
	}
	while ($k < 8){
		print PAR "0";
		$k++;
	}
	print PAR "\n";

	print PAR "ALPHA                 :        ";
	if ($alpha =~ /def/){
		$alpha = 0.100000;
	}
	$k = length($alpha);	
	print PAR $alpha;
	if (!($alpha =~ /\./)){
		print PAR ".";
	}
	while ($k < 8){
		print PAR "0";
		$k++;
	}
	print PAR "\n";
	print PAR "TEMPERATURE           :        1.000000\n";
	print PAR "ERRSTOP               :        0.000100\n";
	print PAR "ERRBIAS               :        0.000000\n";
	print PAR "ERRBINACC             :        0.000000\n";
	print PAR "THRESHOUT             :        0.500000\n";
	print PAR "DICEITRVL             :        0.100000\n";
	print PAR "* --------------------\n";
	print PAR "* A132\n";
	print PAR "TRNTYPE               : ONLINE\n";  
	print PAR "TRGTYPE               : SIG\n";
	print PAR "ERRTYPE               : DELTASQ\n"; 
	print PAR "MODEPRED              : sec\n";
	if ($bal =~ /unbal/){
		print PAR "MODENET               : 1st,unbal\n";
	}
	else{
		print PAR "MODENET               : 1st,bal\n";
	}
	print PAR "MODEIN                : win=5,loc=aa\n";
	print PAR "MODEOUT               : KN\n";
	print PAR "MODEJOB               : mode_of_job\n";

	print PAR "FILEIN_IN             : $diri/in$name-in\n";
	print PAR "FILEIN_OUT            : $diri/in$name-out\n";
	
	#for training purposes the junction file should be NEW all the time
	print PAR "FILEIN_JCT            : $file_test\n";
	print PAR "FILEIN_SAM            : $diri/in$name-sam\n";
	
	#print as many out file and junction file names as requested
	$i = 1;
	while ($i <= $stpout){
		print PAR "FILEOUT_OUT           : $diro/out$name-out$i\n";
		$i++;
	}
	$i = 1;
	while ($i <= $stpout){
		print PAR "FILEOUT_JCT           : $diro/out$name-jct$i\n";
		$i++;
	}
	
	#hardcode rest
	print PAR "FILEOUT_ERR           : $diro/out$name-err\n";
	print PAR "FILEOUT_YEAH          : $diro/out$name-yeah\n";
	print PAR "//";
	close PAR;
}
