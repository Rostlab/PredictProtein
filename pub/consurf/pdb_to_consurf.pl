#!/usr/local/bin/perl


#*** Modules ***#
use lib '/data/users/consurf/WebConsurf/modules';  
#use lib '/data/users/consurf/DEV_WebConsurf/modules';  # only when working on a module!
use PDB;
use strict;

#****************************************
#command line arg
my $NamePref = $ARGV[0];  # The prefix of the file
my $Prog = $ARGV[1]; # the calc program: 'consurf' or 'rate4s'
my $mode = $ARGV[2]; # 'msa' or 'fasta'
my $OutLogFile = $ARGV[3];
my $run_name = $ARGV[4];
my $SeqName = $ARGV[5]; # in case of 'msa'

# files names
my $aln_file = ($mode eq "fasta" ? $NamePref."_PDB_SEQRES.aln" : $NamePref."_PDB_MSA.aln");
my $pdbdata = $NamePref . ".pdbdata";
my $prog_out = ($Prog eq "consurf" ? $NamePref.".grades" : "r4s.res");
my $final_out = $NamePref . ".gradesPE";
my $pdb_file = $NamePref . ".ent";
my $msa = $NamePref . ".aln";
my $fasta_seq = $NamePref . ".seq";

# output file definitions
my $OutHtmlFile = "output.html";
my $ErrorDef = "<font size=+3 color='red'>ERROR!  ConSurf session has been terminated: </font>";
my $SysErrorDef = "<p><font size=+3 color='red'>SYSTEM ERROR - ConSurf session has been terminated!</font><br><b>Please wait for a while and try to run ConSurf again</b></p>\n";
my $mail = "\"mailto:yossir\@ashtoret.tau.ac.il?subject=Run No: $run_name\"";
my $ContactDef = "\n<H3><center>For assistance please <a href=$mail>contact us</a></H3>\n";


#******************************
#variables

my @Output = ();  # To hold all the information that should be printed in the output file
                  # (SEQRES, ATOM, grade, 3LATOM, color, reliability) 

my @PdbSeq = (); #to hold the PDB aligned to SEQRES (without the gaps in the seqres, if any)
my @SeqPdb = (); # to hold the SEQRES aligned to the PDB
my @PDB = ();    #to hold the PDB AND numbers ready to PE
my @gradesPE_data = (); #To hold data of updated gradesPE
my $ConsColorUnity; #unity of conservation to be colored
my $MaxCons;        #MaxCons Value
my @ColorLayers;    #color limit values between the layers

my @colorstep; #color steps
$colorstep[8] = "[16,200,209]";    #less conserved
$colorstep[7] = "[140,255,255]";
$colorstep[6] = "[215,255,255]";
$colorstep[5] = "[234,255,255]";
$colorstep[4] = "[255,255,255]";
$colorstep[3] = "[252,237,244]";
$colorstep[2] = "[250,201,222]";
$colorstep[1] = "[240,125,171]";
$colorstep[0] = "[160,37,96]";      #most conserved

#$colorstep[8] = "[16,200,209]";    #less conserved
#$colorstep[7] = "[76,214,221]";
#$colorstep[6] = "[136,228,232]";
#$colorstep[5] = "[195,241,244]";
#$colorstep[4] = "[255,255,255]";
#$colorstep[3] = "[231,201,215]";
#$colorstep[2] = "[208,146,176]";
#$colorstep[1] = "[184,92,136]";
#$colorstep[0] = "[160,37,96]";      #most conserved

my %ColorScale = (0 => 9,
		  1 => 8,
		  2 => 7,
		  3 => 6,
		  4 => 5,
		  5 => 4,
		  6 => 3,
		  7 => 2,
		  8 => 1);  

