#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# chop hssp for PHD server
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"sexposureali_from_hssp.pl list-hssp-files
#
# task:		extracting from a list of HSSP files the
# 		HSSP sequences (chain) + those from the alis
#
#----------------------------------------------------------------------
#                                                                      #
#----------------------------------------------------------------------#
#	Burkhard Rost			November,	1993           #
#			changed:		,      	1993           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name = "sexposureali_from_hssp.pl";
$script_input= "list_of_hssp_files";

push (@INC, "/zinc2/rost/perl") ;
require "ctime.pl";
require "rs_ut.pl" ;
require "ut.pl";
require "lib-prot.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; 
#$datex = join(':',@Date) ;


#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {
   die "*** ERROR: \n*** usage: \t $script_name $script_input \n";
   print "number of arguments:  \t$ARGV \n";
}

#  ----------------------------------------
#  about script
#  ----------------------------------------
   &myprt_line; &myprt_txt("perl script to extract HSSP sequences + alis");
   &myprt_empty; &myprt_txt("usage: \t $script_name $script_input"); &myprt_empty;

#----------------------------------------
#  read input
#----------------------------------------
   				&myprt_empty;
   $file_list	= $ARGV[1]; 	&myprt_txt("list here: \t \t $file_list"); 

   $Ltalking    = "False";
   $Ltalking    = "True";
   if ($#ARGV > 1) { 
       if ( $ARGV[2] =~ /talk/ ) { 
	   $Ltalking = "True"; 
	   print "--- ==> called with: $script_name $file_list talking -> more print outs! \n";
       }
   }

#------------------------------
# defaults
#------------------------------

   $file_list_tmp	= $file_list;
   $file_list_tmp	=~ s/\.tmp//g;
   $file_list_tmp	=~ s/\.list//g;
   $file_list_tmp	=~ s/\.lifi//g;
   $file_missing        = "$file_list_tmp" . ".missing_files";
				&myprt_txt("missing files:   \t $file_missing");
   $file_pdb_ids        = "$file_list_tmp" . ".pdb_ids";
				&myprt_txt("pdb ids in:      \t $file_pdb_ids");
   $file_wrong_chain    = "$file_list_tmp" . ".wrong_chains";
				&myprt_txt("wrong chains in: \t $file_wrong_chain");
   $file_2hssp_versions = "$file_list_tmp" . ".2hssp_version";
				&myprt_txt("2 hssp versions: \t $file_2hssp_versions");
   $file_out             = "$file_list_tmp" . ".sse2";
				&myprt_txt("wrong chains in: \t $file_out");
   $file_info            = "$file_list_tmp" . ".info";
				&myprt_txt("all infos:       \t $file_info");
   $nalign	= 0; 

   $ext_hssp = ".hssp";
   $dir_hssp = "hssp/";
#   $dir_hssp = "/data/hssp/";

   $water_mode = "07ang";
#   $water_mode = "3ang";
#   $water_mode = "5ang";
#   $water_mode = "";

#------------------------------
#  check existence of file
#------------------------------
   if ( ! -e $file_list ) {
      &myprt_empty; &myprt_txt("ERROR: \t file $file_list does not exist"); exit;
   }

