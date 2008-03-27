#!/usr/sbin/perl -w
# filter_sw.perl
#
# Filter sw entries for some properties:
# location (as given)
# no presence of 3D structure
# eukaryota
# no transmembrane
# dna-binding
#
# Usage: filter_sw.perl [-loc location] [-list list] [-3D] [-taxa taxa] [-tmb] [-gly] [-dna]
#
# e.g.: filter_sw.perl -loc EXTRACELLULAR -list my_list -3D -taxa EUKA -tmb -gly -dna -rna
#
# Miguel A. Andrade December 1996
# March 1997. Alternative use of a list of sw identifiers.
#
##############################################################


# constants
$EBI_SW_PATH = "/data/research/swissprot/current/";
$EMBL_SW_PATH = "/data/swissprot/current/";
$SWDIR = $EMBL_SW_PATH;


# read command line parameters
if ($#ARGV < 0){
    # print help text
    print "\n";
    print "Usage: filter_sw.perl -loc EXTRACELLULAR -list my_list -3D -taxa EUKA -tmb -gly -dna -rna\n";
    die "\n";
}

$location = '';
$sw_list = '';
$taxa = '';

$chk_tmb = 0;
$chk_dna = 0;
$chk_gly = 0;
$chk_3D = 0;

for ($i = 0; $i <= $#ARGV; $i++) {
    if ($ARGV[$i] eq '-loc') {
        $location = $ARGV[$i+1];
        $i++;
    }
    if ($ARGV[$i] eq '-list') {
        $sw_list = $ARGV[$i+1];
        $i++;
    }
    if ($ARGV[$i] eq '-taxa') {
        $taxa = $ARGV[$i+1];
        $i++;
    }
    if ($ARGV[$i] eq '-tmb') {
        $chk_tmb = 1;
    }
    if ($ARGV[$i] eq '-dna') {
        $chk_dna = 1;
    }
    if ($ARGV[$i] eq '-rna') {
        $chk_rna = 1;
    }
    if ($ARGV[$i] eq '-gly') {
        $chk_gly = 1;
    }
    if ($ARGV[$i] eq '-3D') {
        $chk_3D = 1;
    }
}


if ($sw_list eq '') {
    # no list. Make a list with the whole SwissProt

    opendir(SWD, $SWDIR);
    @dir_list = grep(/\w/, readdir(SWD));
    closedir(SWD);

    $counter = 0;

    foreach $directory(@dir_list) {
        opendir(SUB, $SWDIR.$directory);
        @file_list = grep(/\_/, readdir(SUB));
        closedir(SUB);
    }
    @file_list .= @file_sublist;
} else {
    # take list from the file

    @file_list = `cat $sw_list`;
}


# check each name on the list

foreach $name(@file_list) {

    $sw_id = $name;
    $sw_id =~ tr/A-Z/a-z/;
    ($name, $species) = split(/_/, $sw_id);
    $initial = substr($species, 0, 1);

    $full_path = $SWDIR."$initial/";
        
    @entry = `cat $full_path$sw_id`;
        
    if ($location ne '') {
        @cc = grep(/^CC/, @entry);
    }

    if ($taxa ne '') {
        @oc = grep(/^OC/, @entry);
    }

    if ($chk_3D) {
        @dr = grep(/^DR/, @entry);
    }

    if ($chk_dna || $chk_rna || $chk_gly || $chk_tmb) {
        @kw = grep(/^KW/, @entry);
    }

    # select by location

    $loc = 1;
    if ($location ne '') {
        # check location
        
        $loc = 0;
        foreach $line(@cc) {
            if (($line =~ /SUBCELLULAR LOCATION/) && ($line =~ /$location/)) {
                $loc = 1;
            }
        }
    }

    if ($loc) {
    
        # if the location is found then try to found the taxa

        $tax = 1;
        if ($taxa ne '') {
        
            # check taxa
            $tax = 0;
            
            foreach $line(@oc) {
                if ($line =~ /$taxa/) {
                    $tax = 1;
                }
            }
        }

        if ($tax) {
            # if the taxa is found then proceed with other checks
    

            chop($sw_id);
            print "$sw_id";


            if ($chk_tmb) {
            
                # check transmembrane
                $tmb = 0;
                foreach $line(@kw) {
                    if ($line =~ /TRANSMEMBRANE/) {
                        $tmb = 1;
                    }
                }
                if ($tmb) {
                    print "\ttmb";
                } else {
                    print "\tnon-tmb";
                }
            }

            if ($chk_3D) {
                
                # check 3D
                $pdb = 0;
                foreach $line(@dr) {
                    if ($line =~ /PDB/) {
                        # it has a PDB entry
                        $pdb = 1;
                    }
                }
                if ($pdb) {
                    print "\t3D";
                } else {
                    print "\tno-3D";
                }
            }
            
            if ($chk_gly) {
                
                # check glycosilation
                @kw = grep(/^KW/, @entry);
                $gly = 0;
                foreach $line(@kw) {
                    if ($line =~ /GLYCOPROTEIN/) {
                        # it is glycosilated
                        $gly = 1;
                    }
                }
                if ($gly) {
                    print "\tgly";
                } else {
                    print "\tnon-gly";
                }
            }
            
            if ($chk_dna) {
                
                # check dna-binding
                $dna = 0;
                foreach $line(@kw) {
                    if ($line =~ /DNA-BINDING/) {
                        $dna = 1;
                    }
                }
                if ($dna) {
                    print "\tdna";
                } else {
                    print "\tnon-dna";
                }
            }
            
            if ($chk_rna) {
                
                # check rna-binding
                $rna = 0;
                foreach $line(@kw) {
                    if ($line =~ /RNA-BINDING/) {
                        $rna = 1;
                    }
                }
                if ($rna) {
                    print "\trna";
                } else {
                    print "\tnon-rna";
                }
            }
            

            print "\n";

        } # end if $tax
    } # end if $loc
}


# end