open LOG, ">>$OutLogFile";
print LOG "\npdb_to_consurf.pl:\nNamePref = $NamePref, Program = $Prog, mode = $mode, Log = $OutLogFile, run_name = $run_name, SeqName(if MSA) = $SeqName\n";
close LOG;
print "NamePref = $NamePref, Program = $Prog, mode = $mode, Log = $OutLogFile, run_name = $run_name, SeqName(if MSA) = $SeqName\n";


### read the pairwise alignment
&Read_aln_file;

### read the pdbdata file that contains the ATOM sequence in 3 letter code, the residue number
### and the chain (for example: ARG34:A) 
&Read_pdb_data;

### read the scores file (the output of rate4site or consurf.pl)
&Read_grades;  

#calculate color unit layer thickness and max cons value
($MaxCons, $ConsColorUnity) = &Calc_layer_unit;

# calculate 1-9 color grades
@ColorLayers = &calc_color_layers ($MaxCons, $ConsColorUnity);

# set the color grade for each residue based on the conservation score
&Set_colors_pdb;

#calculate the number of informative sequences in each position (MSA DATA)
&calc_reliability;

#calc alternative amino-acids (RESIDUE VARIETY)
&calc_residue_range; 

#print output file for PE protein coloring
&Print_consurf_spt;

#print file for PE sequence coloring (ConSurf Seq3D)
&Print_consurf_js;

#print the 'amino acid conservation scores' file
&Print_PE;

#Insert the grades into the tempFactor column of the PDB file
# (not in use right now because for some reason it doesn't work with grasp)
&insert_grades;



#*** SUBROUTINES ****************************
#####################################
####################################

