#-------------------------------------------
# NLProt 2.0 command-line version (LINUX)
#-------------------------------------------

#---------------------  
 Files
#---------------------  

Files contained in the NLProt-package:

executables
- nlprot
- install
- svm
- bl

SVM files
- svm_model_1_j10.txt
- svm_model_2_j10.txt
- svm_model_5_j10.txt
- svm_model_3_j1.txt
- word_frequencies_names.txt
- word_frequencies_overlap.txt
- word_frequencies.txt

dictionary files
- dictionary.txt
- protein_dictionary.txt
- common_words_not_in_sp_or_tr.txt
- chemical_compounds_endings.txt
- in_ending_negatives.txt
- minerals.txt
- species.txt
- tissue.txt

other
- trembl_species_links.txt

service
- README.txt


#---------------------
 System Requirements
#---------------------  




#---------------------  
 Installation
#---------------------  

1) create a directory (e.g. /home/test/nlprot/) on your local machine

2) download a compressed NLProt_LINUX-file from our server (.tar.gz or .zip) into this directory

3) change to the new directory
$ cd /home/test/nlprot/

4) Decompress the downloaded archive
$ unzip NLProt_LINUX.zip
OR
$ gunzip NLProt_LINUX.tar.gz
$ tar -xf NLProt_LINUX.tar

5) Run the installation program
$ ./install

install will set up your local copy of NLProt and then ask you to install the name-databases on your machine.
You need these databases to assign UniProt IDs to all the found names. If you do not need this feature, you can skip this process.
It can take up to 20min on a 2.5GHz machine to finish this step but it is only necessary once.


#---------------------  
 Running NLProt
#---------------------  

To use NLProt just run the executable 'nlprot':
Type "./nlprot" on the command line and give some necessary options.

Options are submitted to the program as it is shown in the following example:
./nlprot -i /home/test/test_input.txt -o /home/test/test_output.txt


Options:
--------

-i  the input file (input-format: see -n)
    This is a mandatory option for the program!

    input format:
    plain natural language text (each line = one abstract/paper)
		lines have to start with number followed by ">" and then the text
		e.g. 0001>abstract1 abstract1 abstract1 ...
			 0002>abstract2 abstract2 abstract2 ...
			 0003>abstract3 abstract3 abstract3 ...
			 etc
			 .
			 .
			 .

-o  the output file (output-format: see -f)
    This is a mandatory option for the program!

-f  output format:
    html (default) = html formatted output (font color = red for protein names)
	txt = plain text (tags <n> and </n> for protein names)

-d  sequence database:
    sptr = show both, SWISS-PROT and TrEMBL IDs (default)
	sp = show only SWISS-PROT IDs
	sp = show only TrEMBL IDs

-s  on = only provide one database ID for each found name. NLProt will scan the surrounding text for organism names and
         assign the most likely ID to each protein name. (default)
    off = provide all possible IDs (organism unspecific)

-a  on = create a fasta file ([output file-name].fasta) with all sequences for the provided database IDs
    off = do not create fasta output (default)

#---------------------  
 Temporary Files
#---------------------  

NLProt generates a working directory ('tmp') to dump certain temporary files.
All temporary files will be deleted after NLProt finishes.


#---------------------  
 Deinstallation
#---------------------  

Delete all contents of the NLProt directory.
Since no files are being copied to other directories by the install.pl script, this should be
sufficient to remove the program completely from your machine.

