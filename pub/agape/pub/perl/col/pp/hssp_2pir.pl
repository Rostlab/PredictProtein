#!/usr/pub/bin/perl 
#----------------------------------------------------------------------
# chop hssp for PHD server
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"myhssp_to_pir.pl list-hssp-files
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

$script_name = "myhssp_to_pir.pl";
$script_input= "list_of_hssp_files";

push (@INC, "/home/rost/perl") ;
require "ctime.pl";
#require "rs_ut.pl" ;
require "lib-ut.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; $date = join(':',@Date) ;


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

#------------------------------
# defaults
#------------------------------

   $sweeps_max	= 30;		&myprt_txt("maximal no alis: \t $sweeps_max*70");

   $file_list_tmp	= $file_list;
   $file_list_tmp	=~ s/\.tmp//g;
   $file_list_tmp	=~ s/\.list//g;
   $file_list_tmp	=~ s/\.lifi//g;
   $file_missing= "$file_list_tmp" . ".missing_files";
				&myprt_txt("missing files: \t $file_missing");
   $file_swiss_ids = "$file_list_tmp" . ".swissprot_ids";
				&myprt_txt("swissprot ids in:\t $file_swiss_ids");
   $file_wrong_chain = "$file_list_tmp" . ".wrong_chains";
				&myprt_txt("wrong chains in: \t $file_wrong_chain");
   $seq_char_per_line = 80;
   $nalign	= 0; 


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
   &open_file("FILE_MISSING", ">$file_missing");
   &open_file("FILE_SWISS_IDS", ">$file_swiss_ids");
   &open_file("FILELIST", "$file_list");

   printf FILE_SWISS_IDS "%-15s %-6s %-10s %-2s %-5s \n", "swiss_id", "pdb_id", "HSSP file", "ch", "noseq";

   print FILE_WRONG_CHAIN "*** ERROR chain does NOT exist for: \n";

   while ( <FILELIST> ) {
      ($file_in, $chain_in) = split('_',$_,2);
      $file_in 		=~ s/\s//g;
      $chain_in 	=~ s/\s//g;
      if ( length($chain_in) < 1 ) {
         $chain_in 	= "X";
      }
      &myprt_txt("current file: \t -$file_in-");
      &myprt_txt("current chain: \t -$chain_in-"); &myprt_empty; 

#--------------------------------------------------
#     reading one HSSP file
#--------------------------------------------------
      if (! -e $file_in ) {			# check existence
         print FILE_MISSING "$file_in \n";
      } else {

						# get swissprot ids
         &read_swissprot_id ("$file_in");

#        --------------------------------------------------
#        loop over n-tuples of 70 alignments
#        --------------------------------------------------
         $sweeps_count 	= 0;
         $Lsweeps_end	= "False";
         while ( $Lsweeps_end =~ "False" ) {
            $sweeps_count ++;
            if ( $sweeps_count == 1 ) { $Lwrite_hssp = "True";
            } else { $Lwrite_hssp = "False"; }

            &read_70alis ("$file_in", "$chain_in", $sweeps_count);
#           ------------------------------
#           exit if too many sweeps or too few alis
#           ------------------------------
            if ( $nalign <= ($sweeps_count*70) ) { $Lsweeps_end = "True"; }
            if ( $sweeps_count == $sweeps_max ) { 
               $Lsweeps_end = "True"; 
               print "\n*** WARNING: \n*** for $hssp_name more alis are possible \n";
            }
         }


#        ------------------------------
#        mv files into directories
#        ------------------------------
         $tmpfile = $file_in; $tmpfile =~ s/\/data\/hssp\///;
         $tmp = substr($tmpfile,1,2); 
         if ($tmp =~ /[3-9]/) { $tmp2 = substr($tmp,1,1); $tmp2 .= "x";
         } elsif ($tmp =~ /2[a-k]/) { $tmp2 = "2a";
         } elsif ($tmp =~ /2[m-z]/) { $tmp2 = "2m";
         } elsif ($tmp =~ /1[a-e]/) { $tmp2 = "1a";
         } elsif ($tmp =~ /1[f-m]/) { $tmp2 = "1f";
         } elsif ($tmp =~ /1[n-z]/) { $tmp2 = "1n";
         }
         $tmpd = "dir.PIR/d" . "$tmp2" . "/";
         print "--- now moving files into directory: $tmpd \n";
         system("mv *.pir $tmpd");

#        ------------------------------
#        writing swissprot identifiers
#        ------------------------------
         $swiss_tmp = "xx";
         for ( $i=1; $i < $#swiss_id_here ;$i ++ ) {
            if ( $swiss_tmp !~ /$swiss_id_here[$i]/ ) {		# unique
               $swiss_tmp .= $swiss_id_here[$i];
               if ( $pdb_id_here[$i] !~ /NPDB/ ) {
                  printf FILE_SWISS_IDS "%-15s %-6s %-9s_%-1s %5d \n", $swiss_id_here[$i], $pdb_id_here[$i], $file_in, $chain_in, ($#swiss_id_here);
               } else {
                  printf FILE_SWISS_IDS "%-15s %-6s %-9s_%-1s %5d \n", $swiss_id_here[$i], " - ", $file_in, $chain_in, ($#swiss_id_here);
               }
            }
         } 

#        ------------------------------
#        setting arrays to 0
#        ------------------------------
         $#swiss_id = 0; $#swiss_id_here = 0; $#swiss_id_excluded =0;
         $#pdb_id = 0; $#pdb_id_here = 0; 
      }
   }
   close(FILELIST); close(FILE_MISSING); close(FILE_SWISS_IDS); close(FILE_WRONG_CHAIN);

exit;


#==========================================================================
sub read_70alis {
    local ($file_in, $chain_in, $skip) = @_ ;
     local ($hssp_name, $file_out0, $file_out1, $file_tmp, $hssp_nochain);
     local ($fh_in, $fh_out0, $fh_out1, $fh_tmp, $tmpchain, $tmprest, $tmpseq);
     local ($len_max, $i, $ctskips, $ctfiles, $ctalis, $ctbef, $inter, $ctmp);
     local ($Lnalign);
     local (@ali_seq);

#--------------------------------------------------
#  reads and writes the sequence of HSSP + 70 alis
#--------------------------------------------------

   $hssp_name 	= $file_in; 
   $hssp_name	=~ s/\/data\/hssp\///; 
   $hssp_name	=~ s/\.hssp//;
   if ( ($chain_in =~ / /) || ($chain_in =~ /X/) ) {
      $file_out0	= "$hssp_name" . ".pir"; 
   } else { 
      $file_out0	= "$hssp_name" . "_$chain_in" . ".pir";
   }
   $file_out0	=~ s/\s//g;
   $file_out0 	=~ tr/[A-Z]/[a-z]/;
   $file_tmp	= "$hssp_name" . ".tmp";
   $hssp_nochain= "$hssp_name";
   $hssp_name	.= "_" . "$chain_in";

   print "--- read_70alis: $hssp_name , chain: -$chain_in- , skip: $skip \n";

#--------------------------------------------------
#  read in file
#--------------------------------------------------

   $fh_in = "FILEIN_LOC"; $fh_out0 = "FILEOUT0_LOC"; $fh_tmp = "FILETMP_LOC";

   open($fh_in,$file_in)  		|| warn "Can't open $file_in: $!\n";
   if ( $Lwrite_hssp eq "True" ) {
      open($fh_out0,"> $file_out0")  	|| warn "Can't open $file_out0: $!\n";
   }
   open($fh_tmp,"> $file_tmp")  	|| warn "Can't open $file_tmp: $!\n";

#----------------------------------------
#  skip first 70*skip alis
#----------------------------------------
   $ctskips	= 0; 
   while ( <$fh_in> ) {
      if ( /^## ALIGNMENTS/ ) { $ctskips ++; }
      last if ( $ctskips == $skip );
   }

#----------------------------------------
#  read the sequences
#----------------------------------------
   $ctbef = ($skip-1)*70 ; $len_max = 0;
   $seq0 = ""; 
   while ( <$fh_in> ) {
      if (! / SeqNo / ) { 
         last if ( /^## / ) ;
         $tmpchain = substr($_,13,1); 
         $tmprest = substr($_,53);

         if ( length($tmprest) > $len_max ) { 	# maximal number of alis
            $len_max = length($tmprest); 
         } 
						# if chain ok extract
         if ( ($tmpchain eq "$chain_in") || ($chain_in eq "X") ) {
            $tmpseq = substr($_,15,1); $tmpseq =~ tr/[a-z]/[A-Z]/;
            $seq0 .= $tmpseq;
#            print  "$tmpseq"; 
            print $fh_tmp "$tmprest";		# write rest into temporary file
         } else {
            $#seq0 = 0;
         }
      } 
   }
   close($fh_tmp);

#----------------------------------------
#  check chain identifier
#----------------------------------------
   if ( $Lwrite_hssp eq "True" ) {
      if ( length($seq0) < 10 ) {
         print FILE_WRONG_CHAIN "$hssp_name\n";
      }
   }

#----------------------------------------
#  write out guide (HSSP) sequence
#----------------------------------------
   if ( $Lwrite_hssp eq "True" ) {
      push(@swiss_id_here,$swiss_id[1]);
      push(@pdb_id_here,$pdb_id[1]);
      &write_pir("$hssp_name", "$seq0", "$fh_out0", "$seq_char_per_line"); 
      close($fh_out0);
   }

#--------------------------------------------------
#  now extract sequences from alis
#--------------------------------------------------

   open($fh_tmp,"$file_tmp")  || warn "Can't open $file_tmp: $!\n";
   while ( <$fh_tmp> ) {
      for ( $i=1; $i < $len_max; $i++ ) {
         $ali_seq[$i] .= substr($_,$i,1);
      }
   }
   close($fh_tmp);
   system("rm -f $file_tmp");

   print "--- $len_max alis for file: $hssp_name \n";
   $ctalis = ($ctbef + 1);
   for ( $i=1; $i < $len_max; $i++ ) {
      ++$ctalis;
      $ali_seq[$i]	=~ s/[^A-Z]//g; $ali_seq[$i]	=~ tr/[a-z]/[A-Z]/;

      if ( length($ali_seq[$i]) >= 10 ) {
         push(@swiss_id_here,$swiss_id[$ctalis]);
         push(@pdb_id_here,$pdb_id[$ctalis]);
#        ------------------------------
#        write into file
#        ------------------------------
         $fh_out1 	= "FILEOUT" . "$i" . "_LOC";
         $ctfiles	= ($i + $ctbef); 
         if ( ($chain_in =~ / / )||($chain_in =~ /X/ )) {
            $file_out1	= "$hssp_nochain" . "_$ctfiles" . ".pir";
         } else {
            $file_out1	= "$hssp_nochain" . "_$chain_in" . "_$ctfiles" . ".pir";
         }
         $file_out1	=~ s/\s//g;
#         $file_out1	=~ tr/[a-z]/[A-Z]/;
         print "$file_out1, ";
         $file_out1 	=~ tr/[A-Z]/[a-z]/;
         &open_file("$fh_out1", ">$file_out1");
         &write_pir("$swiss_id[$ctalis] identical to: $file_in", "$ali_seq[$i]", "$fh_out1", "$seq_char_per_line");
         close($fh_out1); 
      } else { 
         push(@swiss_id_excluded,$swiss_id[$ctalis]);
      }
   }
   print "\n"; 
   close($fh_in); 
}

#==========================================================================
sub read_swissprot_id {
    local ($file_in) = @_ ;
     local ($fh_in, $ctmp, $notmp, $ctmpx, $swiss_idtmp, $pdb_idtmp, $Lprint);

#--------------------------------------------------
#  reads and writes the sequence of HSSP + 70 alis
#--------------------------------------------------

   $fh_in = "FILEIN_LOC"; 
   open($fh_in,$file_in)  		|| warn "Can't open $file_in: $!\n";

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
#  get number of alignments
#------------------------------
   while ( <$fh_in> ) {
      if (! /^  NR/ ) {
         $swiss_idtmp = substr($_,8,12);
         $swiss_idtmp =~ s/\s//g;
         $pdb_idtmp = substr($_,21,4);
         $pdb_idtmp =~ s/\s//g;
         if ( length($pdb_idtmp) == 0 ) { $pdb_idtmp = "NPDB"; }
         push(@swiss_id,$swiss_idtmp);
         push(@pdb_id,$pdb_idtmp);
      }
      last if ( /## ALIGNMENTS/ );
   }
   close($fh_in);

   $Lprint = "False";
#   $Lprint = "True";
   if ($Lprint eq "True") {
      printf "%-20s %-6s %-10s \n", "swiss_id", "pdb_id", "HSSP file";
      for ( $i=1; $i < $#swiss_id ;$i ++ ) {
          printf "%-20s %-6s %-10s \n", $swiss_id[$i], $pdb_id[$i], $file_in;
      }
   }
}