############################################################################
# Read the PDB-SEQRES (or PDB-MSA) alignment into two arrays
sub Read_aln_file {

    unless (open ALN2, "<$aln_file"){ #from SEQRES-PDB clustalw alignment
        
	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl\nRead_aln_file: Can\'t open the file $aln_file\n";
        close LOG;

	print "Can\'t open the file $aln_file\n";

	open ERROR, ">error";
	close ERROR;
        exit;
    } 
    
    my $pdbseq; #to hold the ATOM sequence
    my $seqpdb; #to hold the SEQRES sequence

    while (<ALN2>) {
        
        if (/^PDB_\w*\s+(\S+)/) {

            $pdbseq .= $1;
        }
        elsif (/^SEQRES_\w*\s+(\S+)/){

            $seqpdb .= $1;
        }
	# in case of msa
	elsif (/^\Q$SeqName\E\s+(\S+)/){

	   $seqpdb .= $1; 
	}
    }
    close ALN2;

    my @PdbSeq_temp = split (//, $pdbseq); 
    @SeqPdb = split (//, $seqpdb);

    # copy @PdbSeq_temp to @PdbSeq, 
    # without the places in which there are gaps in the SEQRES (if any)
    # or 'X' (unknown) amino acids if it is an MSA 
    my $i = 0;
    foreach my $AA (@SeqPdb){

        if ($AA ne "-" and $AA ne "X"){
            
            push @PdbSeq, $PdbSeq_temp[$i];
        }
        $i++;
    }
}

################################################################################
#open and read file pdbdata into an array
sub Read_pdb_data {

    unless (open PDB, "<$pdbdata"){ #from SEQRES-PDB clustalw alignment 
    
	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:\nRead_pdb_data: Can\'t open the file $pdbdata\n";
        close LOG;

	print "Can\'t open the file $pdbdata\n";

	open ERROR, ">error";
	close ERROR;
        exit;
    }

    my @PDB_temp = <PDB>;
    chomp @PDB_temp;
    close PDB;

    # copy @PDB_temp to @PDB, 
    # without the places in which there are gaps in the SEQRES (if any)
    # or non-sandard amino acids if it is an MSA 
    my $i = 0;
    foreach my $AA (@SeqPdb){

        if ($AA ne "-"){
	    
	    $PDB_temp[$i] =~ s/\s*$//;  # to remove the spaces
            push @PDB, $PDB_temp[$i];
        }
        $i++;
    }
}

#########################################################################################
# Read the grades file and put all the information in @output in the correct alignment!
sub Read_grades {

    # check if $prog_out exists and if it contains any data
    my $alt_method = ($prog_out eq "r4s.res" ? "Maximum Parsimony" : "Maximum Likelihood");
    if (!-e $prog_out or -z $prog_out){

	open OUTPUT, ">>$OutHtmlFile";
        print OUTPUT "\n<p>$ErrorDef<br><b>An error has occured during the calculation. You can try to run ConSurf with the $alt_method method.</b></p>\n";
	print OUTPUT $ContactDef;
	close OUTPUT;

	open LOG, ">>$OutLogFile";
	print LOG "\npdb_to_consurf.pl:\nRead_grades: The file $prog_out does not exist or contains no data\n";
	close LOG;

	print "The file $prog_out does not exist or contains no data\n";

	open ERROR, ">error";
	close ERROR;
	exit;
    }

    # open the output file of 'consurf' or 'rate4s' for reading
    unless (open GRADES, "<$prog_out"){

	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:\nRead_grades: Can\'t open the file $prog_out\n";
        close LOG;

	print "Can\'t open the file $prog_out\n";

        open ERROR, ">error";
	close ERROR;
	exit;
    }

    # skip the title
    if ($Prog eq "consurf"){

	$_ = <GRADES>;
    }

    my $CountPdb = 0; # for the 3LATOM
    my $CountSeq = 0; # for the SEQ

    while (<GRADES>) {

        my $line = $_;
        chomp $line;

	if ($line =~ /^\s*(\d+)\s+(\S+)\s+(\S+)/){

	    my $AA = $2;
	    my $grade = $3;

	    # ignore lines with '*' - meaning gaps between the seqres and its homologues
	    if ($AA eq "*"){
		
		next;
	    }

	    $Output[$CountSeq]{SEQ} = $AA;
	    $Output[$CountSeq]{GRADE} = $grade;
	    $Output[$CountSeq]{ATOM} = $PdbSeq[$CountSeq];

	    if ($PdbSeq[$CountSeq] ne "-") {

		$Output[$CountSeq]{PE} = $PDB[$CountPdb];
		$CountPdb++;
	    }
	    else {
		
		$Output[$CountSeq]{PE} = "-";
	    }
        
	    $CountSeq++;

	}
    }

    close GRADES;

}


#########################################################################
# calc the thickness of the color layers and the most conserved value
sub Calc_layer_unit {

    my $element;
    my $max_cons = $Output[0]{GRADE};
    my $ConsColorUnity; #unity of conservation to be colored

    foreach $element (@Output){

	if ($$element{GRADE} < $max_cons) {

	    $max_cons = $$element{GRADE};
	}
    }

    $ConsColorUnity = $max_cons / 4.5 * -1; 

    return ($max_cons, $ConsColorUnity);
}

#################################################################
# calc the 1 - 9 color grades
sub calc_color_layers ($$) {

    my $MaxCons = $_[0];
    my $ConsColorUnity = $_[1];
    my $i;
    my $NoLayers = 9;
    my @ColorLayers;

    for ($i = 0; $i <= $NoLayers; $i++) {

	$ColorLayers[$i] = $MaxCons + ($i * $ConsColorUnity);
    }

    return @ColorLayers;

}

#############################################################
#Set the colors and the color grades for each AA
sub Set_colors_pdb {
    
    my $i;
    my $element;
    my $Count = 0;

    foreach $element (@Output) { 
       
        for ($i = 0; $i <= $#ColorLayers; $i++) {
            
            if ($$element{GRADE} >= $ColorLayers[$i] && $$element{GRADE} < $ColorLayers[$i + 1]) {
                
                $Output[$Count]{COLOR} = $colorstep[$i]; #color for chime
                $Output[$Count]{SEQ3DCOLOR} = $i;          #number of color for seq3d
                ($Output[$Count]{NUMBER}) = ($$element{PE}) =~ /(\d+)/; #res number
                
                $Count++;
                last;
            }
            elsif ($i == 9) {
                
                $Output[$Count]{COLOR} = $colorstep[8];
                $Output[$Count]{SEQ3DCOLOR} = 8;          #color for seq3d
                ($Output[$Count]{NUMBER}) = ($$element{PE}) =~ /(\d+)/;
               
                $Count++;

            }
        }
    }
}

##########################################################################
# Print consurf.spt file (RasMol coloring script) for PE
sub Print_consurf_spt {

    my $i;
    my $element;
    my $color;
    my $LineMaxElem = 10;  #No of elements on each consurf.spt line
    my $ElemCount = 0;
    my $separator;
     my $chain;
    unless (open SPT, ">consurf.spt"){

	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:\nPrint_consurf_spt: Can\'t open the file consurf.spt\n";
        close LOG;

	print "Can\'t open the file consurf.spt\n";

        open ERROR, ">error";
	close ERROR;
	exit;
    }
#============================ RasMol (CON) =============
      unless (open RSML, ">consurf.rsml"){

	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:\nPrint_consurf_rsml: Can\'t open the file consurf.rsml\n";
        close LOG;

	print "Can\'t open the file consurf.rsml\n";

        open ERROR, ">error";
	close ERROR;
	exit;
    }
    
#========================================================

    # to solve the problem when chime runs out of colors.
    print SPT "select all\n";
#============================ RasMol (CON) =============
    print RSML "select all\n";
#=======================================================

    print SPT "color [200,200,200]\n\n";
#============================ RasMol (CON) =============
    print RSML "color [200,200,200]\n\n";
#=======================================================



    my $file_count = 9;

    foreach $color (@colorstep) {
        
	my $color_elem_count = 0;

	open COLOR, ">./pdbspt/" . $file_count . ".spt";

        foreach $element (@Output) { 
     
            if ($$element{COLOR} eq $color and $$element{PE} ne "-" ) {

		if ($ElemCount == 0) {

	            print SPT "\nselect ";
		    print COLOR "\nselect ";
#============================ RasMol (CON) =============
                   print RSML "\nselect ";
#=======================================================
		}


                if ($ElemCount == 10) {
              #       $$element{PE} =~ s/(\:)([\d|\w])//;
               #     $chain=$2;
                    print SPT "\nselect selected or $$element{PE}";
		    print COLOR "\nselect selected or $$element{PE}";
#============================ RasMol (CON) =============
                    print RSML "\nselect selected or $$element{PE}";
#======================================================
                    $ElemCount = 0;
                }
                else {
 #                    $$element{PE} =~ s/(\:)([\d|\w])//;
 #                   $chain=$2;
                    print SPT "$separator $$element{PE}";
		    print COLOR "$separator $$element{PE}";
#============================ RasMol (CON) =============
		    print RSML "$separator $$element{PE}";
#======================================================
                    $separator = ",";
                }

                $ElemCount++;
		$color_elem_count++;
            }
        }

        if ($ElemCount > 0) {
           print SPT "\nselect selected and:$chain\n";
           print SPT "color $color\nspacefill\n";

#============================ RasMol (CON) =============
	   print RSML "\nselect selected and:$chain\n";
           print RSML "color $color\nspacefill\n";
           print RSML "\ndefine CON" . $file_count . " selected\n\n";
#=======================================================
	   print COLOR "\nspacefill\n";
	}

	if ($color_elem_count == 0){

	    print COLOR "javascript alert(\"No residues have this color\")";
	}

        $ElemCount = 0;
        $separator = " ";
	$file_count--;
	
	close COLOR;
    }

    close SPT;
    close RSML;
}

#################################################################################
# print consurf.js file for PE Seq3D
sub Print_consurf_js {

    my $i;
    my $element;
    my $Count = 0;

    my $total = scalar (@Output);

    unless (open JS, ">consurf.js"){

	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;
	
        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:\nPrint_consurf_js: Can\'t open the fileconsurf.js\n ";
        close LOG;

	print "Can\'t open the fileconsurf.js\n ";

	open ERROR, ">error";
	close ERROR;
	exit;
    }

    print (JS "var csc = new Array(", $total +1 , ");\n\n");
    print (JS "for (i = 0; i <= " ,$total  , "; i++)\n");
    print JS "\tcsc[i] = -1;\n\n";



    foreach $element (@Output) { 
        
        if ($$element{PE} ne "-" ) {
            
            print (JS "csc[" , $$element{NUMBER}, "] = ", $$element{SEQ3DCOLOR}, ";\n");       
        }
    }
}

############################################################################
# Print the 'amino acid conservation scores' file
sub Print_PE {

    # open the final output file for writing
    unless (open PE, ">$final_out"){

	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:\nUpdate_grades_to_PE: Can\'t open the file $final_out\n";
        close LOG;

	print "Can\'t open the file $final_out\n";

        open ERROR, ">error";
	close ERROR;
	exit;
    }

    print PE "\t Amino Acid Conservation Scores\n";
    print PE "\t===============================\n\n";
    print PE "- POS: The position of the AA in the SEQRES derived sequence.\n";
    print PE "- SEQ: The SEQRES derived sequence in one letter code.\n";
    print PE "- SCORE: The normalized conservation scores.\n";
    print PE "- 3LATOM: The ATOM derived sequence in three letter code, including the AA's positions as they appear in the PDB file and the chain identifier.\n";
    print PE "- COLOR: The color scale representing the conservation scores (9 - conserved, 1 - variable).\n";
    print PE "- MSA DATA: The number of aligned sequences having an amino acid (non-gapped) from the overall number of sequences at each position.\n";
    print PE "- RESIDUE VARIETY: The residues variety at each position of the multiple sequence alignment.\n\n";
    print PE " POS\t SEQ\t    3LATOM\t SCORE\tCOLOR\tMSA DATA\tRESIDUE VARIETY\n";

    my $pos = 1;
    foreach my $elem (@Output){

	printf (PE "%4d", "$pos");
	printf (PE "\t%4s", "$$elem{SEQ}");
	printf (PE "\t%10s", "$$elem{PE}");
	printf (PE "\t%6.3f", "$$elem{GRADE}");
	printf (PE "\t%5d", "$ColorScale{$$elem{SEQ3DCOLOR}}");
	printf (PE "\t%8s", "$$elem{reliability}");
	printf (PE "\t%-s\n", "$$elem{res_range}"); # to align left

	$pos++;
    }

    close PE;
}

###########################################################################
# Insert the scores into the Tempfactor column in the PDB file
sub insert_grades{

    my %grades = ();
    my $pe;
    my $chain;
    my $resnum;
    my $grade;

    # read the 3LATOM and GRADE fields from the output file
    open PE, "<$final_out";
    while (<PE>){

	if ($_ =~ /\s*\d+\s+\w+\s+(\S+)\s+(\S+)\s+\d+/){

	    $pe = $1;
	    $grade = $2;

	    # ignore gaps in the ATOM sequence
	    unless ($pe eq "-"){

		$pe =~ /\w\w\w(\S+):(\w)?/;
		$resnum = $1;
		$chain = $2;

		if ($chain eq ""){
		    
		    $chain = " ";
		}

		unless ($grade =~ /^-/){

		    # add a space so that the grades will be indented to the right
		    $grade = " " . $grade;
		}

		$grades{$resnum} = $grade;
	    }
	}
    }
    close PE;
    
    # call the function insert_Tempfactor to insert the grades to the PDB file
    &PDB::insert_tempFactor($pdb_file, $chain, \%grades);
}

#######################################################################
# calc the number of informative data per each position
sub calc_reliability{

    my @aln = ();

    &read_aln(\@aln); 
    
    # extract the target sequence name from the ".seq" file
    if ($mode eq "fasta"){

	open SEQ, "<$fasta_seq";
	while (<SEQ>){

	    if ($_ =~ />(\S+)\s+/){

		$SeqName = $1;
	    }
	}
	close SEQ;
    }
    
    # loop over the positions
    my $CountPos = 0;
    foreach my $pos (@aln){

	# calculate the reliability only for positions in which the target sequence is not "-" or "X"
	if ($$pos{$SeqName} ne "-" and $$pos{$SeqName} ne "X"){

	    my $total = 0;
	    my $inf = 0;
	    # loop over the different values
	    foreach my $aa (values %{$pos}){

		unless ($aa eq "-"){
		    
		    $inf++;
		}
		$total++;
	    }
	    
	    # insert the reliability field to the general array
	    my $result = $inf . "/" . $total;
	    $Output[$CountPos]{reliability} = $result;
	    $CountPos++;
	}
    }
}

#####################################################################
# read the aln file into an array of hashes
# (for each position there is a hash, where the keys are the sequences names
# and the values are the residues)
#####################################################################
sub read_aln {

    my $aln = shift;

    # read the MSA file into array of hashes
    unless (open MSA, "<$msa"){

	open OUTPUT, ">>$OutHtmlFile";
	print OUTPUT $SysErrorDef;
	print OUTPUT $ContactDef;
	close OUTPUT;

        open LOG, ">>$OutLogFile";
        print LOG "\npdb_to_consurf.pl:calc_reliability\n: Can\'t open the file $msa\n";
        close LOG;

	print "Can\'t open the file $msa\n";

        open ERROR, ">error";
	close ERROR;
	exit;
    }
    my $PosCount = 0;
    my $first_name = "";
    my $i;
    while (<MSA>){

	if ($_ =~ /^CLUSTAL/){

	    next;
	}

	elsif ($_ =~ /^(\S+)\s+(\S+)\s*/){

	    my $name = $1;
	    my $seq = $2;
	    my @seqs = split '', $seq;

	    # to set the first name
	    if ($first_name eq ""){

		$first_name = $name;
	    }
	    # a new block
	    elsif ($name eq $first_name){

		$PosCount = $i; 
	    }
	    

	    $i = $PosCount;
	    foreach my $cell (@seqs){

		$$aln[$i]{$name} = $cell;
		$i++;
	    }
	}
    }
    close MSA;
}

#####################################################################
# calc the residues variety per each position
sub calc_residue_range {

    my @aln = ();
    
    &read_aln(\@aln); 

     # extract the target sequence name from the ".seq" file
    if ($mode eq "fasta"){

	open SEQ, "<$fasta_seq";
	while (<SEQ>){

	    if ($_ =~ />(\S+)\s+/){

		$SeqName = $1;
	    }
	}
	close SEQ;
    }
    
    # loop over the positions
    my $CountPos = 0;
    foreach my $pos (@aln){

	# find the residues range only for positions in which the target sequence is not "-" or "X"
	if ($$pos{$SeqName} ne "-" and $$pos{$SeqName} ne "X"){

	    # sort the residues in alphabeical order
	    my @sorted = ();
	    push @sorted, (sort { $a cmp $b } values %{$pos});

	    $Output[$CountPos]{res_range} = "";

	    # loop over the different values
	    foreach my $aa (@sorted){

		# write the AA if it's not a gap and it hasn't appeared yet
		if ($aa ne "-" and $Output[$CountPos]{res_range} !~ /$aa/){

		    $Output[$CountPos]{res_range} .= "$aa,";
		}
	    }
	    
	    # delete the last comma
	    chop $Output[$CountPos]{res_range};
	    
	    $CountPos++;
	}
    }
}



