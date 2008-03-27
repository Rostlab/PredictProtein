#! bin/env pPATHrl
#  this file contains the paths to different modules for GeneQuiz2
#
#======================================================================

#-------------------------------------path to :
$GQ_HOME_PATH = $ENV{'GQ_HOME_PATH'};
$BIN_PATH   = "$GQ_HOME_PATH/bin/SGI";    #  path to  molbio programs
$MOLBIO_PATH= "$GQ_HOME_PATH/MOLBIO"; # path to  molbio data
$RDB_PATH   = "$GQ_HOME_PATH/RDB";    #  rdb scripts
$GQF_PATH   = "$GQ_HOME_PATH/GQ";     #  modules for features and summary 
$DOONE_PATH = "$GQ_HOME_PATH/DOONE";  #  scripts used by do_one
$PARSER_PATH= "$GQ_HOME_PATH/PARSER"; #  parsers to rdb for varius methods 
$PERL_PATH  = "$GQ_HOME_PATH/bin/SGI";    #  perl executable
$PERL_TOOLS  = "$GQ_HOME_PATH/PERL";  #  perl subroutines
#-------------------------------------
# architecture and other pathes 
#-------------------------------------
$ENV{'MAXHOM_DEFAULT'} = "/home/schneide/public/maxhom.default" ;
$ARCH   	 = $ENV{'ARCH'} ;
$PATH            = $ENV{'PATH'} ;

if (index($path,$BIN_PATH) <= 0) {
   $PATH           .= ":" .  $BIN_PATH;
}
#if (index($path, "$GQ_HOME_PATH/$ARCH") <= 0) {
#   $PATH           .= ":" . "/$ARCH" ;
#}

$ENV{'PATH'}     = "$PATH" ; 
$ENV{'FASTLIBS'} = "$GQ_HOME_PATH/fastgbs" ;
$ENV{'LIBTYPE'}  = "0" ;
$ENV{'BLASTMAT'} = "$MOLBIO_PATH/blast/matrix" ;
$ENV{'BLASTDB'}  = "/research/sander1/db/" ;
$ENV{'MAXHOM_DEFAULT'}  = "$MOLBIO_PATH/maxhom/maxhom.default" ;

$SWISS_PATH = "/research/sander7/swissprot/current/";
#$DSSP_PATH = "/data/dssp/" ;
$PDB_PATH = "/research/sander8/pdb/" ;
#$PHD_PATH = "/home/rost/pub" ;


