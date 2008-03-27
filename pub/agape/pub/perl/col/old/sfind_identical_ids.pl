#!/usr/sbin/perl 
#----------------------------------------------------------------------
# sfind_identical_ids
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"sfind_identical_ids.pl list-hssp-files
#
# task:		finding pairs of identical swissprot identifiers
# 		in a list extracted from HSSP files (myhssp_to_pir.pl)
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

$script_name = "sfind_identical_ids.pl";
$script_input= "list_of_hssp_files";

push (@INC, "/zinc2/rost/perl") ;
require "ctime.pl";
require "rs_ut.pl" ;
require "ut.pl";
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
   &myprt_line; &myprt_txt("perl script to find identical swissprot identifiers");
   &myprt_empty; &myprt_txt("usage: \t $script_name $script_input"); &myprt_empty;

#----------------------------------------
#  read input
#----------------------------------------

   				&myprt_empty;
   $file_list	= $ARGV[1]; 	&myprt_txt("list here:      \t \t \t $file_list"); 

#------------------------------
# defaults
#------------------------------

   $file_identical= "$file_list" . ".identical";
				&myprt_txt("identical swissprot ids in: \t $file_identical");

#------------------------------
#  check existence of file
#------------------------------
   if ( ! -e $file_list ) {
      &myprt_empty; &myprt_txt("ERROR: \t file $file_list does not exist"); exit;
   }

#----------------------------------------
# read list
#----------------------------------------

   $fh_identical	= "FILE_IDENTICAL";
   &open_file("$fh_identical", ">$file_identical");
   &open_file("FILELIST", "$file_list");

   printf $fh_identical " %-12s %-11s %-4s %-12s %-11s \n ", "swiss_id1", "hssp1", " : ", "swiss_id2", "hssp2";

   while ( <FILELIST> ) { last if ( /^swiss_id/ ); }

   while ( <FILELIST> ) {
      ($id_search,$pdb_search,$hssp_search,$rest)=split(' ',$_,4);
      $hssp_search 	=~ s/\s//g;
      $id_search 	=~ s/\s//g;
      print "searching for: $id_search $hssp_search \n";
      &find_identical_1_against_all($file_list,$id_search,$hssp_search,$fh_identical);
   }
   close(FILELIST); close(fh_identical);

exit;


#==========================================================================
sub find_identical_1_against_all {
    local ($file_in,$id_in,$hssp_in, $file_handle) = @_ ;
    local ($id_tmp,$hssp_tmp,$rest,$pdb_tmp);
    local ($hssp_found,$id_found);

#--------------------------------------------------
#  searches the whole file against the input
#--------------------------------------------------

   &open_file("FILEIN", "$file_in");

   while ( <FILEIN> ) {
      if (! /$hssp_in/) {
         if ( /$id_in/ ) { 
            ($id_tmp,$pdb_tmp,$hssp_tmp,$rest)=split(' ',$_,4);
#           ------------------------------
#           don't do twice
#           ------------------------------
            if ( $hssp_in lt $hssp_tmp ) {
               $hssp_in =~ s/\s//g;
               $id_found   =  $id_tmp;
               $id_found   =~ s/\s//g;
               $hssp_found =  $hssp_tmp;
               $hssp_found =~ s/\s//g;
               printf $file_handle "%-12s %-11s %-4s %-12s %-11s \n ", $id_in, $hssp_in, " : ",$id_found, $hssp_found;
            }
         }
      }
   }

   close(FILEIN);

}