#----------------------------------------
# read list
#----------------------------------------

   &open_file("FILE_WRONG_CHAIN", ">$file_wrong_chain");
   &open_file("FILE_2HSSP_VERSIONS", ">$file_2hssp_versions");
   &open_file("FILE_MISSING", ">$file_missing");
   &open_file("FILE_PDB_IDS", ">$file_pdb_ids");
   &open_file("FILE_LIST", "$file_list");
   &open_file("FILE_OUT", ">$file_out");

   printf FILE_PDB_IDS " %5s %-15s %-6s  %-4s  %-4s  %-10s \n", 
            "no", "swiss_id", "pdb_id", "%ide", "lali", "HSSP file";

   print FILE_WRONG_CHAIN "*** ERROR chain does NOT exist for: \n";

   $cthits = 0;

   while ( <FILE_LIST> ) {
       $tmp   =  $_;
       $tmp2  =  $tmp;
       $tmp2  =~ s/.*\/(\w\w\w\w.*)/$1/g; $tmp2 =~ s/\.hssp//g; $tmp2 =~ s/\s|\n//g; 

       if ( length ($tmp2) > 4 ) {
	   ($file_in, $chain_in) = split('_',$_,2);
	   $file_in 	=~ s/\s//g; $chain_in 	=~ s/\s//g;
       } else {
	   $file_in = substr($_,1);
	   $file_in =~ s/\s|\n//g; $chain_in= "";
       }
       if ( length($chain_in) < 1 ) { $chain_in 	= "X"; }

       &myprt_empty; &myprt_line; &myprt_empty; &myprt_txt("current file: \t -$file_in-");
       if ( $chain_in eq "X" ) { &myprt_txt("current chain: \t not specified"); 
       } else { &myprt_txt("current chain: \t -$chain_in-"); 
       } 
       &myprt_empty; 
#     ------------------------------
#     uninitialise arrays
#     ------------------------------

#--------------------------------------------------
#     reading one HSSP file
#--------------------------------------------------
      if (! -e $file_in ) {	# check existence
	  print FILE_MISSING "$file_in \n";
      } else {
#         ------------------------------
#         read: seq, secstr, exp
#         ------------------------------
	  &read_hssp_seq_exp_secstr($file_in, $chain_in);
	  $hssp_seq = $Seq_Read; $hssp_secstr = $Secstr_Read; $hssp_exp = $Exp_Read;
	  $hssp_pos = $Pos_Read;

#         ------------------------------
#         check: correct chain?
#         ------------------------------
	  if ( length($hssp_seq) < 10 ) {
	      print FILE_WRONG_CHAIN "$file_in, $chain_in \n";
	  } else {

	      $Lxx = "False";	# x.x
	      if ( $Lxx eq "True" ) {
		  &write80_data_prepdata($hssp_seq,$hssp_secstr,$hssp_exp);
		  &write80_data_preptext("AA ", "DSP", "Exp"); &write80_data_do("STDOUT"); 
	      }

#             ------------------------------
#             read: all pdb ids from hssp 
#             ------------------------------
	      &read_pdb_id ("$file_in","$chain_in");
	      print "--- \n";	# x.x print
	      $Lprint = "True";
	      if ( $Lprint eq "True") {
		  for ( $i=1; $i < $#Swissid_Read ;$i ++ ) {
		      printf FILE_PDB_IDS " %5d %-15s %-6s  %-4.2f  %-4d  %-10s \n", 
		         $Swissno_Read[$i], $Swissid_Read[$i], $Pdbid_Read[$i], 
		         $Ide_Read[$i], $Lali_Read[$i], $file_in ;

		      printf  "x.x %5d %-15s %-6s  %-4.2f  %-4d  %-10s \n", 
		         $Swissno_Read[$i], $Swissid_Read[$i], $Pdbid_Read[$i], 
		         $Ide_Read[$i], $Lali_Read[$i], $file_in ;
		  }
	      } 
	      $hssp_tmp = $file_in; $hssp_tmp =~ s/\s//g; $hssp_tmp =~ s/\/.+\/.+\///g;

#             --------------------------------------------------
#             for pdb homologues: read seq, secstr, exp
#             --------------------------------------------------
	      $previous_pdb_tmp = " ";
	      for ( $i=1; $i <= $#Swissid_Read ; $i ++ ) {
		  $tmp_pdbread  = $Pdbid_Read[$i]; $tmp_pdbread =~ tr/[A-Z]/[a-z]/;
		  $tmp_hssphere = $hssp_tmp; $tmp_hssphere =~ s/\/.+\/.+\/|\.hssp//g;
		  $tmp_hssphere =~ tr/[A-Z]/[a-z]/;
		  if ( $hssp_tmp !~ /$Pdbid_Read[$i]/ ) {
		      if ( $Pdbid_Read[$i] =~ /$previous_pdb_tmp/ ) {
			  $Ldo1 = "False";
		      } elsif ( substr($tmp_pdbread,2,3) eq substr($tmp_hssphere,2,3) ) {
			  $Ldo1 = "False";
		      } else {
			  $previous_pdb_tmp = $Pdbid_Read[$i];
			  $Ldo1 = "True";
		      }
		  } else {
		      $Ldo1 = "False";
		  }
				# ----------------------------------------
				# skip if: - same as previous pdb
				#          - same as guide hssp
				#          - current swissprot not PDB
				# ----------------------------------------
		  if ( $Ldo1 =~ "True" ) {
		      print "--- guide: $tmp_hssphere","_$chain_in, search: $tmp_pdbread ",
                            "ali no: $Swissno_Read[$i]","\t" x 5, "main \n";
#                     ------------------------------
#                     read swissprot seq (=PDB)
#                     ------------------------------
		      &read_one_swissprot($file_in, $Swissid_Read[$i], 
					  $chain_in, $Swissno_Read[$i]);

		      if ( length($Seq_Read) <= 10 ) { 
			  print "--- ", "\t" x 8, "main \n"; 
			  print "--- no hit for: $Swissid_Read[$i] in $file_in,", 
                                " chain: $chain_in \n";
			  $Ldo1 = "False";
		      } else {
			  $Ldo1 = "True";
		      }
		  }
				# ----------------------------------------
				# skip also if 
				#          - Swissprot not matching chain
				# ----------------------------------------
		  if ( $Ldo1 =~ "True" ) {

#                     ------------------------------
#                     cut off "-" at begin and end
#                     ------------------------------

		      if ( $Ltalking eq "True" ) {
			  print "xx 0:\t $hssp_seq \n";
			  print "xx   \t $Seq_Read \n";
		      }

		      &cutoff_begend_from_ali($hssp_seq, $hssp_pos, $Seq_Read, $Ifir_Read, 
					      $Ilas_Read, $hssp_secstr, $hssp_exp);
		      &hsspfile_to_pdbid($file_in);
		      $hssporg_seq_cut    = $Seq_hssp_Cut;
		      $hssporg_secstr_cut = $Secstr_hssp_Cut;
		      $hssporg_exp_cut    = $Exp_hssp_Cut;
		      $hsspali_seq_cut    = $Seq_ali_Cut;

		      if ( $Ltalking eq "True" ) {
			  print "xx 1:\t $Seq_hssp_Cut +++ ifir: $Ifir_Read  \n";
			  print "xx   \t $Seq_ali_Cut \n";
		      }
                 	     
		      $hssporg_name       = "$hsspfile_to_pdbid" . "_$chain_in";

		      $Lxx = "False"; # x.x
		      if ( $Lxx eq "True" ) {
			  &write80_data_prepdata($hssporg_seq_cut,$hssporg_secstr_cut,
						 $hssporg_exp_cut, $hsspali_seq_cut);
			  &write80_data_preptext("AA ", "DSP", "Exp", "AA2");
			  &write80_data_do("STDOUT"); 
		      }

#                     ----------------------------------------
#                     read seq, secstr, exp for homologue
#                     ----------------------------------------
		      $file_tmp=$Pdbid_Read[$i]; $file_tmp=~ tr/[A-Z]/[a-z]/; $file_tmp=~ s/_.//g;
		      &pdbid_to_hsspfile($file_tmp,$dir_hssp,$ext_hssp);

		      if (! -e $pdbid_to_hsspfile ) {	# check existence
			  print "*** no HSSP file $pdbid_to_hsspfile !! \n"; 
			  print FILE_MISSING "missing ali:  $pdbid_to_hsspfile \n"; 
			  $Ldo2 = "False";
		      } else {
			  $Ldo2 = "True";
		      }

				# ----------------------------------------
				# skip if: - hssp file of ali not exists
				# ----------------------------------------
		      if ( $Ldo2 eq "True" ) {
			  &read_chainids_from_hssp("$pdbid_to_hsspfile");

			  if ( $#Chainids_Read == 0 ) {
			      print "*** ERROR in $script_name \n";
			      print "*** check HSSP file $pdbid_to_hsspfile !! \n"; 
			      print "*** wc -l: \n"; 
			      &run_program("wc -l $pdbid_to_hsspfile");
			      print FILE_MISSING "check HSSP file:  $pdbid_to_hsspfile \n"; 
			      $Ldo2 = "False";
			  } else {
			      $Ldo2 = "True";
			  }
		      }
				# ----------------------------------------
				# skip also if: 
				#          - hssp file empty
				# ----------------------------------------
		      if ( $Ldo2 eq "True" ) {
#                         ------------------------------
#                         loop over all homologue chains
#                         ------------------------------
				# x.print
			  print "--- in main, for $file_tmp, \t chains: ",@Chainids_Read,"\n";

			  $#Ahssp2nd_seq_cut=0; $#Ahssp2nd_secstr_cut=0; $#Ahssp2nd_exp_cut=0;
			  $#Ahssp2nd_name = 0; $#Ahssp2nd_chain = 0;

                                # x.x change
			  print "--- in main, changed: getting all chains \n";
                          $#Chainids_Read=1; $Chainids_Read[1]= "X";
                                # x.x change
			  for ( $it2=1; $it2<=($#Chainids_Read); $it2 ++ ) {
			      if ( $Chainids_Read[$it2] !~ / / ) {
				  &read_hssp_seq_exp_secstr($pdbid_to_hsspfile, 
							    $Chainids_Read[$it2]);
				# x.print
				  print "--- read chain $Chainids_Read[$it2], i.e. the $it2 .\n";

				  &compare_2sequences($hsspali_seq_cut, $Seq_Read,
						      $Secstr_Read, $Exp_Read);

				  if ( length($Seq2_Cutchange) >= 6 ) {
				      printf FILE_2HSSP_VERSIONS " %-15s, from %-15s_%1s: %-s \n",
                                               $file_tmp, $file_in, $chain_in, $Seq2_Cutchange;
				  }

				  push(@Ahssp2nd_seq_cut,$Seq2_Cut); 
				  push(@Ahssp2nd_secstr_cut,$Secstr2_Cut); 
				  push(@Ahssp2nd_exp_cut,$Exp2_Cut); 
				  push(@Ahssp2nd_name, $pdbid_to_hsspfile);
				  push(@Ahssp2nd_chain, $Chainids_Read[$it2]);
			      }
			  }

#                         ----------------------------------------
#                         if many chains match: take longest match
#                         ----------------------------------------
			  $max = 3; $posmax = 0;
			  for ( $it2=1; $it2<=($#Ahssp2nd_seq_cut); $it2 ++ ) {
			      if ( length($Ahssp2nd_seq_cut[$it2]) > $max ) {
				  $max = length($Ahssp2nd_seq_cut[$it2]);
				  $posmax = $it2;
			      }
			  }
			  if ( $posmax == 0 ) { 
                              if ( $max < 4 ) {
                                  $Ldo3 = "False";
                              } else {
                                  print "*** ERROR in $script_name (main) \n";
                                  print "***  for original: $file_in, \n";
                                 print "***  vs: $pdbid_to_hsspfile, chains:",@Chainids_Read,"\n";
                                  print "***  seq: $Ahssp2nd_seq_cut[1] \n";  
                                  print "***  exit: 16-11-93a \n "; exit;
                              }
                          } else {
                              $Ldo3 = "True";
			  }
                          if ( $Ldo3 =~ /T/ ) {
                              $hssp2nd_seq_cut    = $Ahssp2nd_seq_cut[$posmax];
                              $hssp2nd_secstr_cut = $Ahssp2nd_secstr_cut[$posmax];
                              $hssp2nd_exp_cut    = $Ahssp2nd_exp_cut[$posmax];
		      
                              &hsspfile_to_pdbid($Ahssp2nd_name[$posmax]);
                              $hssp2nd_name="$hsspfile_to_pdbid"."_"."$Ahssp2nd_chain[$posmax]";

#                             ----------------------------------------
#                             write output for longest match
#                             ----------------------------------------

                              $tmp2 = " ";
                              $tmp  = "name: " . "$hssporg_name";
                              $tmp3 = "$hssporg_name"; $tmp3 =~ s/\/.+\/.+\///g; 
                              $tmp3 =~ s/\.hssp//g;
                          
                              printf FILE_OUT "\# 1 %-6s %5d %-11s %-6s     %-4.2f  %-5d \n", 
		                       $tmp3, length($hssp2nd_seq_cut), $tmp2, 
		                       $hssp2nd_name, $Ide_Read[$i], $Lali_Read[$i]; 
                              &write80_data_prepdata($hssp2nd_seq_cut, 
                                                     $hssp2nd_secstr_cut, $hssp2nd_exp_cut,
                                                     $hssporg_seq_cut, $hssporg_secstr_cut, 
                                                     $hssporg_exp_cut);
                              &write80_data_preptext("AA2", "DS2", "Ex2", "AA ", "DSP", "Ex1");
                              &write80_data_do("FILE_OUT"); 
                              ++ $cthits;
                              print "--- \# 1 this was writing protein no. $cthits \n";
#			      close (FILE_OUT); print "x.x: \n"; system("cat $file_out"); exit;
                          }     # end of excluding too often changed hit
		      }		# end of excluding putative wrong HSSP file
		  }		# end of job for one pdb homologue
	      }			# end of loop over all pdb homologues
	  }			# end of check for chain
      }				# end of job for one HSSP file
       print "--- \n";		# x.print
  }				# end of loop over list
  close(FILE_LIST); close(FILE_MISSING); close(FILE_PDB_IDS); close(FILE_WRONG_CHAIN);
  close(FILE_OUT); close(FILE_2HSSP_VERSIONS);

#----------------------------------------
# clean up: all error file into one file
#----------------------------------------

&myprt_empty; &myprt_line; &myprt_txt("now cleaning up"); &myprt_empty; 

&open_file("FILE_INFO", ">$file_info");

print FILE_INFO "-" x 80, "\n", "--- \t 2 different HSSP versions for: \n", "-" x 80, "\n", 
      "--- \n";
&open_file("FILE_TMP", "$file_2hssp_versions");
while (<FILE_TMP>) { print FILE_INFO $_; } close(FILE_TMP); print FILE_INFO "^L \n";
print FILE_INFO "-" x 80, "\n", "--- \t missing HSSP files for: \n", "-" x 80, "\n", 
      "--- \n";
&open_file("FILE_TMP", "$file_missing");
while (<FILE_TMP>) { print FILE_INFO $_; } close(FILE_TMP); print FILE_INFO "^L \n";
print FILE_INFO "-" x 80, "\n", "--- \t wrong HSSP chains searched for in: \n", "-" x 80, "\n", 
      "--- \n";
&open_file("FILE_TMP", "$file_wrong_chain");
while (<FILE_TMP>) { print FILE_INFO $_; } close(FILE_TMP); print FILE_INFO "^L \n";
print FILE_INFO "-" x 80, "\n", "--- \t wrong HSSP chains searched for in: \n", "-" x 80, "\n", 
      "--- \n";
&open_file("FILE_TMP", "$file_pdb_ids");
while (<FILE_TMP>) { print FILE_INFO $_; } close(FILE_TMP); print FILE_INFO "^L \n";

close(FILE_INFO);
system("rm -f $file_2hssp_versions"); system("rm -f $file_missing");
system("rm -f $file_wrong_chain"); system("rm -f $file_pdb_ids");


  &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
  &myprt_line; &myprt_empty; 

exit;

#==========================================================================
sub read_pdb_id {
    local ($file_in, $chain_in) = @_ ;
    local ($fh_in, $ctmp, $i, $sub_name);
    local ($swiss_idtmp, $pdb_idtmp, $swiss_notmp, $identity_tmp, $lali_tmp);
    local ($ifir_tmp, $ilas_tmp, $tmp, $chain_tmp);
    local ($pdb_idtmp, @ifir_loc, @ilas_loc, $Lprint); 
    local (@swiss_id, @swiss_no, @pdb_id, @identity, @lali, @Lok_pdb_id);

#----------------------------------------------------------------------
#  reads and writes the sequence of HSSP + 70 alis
#         input:  hssp_file, chain
#         output: @Swissid_Read, @Swissno_Read, @Pdbid_Read, @Ide_Read, @Lali_Read, 
#----------------------------------------------------------------------
    $sub_name = "read_pdb_id";

    $#Swissid_Read = 0; $#Swissno_Read = 0; $#Pdbid_Read = 0; 
    $#Ide_Read = 0; $#Lali_Read = 0; 

    $#swiss_id = 0; $#swiss_no = 0; $#pdb_id = 0; $#identity = 0; $#lali = 0; $#Lok_pdb_id = 0;
    $#ifir_loc = 0; $#ilas_loc = 0; 

    $fh_in = "FILEIN_LOC"; 
    open($fh_in,$file_in)  		|| warn "*** $sub_name: Can't open $file_in:\nread: $!\n";

#------------------------------
#  get swissprot identifiers
#------------------------------
   while ( <$fh_in> ) {
      if ( /^NALIGN/ ) {
         ($ctmp, $nalign)= split('  ',$_,2); 
         $nalign	=~ s/\s//g;
      }
      last if ( /## PROTEINS/ );
   }

#------------------------------
#     get number of alignments
#------------------------------
      $ct=0;
      while ( <$fh_in> ) {
	  last if ( /\#\# ALIGNMENTS/ );
	  if (! /^  NR/ ) {
	      ++$ct;
				# extract swiss and pdb id
	      $swiss_notmp =  substr($_,2,5);
	      $swiss_idtmp =  substr($_,8,12);
	      $pdb_idtmp   =  substr($_,21,4);
	      $identity_tmp=  substr($_,29,4);
	      $lali_tmp    =  substr($_,60,4);
	      $ifir_tmp =  substr($_,40,4); 
	      $ilas_tmp =  substr($_,45,4);
				# delete spaces
	      $swiss_notmp =~ s/\s//g; $swiss_idtmp =~ s/\s//g; 
	      $pdb_idtmp   =~ s/\s//g; $pdb_idtmp   =~ tr/[A-Z]/[a-z]/;
	      $lali_tmp    =~ s/\s//g;
	      $ifir_tmp =~ s/\s//g; $ilas_tmp =~ s/\s//g;
         
	      if ( length($pdb_idtmp) == 0 ) { $pdb_idtmp = "NPDB"; }
	      push(@swiss_id,$swiss_idtmp); push(@swiss_no,$swiss_notmp);
	      push(@pdb_id,$pdb_idtmp);
	      push(@identity,$identity_tmp); push(@lali,$lali_tmp);
	      push(@ifir_loc,$ifir_tmp); push(@ilas_loc,$ilas_tmp);
	  }
      }

#------------------------------
#     get chain position
#------------------------------
      $ifir_tmp = 0; $ilas_tmp = 0;
      while ( <$fh_in> ) {
	  last if ( /\#\# / );
	  if (! /^ SeqNo/ ) {
	      $chain_tmp = substr($_,13,1);
	      if ( ($chain_tmp eq "$chain_in") || ($chain_in eq "X") ) {
		  if ( $ifir_tmp == 0 ) {
		      $tmp = substr($_,2,5); $tmp =~ s/\s//g;
		      $ifir_tmp = $tmp;
		  }
		  $tmp = substr($_,2,5); $tmp =~ s/\s//g;
		  $ilas_tmp = $tmp;
	      }
	  }
      } 
      close($fh_in);

      $Lprint = "False";
      $Lprint = "True";
      if ( $Lprint eq "True") {
	  print "--- ", "\t" x 8, "$sub_name: \n";
	  printf "--- %5s %-15s %-6s  %-4s  %-4s  %-10s \n", "no", "swiss_id", "pdb_id", 
                 "%ide", "lali", "HSSP file";
	  for ( $i=1; $i < $#swiss_id ;$i ++ ) {
	      if ( $pdb_id[$i] ne "NPDB" ) {
		  if ( ($ifir_loc[$i] > $ilas_tmp) || ($ilas_loc[$i] < $ifir_tmp) ) {
		      $Lok_pdb_id[$i] = "Exclude";
#		      print "xx i: $i, pdb: $pdb_id[$i], ifir: $ifir_tmp, ilas: $ilas_tmp \n";
#		      print "xx arr: fir: $ifir_loc[$i], las: $ilas_loc[$i], \n";
		  } else {
		      $Lok_pdb_id[$i] = "ok";
		      printf "--- %5d %-15s %-6s  %-4.2f  %-4d  %-4d $-4d %-10s \n", 
		             $swiss_no[$i], $swiss_id[$i], $pdb_id[$i], $identity[$i], 
		             $lali[$i], $ifir_loc[$i], $ilas_loc[$i], $file_in ;
		      push(@Swissid_Read, $swiss_id[$i]); push(@Swissno_Read, $swiss_no[$i]);
		      push(@Pdbid_Read, $pdb_id[$i]); push(@Ide_Read, $identity[$i]);
		      push(@Lali_Read, $lali[$i]);
		  }
	      }
	  }
      }
 }

#==========================================================================
sub read_chainids_from_hssp {
    local ($file_in) = @_ ;
    local ($tmp_chain, $i);
    local ($Lexit, $fh_in, $tmp_nochain, $tmp1, $tmprest);
    local ($prev_chain_tmp);

#----------------------------------------------------------------------
#  read all chain identifiers from one hssp file
#----------------------------------------------------------------------

    $fh_in = "FILEINTMP";
    &open_file("$fh_in", "$file_in");

    $Lexit = "False";
    $tmp_nochain = 0;
    $#Chainids_Read = 0;
    while (<$fh_in>) {
	if ( /^NCHAIN/ ) {
	    ($tmp1,$tmp_nochain,$tmprest)=split(' ',$_,3);
	    $tmp_nochain =~ s/\s//g;
	    if ( $tmp_nochain == 1 ) {
		push(@Chainids_Read,"X");
		$Lexit = "True";
	    }
	}
	last if ( /^## ALIGNMENTS/ ) ;
     }

     $prev_chain_tmp = " ";
     while (<$fh_in>) {
	 last if ( $Lexit =~ /True/ );
	 if (! /^ SeqNo/ ) {
	     $tmp_chain = substr($_,13,1);
	     if ( $tmp_chain !~ /$prev_chain_tmp/ ) {
		 $prev_chain_tmp = $tmp_chain;
		 push(@Chainids_Read,$prev_chain_tmp);
		 if ( $tmp_nochain == $#Chainids_Read ) {
		     $Lexit = "True";
		 }
	     }
	 } 
     }
     close($fh_in);
}

#==========================================================================
sub read_one_swissprot {
    local ($file_in, $name_in, $chain_in , $swissno_in) = @_ ;
    local ($hssp_name, $fh_in, $swiss_notmp, $swiss_idtmp);
    local ($no_here, $ctskip, $ct, $ct2, $tmp1, $tmp2, $tmp);
    local ($tmpchain, @tmpseq, @no_here_vec, $i);
    local ($sub_name);
    local ($ifir_tmp, $ilas_tmp, $jfir_tmp, $jlas_tmp);
    local (@ifir_vec, @ilas_vec, @jfir_vec, @jlas_vec);

#----------------------------------------------------------------------
#  reads one swissprot sequence: name_in from the hssp file file_in
#         input:  hssp_file, swissprot_id_tobe_extracted, chain_of_hssp, number_of_swiss
#         output: Seq_Read, Ifir_Read, Ilas_Read, Jfir_Read, Jlas_Read
#----------------------------------------------------------------------

#------------------------------
#   string for result:
#------------------------------
    $sub_name = "read_one_swissprot";

    $Seq_Read   = "";
    $#tmpseq=0; $#no_here_vec=0, $#ifir_vec=0; $#ilas_vec=0; $#jfir_vec=0; $#jlas_vec=0;
    if (length($chain_in) == 0) { $chain_in = "X" ; }

#    print "$sub_name input: \n", "$file_in, $name_in, $chain_in , $swissno_in \n";


    $hssp_name = $file_in; $hssp_name =~ s/\/.+\/.+\///g; $hssp_name	=~ s/\.hssp//;

#--------------------------------------------------
#  read in file
#--------------------------------------------------

    $fh_in = "FILEIN_LOC"; 
    open($fh_in,$file_in)  		|| warn "*** $sub_name: Can't open $file_in:\nread: $!\n";

#----------------------------------------
#  read in name to find position
#----------------------------------------
    while ( <$fh_in> ) {
	last if ( /\#\# PROTEINS/ );
    }
    $no_here = 0;
    $#no_here_vec = 0; $#ifir_vec = 0; $#ilas_vec = 0; $#jfir_vec = 0; $#jlas_vec = 0; 
    
    while ( <$fh_in> ) {
	if (! /^  NR/ ) {
	    $swiss_notmp =  substr($_,2,5);
	    $swiss_idtmp =  substr($_,8,12);
	    $ifir_tmp =  substr($_,40,4); $ilas_tmp =  substr($_,45,4);
	    $jfir_tmp =  substr($_,50,4); $jlas_tmp =  substr($_,55,4);

	    $swiss_notmp =~ s/\s//g; $swiss_idtmp =~ s/\s//g;
	    $ifir_tmp =~ s/\s//g; $ilas_tmp =~ s/\s//g;
	    $jfir_tmp =~ s/\s//g; $jlas_tmp =~ s/\s//g;

	    if ( $swiss_idtmp eq $name_in ) {
		$no_here = $swiss_notmp; 
		push(@no_here_vec, $swiss_notmp);
 		push(@ifir_vec, $ifir_tmp); push(@ilas_vec, $ilas_tmp);
 		push(@jfir_vec, $jfir_tmp); push(@jlas_vec, $jlas_tmp);
	    } 
	}
	if ( /\#\# ALIGNMENTS/ ) {
	    $tmp1 = substr ($_,15,4); $tmp1 =~ s/\s//g; 
	    $tmp2 = substr ($_,22,4); $tmp2 =~ s/\s//g; 
	}
	last if ( /\#\# ALIGNMENTS/ );
    }

#----------------------------------------
#   if explicit number given: take it
#----------------------------------------
    if ( length($swissno_in) > 0 ) {
	$no_here = $swissno_in; 
	for ( $i=1; $i <= $#no_here_vec ;$i ++ ) {
	    if ( $no_here_vec[$i] == $no_here ) {
		$ifir_tmp = $ifir_vec[$i]; $ilas_tmp = $ilas_vec[$i]; 
		$jfir_tmp = $jfir_vec[$i]; $jlas_tmp = $jlas_vec[$i]; 
	    }
	}
	$#no_here_vec = 0; $#ifir_vec = 0; $#ilas_vec = 0; $#jfir_vec = 0; $#jlas_vec = 0; 
	push(@no_here_vec, $no_here);
	push(@ifir_vec, $ifir_tmp); push(@ilas_vec, $ilas_tmp);
	push(@jfir_vec, $jfir_tmp); push(@jlas_vec, $jlas_tmp);
    }
    

#----------------------------------------
#  skip all those alis before the current seq
#----------------------------------------
    $ct = 1; 
    $ctskip = int(($no_here-1)/(70)); 
    if ( $ctskip > 0 ) {
	while ( <$fh_in> ) {
	    if ( /^## ALIGNMENTS/ ) {
		++ $ct;
	    }
	    if ( $ct > $ctskip ) {
		$tmp1 = substr ($_,15,4); $tmp1 =~ s/\s//g; 
		$tmp2 = substr ($_,22,4); $tmp2 =~ s/\s//g; 
	    }
	    last if ( $ct > $ctskip );
	}
    }

#----------------------------------------
#  consistency check
#----------------------------------------
   if ( ($no_here >= $tmp1) && ($no_here <= $tmp2) ) { 
   } else {
       print "*** ERROR: read_one_swissprot wrong extract: \n";
       print "*** no_here: $no_here, alis from $tmp1 to $tmp2, ctskip = $ctskip \n";
       exit;
   }

#----------------------------------------
#  read sequences
#----------------------------------------
   while ( <$fh_in> ) {
       if ( /^ SeqNo/ ) { 
	   for ( $i=1; $i <= $#no_here_vec ;$i ++ ) {
	       $tmpseq[$i] = "";
	   }
       } else {
	   last if ( /^## / ) ;
           $tmpchain = substr($_,13,1); 
	   if ( ($tmpchain eq "$chain_in") || ($chain_in eq "X") ) {
	       for ( $i=1; $i <= $#no_here_vec ;$i ++ ) {
		   $ct2 = (51+$no_here_vec[$i]);
		   if ($ctskip >= 1) { $ct2 -= $ctskip*70 ; }
		   $tmpseq[$i] .=  substr($_,$ct2,1);
	       }
	   } 
       }
   }
   close($fh_in);

#--------------------------------------------------
#  now extract sequences from alis
#--------------------------------------------------

   for ( $i=1; $i <= $#no_here_vec ;$i ++ ) {
       $tmp = $tmpseq[$i];
       $tmp =~ s/\s//g;
       if ( length ($tmp) >= 10 ) {
	   $Seq_Read = $tmpseq[$i];
	   $Seq_Read =~ s/\s/-/g;
	   $Ifir_Read = $ifir_vec[$i]; $Ilas_Read = $ilas_vec[$i]; 
	   $Jfir_Read = $jfir_vec[$i]; $Jlas_Read = $jlas_vec[$i]; 
#           print "read_one: $i  $Seq_Read \n "; 
           printf "--- i: %-4d -> %-4d \t j: %-4d -> %-4d  %-s\t \t%-s \n", 
	          $Ifir_Read,$Ilas_Read,$Jfir_Read,$Jlas_Read,$name_in,$sub_name;
       }
   }

  }				# end of: read_one_swissprot

#==========================================================================
sub read_hssp_seq_exp_secstr {
    local ($file_in, $chain_in ) = @_ ;
    local ($hssp_name, $swiss_notmp, $swiss_idtmp);
    local ($ctskip,  $ct, $fh_in, $sub_name);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppos);
    local ($tmpseq2, $tmpsecstr2, $tmpexp2, $tmpexp3);

#----------------------------------------------------------------------
#   reads one swissprot sequence: name_in from the hssp file file_in
#         input:  hssp_file, chain
#         output: Seq_Read, Secstr_Read, Exp_Read, Pos_Read
#----------------------------------------------------------------------
    $sub_name = "read_hssp_seq_exp_secstr" ;

#----------------------------------------
#   set normalisation weights for exposure
#----------------------------------------
    &exposure_normalise_prepare($water_mode);

#----------------------------------------
#   string for result:
#----------------------------------------
    $Seq_Read   = "";
    $Secstr_Read= "";
    $Exp_Read   = "";
    $Pos_Read   = "";

    $hssp_name = $file_in; $hssp_name =~ s/\.hssp//; $hssp_name =~ s/\/.+\/.+\///g;
    if (length($chain_in) == 0) { $chain_in = "X" ; }

#--------------------------------------------------
#  read in file
#--------------------------------------------------

    $fh_in = "FILEIN_LOC"; 
    open($fh_in,$file_in)  		|| warn "*** $sub_name: Can't open $file_in:\nread:$!\n";

#----------------------------------------
#  skip anything before data...
#----------------------------------------
    while ( <$fh_in> ) {
	last if ( /^## ALIGNMENTS/ );
    }

#----------------------------------------
#  read sequence
#----------------------------------------
   while ( <$fh_in> ) {
      if (! / SeqNo / ) { 
         last if ( /^## / ) ;
         $tmpchain =  substr($_,13,1); 
         if ( ($tmpchain eq "$chain_in") || ($chain_in eq "X") ) {
	     $tmpseq    = substr($_,15,1);
	     $tmpsecstr = substr($_,18,1);
	     $tmpexp    = substr($_,37,3);
	     $tmppos    = substr($_,2,5); $tmppos =~ s/\s//g; $tmppos .= "-";

             $tmpseq2   = $tmpseq;
	     if ( $tmpseq2 =~ /[a-z]/ ) {
		 $tmpseq2 = "C";
	     }
             &secstr_convert_dsspto3($tmpsecstr);
             $tmpsecstr2= $secstr_convert_dsspto3;
	     if ( ($tmpseq2 !~ /[A-Z]/) && ($tmpseq2 !~ /!/) ) { 
		 print "*** $sub_name: ERROR: $file_in \n";
		 print "*** small cap sequence: $tmpseq2 ! exit 15-11-93b \n" , "$_"; exit; 
	     }
             &exposure_normalise($tmpexp,$tmpseq2);
             $tmpexp2   = $exposure_normalise;

#            ------------------------------
#            project exposure onto 1 digit
#            ------------------------------
             &exposure_project_1digit($tmpexp2);
             $tmpexp3   = $exposure_project_1digit;

	     $Seq_Read    .= $tmpseq;
	     $Secstr_Read .= $tmpsecstr2;
	     $Exp_Read    .= $tmpexp3;
	     $Pos_Read    .= $tmppos;
         } 
      } 
   }
   close($fh_in);
}                               # end of: read_hssp_seq_exp_secstr


#==========================================================================
sub cutoff_begend_from_ali {
    local ( $seq_hssp_tmp, $pos_hssp_tmp, $seq_ali_tmp, $ifir_ali_tmp, $ilas_ali_tmp, 
	   $secstr_hssp_tmp, $exp_hssp_tmp ) = @_ ;
    local ( @Aseq_hssp_tmp, @Aseq_ali_tmp, @Asecstr_hssp_tmp, @Aexp_hssp_tmp );
    local ( $sub_name ) ;
    local ( @Apos_hssp_tmp, $ct, $i );
#--------------------------------------------------------------------------------
#   writes hssp seq + sec str + exposure(projected onto 1 digit) into 
#   file with 80 characters per line
#         input:  hssp_seq, hssp_pos, ali_seq, ali_pos (pointer to ifir of hssp file),
#                 hssp_secstr, hssp_exp
#         output: Seq_hssp_Cut, Secstr_hssp_Cut, Exp_hssp_Cut, Seq_ali_Cut
#--------------------------------------------------------------------------------
    $sub_name          = "cutoff_begend_from_ali";

#    print"input to $sub_name: \n"; print"hssp: $seq_hssp_tmp\n"; print"ali : $seq_ali_tmp\n";
#    print"i: $ifir_ali_tmp -> $ilas_ali_tmp, $pos_hssp_tmp\n";

    $#Aseq_hssp_tmp =0; $#Aseq_ali_tmp =0; 
    $#Apos_hssp_tmp =0; $#Asecstr_hssp_tmp =0; $#Aexp_hssp_tmp =0; 

    @Aseq_hssp_tmp     = split(//,$seq_hssp_tmp);
    @Apos_hssp_tmp     = split(/-/,$pos_hssp_tmp);
    @Aseq_ali_tmp      = split(//,$seq_ali_tmp);
    @Asecstr_hssp_tmp  = split(//,$secstr_hssp_tmp);
    @Aexp_hssp_tmp     = split(//,$exp_hssp_tmp);

#------------------------------
#   check for length equality
#------------------------------
    if ( length($seq_hssp_tmp) < length($seq_ali_tmp) ) {
	print "*** cutoff_begend_from_ali: length not equal ! \n";
	print "*** hssp: ",length($seq_hssp_tmp),", ali: ",length($seq_ali_tmp),"\n";
#	exit;
    }

#------------------------------
#   check for length equality
#------------------------------
    $Seq_hssp_Cut = ""; $Seq_ali_Cut = ""; $Secstr_hssp_Cut = ""; $Exp_hssp_Cut = "";
    $ct = 0; 

    for ($i=1; $i<$#Aseq_hssp_tmp; $i++) {
	if ( ($Apos_hssp_tmp[$i] >= $ifir_ali_tmp) && ($Apos_hssp_tmp[$i] <= $ilas_ali_tmp) ) {
	    last if ( $ct >= $#Aseq_ali_tmp );
	    ++$ct;
	    while ( $Aseq_ali_tmp[$ct] =~ /-/ ) {
		++$ct;
	    }
	    if ( $Aseq_ali_tmp[$ct] !~ /-/ ) {
		$Seq_hssp_Cut    .= $Aseq_hssp_tmp[$i];
		$Seq_ali_Cut     .= $Aseq_ali_tmp[$ct];
		$Secstr_hssp_Cut .= $Asecstr_hssp_tmp[$i];
		$Exp_hssp_Cut    .= $Aexp_hssp_tmp[$i];
	    } else {
		print "*** ERROR in $sub_name \n";
		print "*** '-' detected for i = $i, $seq_ali_tmp \n";
		print "*** exit: 14-11-1993 \n"; exit;
	    }
	}
    }

#    print"output from $sub_name: \n"; print"hssp: $Seq_hssp_Cut\n"; print"ali : $Seq_ali_Cut\n";

}

#==========================================================================
sub compare_2sequences {
    local ( $seq1, $seq2, $secstr2, $exp2 ) = @_;
    local ( @Aseq1_tmp, @Aseq2_tmp, @Asecstr2_tmp, @Aexp2_tmp);
    local ( $i, $ct, $ct2, $ct_change, $tmp, $tmp2, $sub_name);
    local ( $Lprev_small, $Lchange, $Ladd, $Ldel);
    local ( $tmp1h, $tmp1n, $tmp2h, $tmp2n);
#----------------------------------------------------------------------
#   writes hssp seq + sec str + exposure(projected onto 1 digit) into 
#   file with 80 characters per line
#         input:  seq1, seq2, secstr2, exp2
#         output: Seq2_Cut, Secstr2_Cut, Exp2_Cut, Seq2_Cutdel, Seq2_Cutchange
#----------------------------------------------------------------------

#--------------------------------------------------
#   defaults
#--------------------------------------------------
    $sub_name = "compare_2sequences";
    @Aseq1_tmp     = split(//,$seq1);
    @Aseq2_tmp     = split(//,$seq2);
    @Asecstr2_tmp  = split(//,$secstr2);
    @Aexp2_tmp     = split(//,$exp2);
    $Seq2_Cut = ""; $Secstr2_Cut = ""; $Exp2_Cut = ""; $Seq2_Cutdel = "";
    $Seq2_Cutchange = "";

    if ( $Ltalking eq "True" ) {
        print " input to $sub_name \n"; print "1: $seq1 \n"; print "2: $seq2 \n";
    }

#------------------------------------------------------------
#   in search: small caps -> C
#------------------------------------------------------------
    for ($i=1; $i<$#Aseq2_tmp; $i++) {
	if ( $Aseq2_tmp[$i] =~ /[a-z]/ ) {
	    $Aseq2_tmp[$i] = "C";
	}
    }

#------------------------------------------------------------
#   compare the two sequences (loop over 2, implicit over 1)
#------------------------------------------------------------
    $ct = 1; $ct_change = 0;
    $Lprev_small = "False";

    for ($i=1; $i<$#Aseq2_tmp; $i++) {
				# delete residues in seq 2
	if ( $ct > $#Aseq1_tmp ) {
	    $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
	} else {
				# add "." to seq2 
	    if ( $Aseq1_tmp[$ct] eq "\." ) {
		if ( $Lprev_small =~ /True/ ) {
		    $Lprev_small = "False";
		}
		while ( $Aseq1_tmp[$ct] eq "\." ) {
		    $Seq2_Cut    .= "."; $Secstr2_Cut .= "."; $Exp2_Cut    .= ".";
		    ++$ct;
		}
	    }

				# delete anything not matchin 3 residues for begin
	    if ( $ct < 2 ) {
                if ( ($Aseq1_tmp[$ct] ne $Aseq2_tmp[$i]) || 
                    ($Aseq1_tmp[$ct+1] ne $Aseq2_tmp[$i+1]) || 
                    ($Aseq1_tmp[$ct+2] ne $Aseq2_tmp[$i+2]) ) {
                    $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
                } elsif ( ($Aseq1_tmp[$ct+10] ne $Aseq2_tmp[$i+10]) || 
                    ($Aseq1_tmp[$ct+11] ne $Aseq2_tmp[$i+11]) || 
                    ($Aseq1_tmp[$ct+12] ne $Aseq2_tmp[$i+12]) ) {
                } else {
                    $Seq2_Cut    .= "$Aseq2_tmp[$i]";
                    $Secstr2_Cut .= "$Asecstr2_tmp[$i]";
                    $Exp2_Cut    .= "$Aexp2_tmp[$i]";
                    ++$ct;
                }
				# set secstr, exp -> output
	    } elsif ( $Aseq1_tmp[$ct] eq $Aseq2_tmp[$i] ) {
		$Seq2_Cut    .= "$Aseq2_tmp[$i]";
		$Secstr2_Cut .= "$Asecstr2_tmp[$i]";
		$Exp2_Cut    .= "$Aexp2_tmp[$i]";
		++$ct;
		if ( $Lprev_small =~ /True/ ) {
		    $Lprev_small = "False";
		}
				# small caps in guide
	    } elsif ( $Aseq1_tmp[$ct] =~ /[a-z]/ ) {
		$tmp = $Aseq1_tmp[$ct];
		$tmp =~ tr/[a-z]/[A-Z]/;
				# set secstr, exp -> output
                if ( $Lprev_small =~ /F/ ) {
                    if ( $tmp =~ /$Aseq2_tmp[$i]/ ) {
                        $tmp2 = "$Aseq2_tmp[$i]"; $tmp2 =~ tr/[A-Z]/[a-z]/;
                        $Seq2_Cut    .= "$tmp2";
                        $Secstr2_Cut .= "$Asecstr2_tmp[$i]";
                        $Exp2_Cut    .= "$Aexp2_tmp[$i]";
                        ++$ct;
                        $Lprev_small = "True";
                    } else {	
				# delete residues in seq 2
                        $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
                    }
                } else {
                    if ( ($tmp=~ /$Aseq2_tmp[$i]/) && ($Aseq1_tmp[$ct+1]=~ /$Aseq2_tmp[$i+1]/) ) {
                        $tmp2 = "$Aseq2_tmp[$i]"; $tmp2 =~ tr/[A-Z]/[a-z]/;
                        $Seq2_Cut    .= "$tmp2";
                        $Secstr2_Cut .= "$Asecstr2_tmp[$i]";
                        $Exp2_Cut    .= "$Aexp2_tmp[$i]";
                        ++$ct;
                        $Lprev_small = "False";
                    } else {	
				# delete residues in seq 2
                        $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
                    }
                }
				# delete
	    } elsif ( $Aseq2_tmp[$i] =~ / |\.|-/ ) {
                $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
				# delete at begin
	    } elsif ( $ct < 2 ) {
                $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
				# ==================================================
				# change residues !!! different head hssp and search  !!!
				# only if next not equal, than delete
				# ==================================================
	    } else {
		$Ladd = "False"; $Lchange = $Ladd; $Ldel = $Ladd;
		$tmp2h  = $Aseq2_tmp[$i];   $tmp2h =~ tr/[a-z]/C/;
		$tmp1h  = $Aseq1_tmp[$ct];  $tmp1h =~ tr/[a-z]/[A-Z]/;
		if ( $i == $#Aseq2_tmp ) { $tmp2n = "";
		} else { $tmp2n=$Aseq2_tmp[$i+1]; $tmp2n=~ tr/[a-z]/C/;
		    if ( ($i+1) == $#Aseq2_tmp ) { $tmp2nn ="";
		    } else { $tmp2nn=$Aseq2_tmp[$i+2];$tmp2nn=~ tr/[a-z]/C/; }
		}
		if ( $ct == $#Aseq1_tmp ) { $tmp1n = "";
		} else { $tmp1n=$Aseq1_tmp[$ct+1]; $tmp1n=~ tr/[a-z]/[A-Z]/;
		    if ( ($ct+1) == $#Aseq1_tmp ) { $tmp1nn ="";
		    } else { $tmp1nn=$Aseq1_tmp[$ct+2];$tmp1nn=~ tr/[a-z]/[A-Z]/; }
		}
					# case insert: 1: KRLV, 2: KLV
		if ( ((length($tmp1n)>0)&&($tmp1n eq $tmp2h)) && 
		    ((length($tmp1nn)>0)&&($tmp1nn eq $tmp2n)) ) {
		    $Ladd = "True";
		} else {
		    if ( ((length($tmp2n)>0)&&(length($tmp1n)>0)&&($tmp2n eq $tmp1n)) &&
			((length($tmp2nn)>0)&&(length($tmp1nn)>0)&&($tmp2nn eq $tmp1nn)) ) {
#			print " changed: $tmp1h $tmp1n $tmp1nn, $tmp2h $tmp2n $tmp2nn \n";
			$Lchange = "True";
		    } else {
				# case delete: 1: KLV, 2: KRLV, + complete miss-hits
			$Ldel = "True";
		    }
		}

                if ( $Ldel =~ /T/ ) { $Ldel = "False"; $Lchange = "True"; $Ladd = "False";}
		if ( $Ldel =~ /True/ ) {
				# delete residues in seq 2
		    $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
		} elsif ( $Ladd =~ /True/ ) {
				# add insertions in seq 2
		    $Seq2_Cut    .= "."; $Secstr2_Cut .= "."; $Exp2_Cut    .= ".";
		    ++$ct;
				# change
		} elsif ( $Lchange =~ /True/ ) {
                    ++$ct_change;
		    $Seq2_Cut    .= "$Aseq2_tmp[$i]";
		    $Secstr2_Cut .= "$Asecstr2_tmp[$i]";
		    $Exp2_Cut    .= "$Aexp2_tmp[$i]";
		    $Seq2_Cutchange .= "$Aseq2_tmp[$i]:$i->$Aseq1_tmp[$ct],";
		    ++$ct;
		} else {
				# delete residues in seq 2
		    $Seq2_Cutdel .= "$Aseq2_tmp[$i]";
		}
	    }			# end of case discrimination: A, ., a
	}			# end of ct < length seq1
    }				# end of loop over seq2

    if ( $ct_change > (length($seq1)/3.) ) {
	print "*** \n", "*** $sub_name: too many changes: refused! \n", "*** \n";
        print "1: $seq1 \n";
        print "2: $Seq2_Cut \n"; 
        print "c: $Seq2_Cutchange \n";
        $Seq2_Cut = " ";
    }

    if ( $Ltalking eq "True" ) {
        print "output from $sub_name \n"; print "1: $seq1 \n"; print "2: $Seq2_Cut \n";
    }
#    print "ct = $ct , i = $i, len1: $#Aseq1_tmp, len2: $#Aseq2_tmp \n";
#    print "deleted: $Seq2_Cutdel \n";
    if ( (length($Seq2_Cutchange) >= 6) && (length($Seq2_Cut) >= 2 )) {
	print "*** $sub_name: changed: $Seq2_Cutchange \n"; 
    }

#----------------------------------------
#   security check
#----------------------------------------
    if ( length($seq1) < length($Seq2_Cut) ) {
	print "*** ERROR: $sub_name: length of original < than of aligned: \n";
	print "***        seq1: ", length($seq1), " Seq2_Cut: ", length($Seq2_Cut), " \n";
	exit;
    }

}



