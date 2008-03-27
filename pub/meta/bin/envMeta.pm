#===============================================================================
sub iniEnv {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniEnv                      set global parameters for PPmeta
#       out GLOBAL:             all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="iniEnv";
				# ------------------------------
				# avoid warnings
    $#services=  0;
    $exe_tmpname="";
				# ------------------------------
				# directories (end with '/')
				# scripts (machine independent)
    $DIR_meta_scr=  "";
				# binaries (machine dependent)
    $DIR_meta_bin=  "/home/meta/server/bin/";
    $DIR_meta_bin=  "";
				# all working files will go here
    $DIR_meta_work= "";

				# ------------------------------
				# 
    %par=
	(
				# program to sned mail
	 'exe_mail',         "/usr/sbin/Mail",
				# sendmail for the massaged backup mail messages
	 'exe_sendmail',     "/usr/lib/sendmail",
				# -i: ignores dots on a line by themselves
	 'opt_sendmail',     "-i",
				# program generating temporary filenames
	 'exe_tmpname',      $DIR_meta_bin."tmpnam.SGI64",

				# libraries
	 'lib_meta',         $DIR_meta_scr."lib-meta.pm",
	 'lib_services',     $DIR_meta_scr."lib-meta-services.pm",
	 'lib_sequence',     $DIR_meta_scr."lib-meta-sequence.pm",
	 );

				# ------------------------------
				# check correctness of settings
    $#kwdLib=0;
    foreach $kwd (keys %par) {
	next if (! defined $kwd || length($kwd)<1);
	next if ($kwd !~/^(file|exe|lib)/);
	push(@kwdLib,$kwd)          if ($kwd=~ /^lib/);
	if    ($kwd =~ /^exe/ && ! -x $par{$kwd}) {
	    $msg="*** ERROR during ini of $0: executable $kwd (".$par{$kwd}.") missing";
	    &msglog($msg);
	    &abort("$msg"); }
	elsif ($kwd =~ /^lib/ && ! -l $par{$kwd} && ! -e $par{$kwd}) {
	    $msg="*** ERROR during ini of $0: library $kwd (".$par{$kwd}.") missing";
	    &msglog($msg);
	    &abort("$msg"); } }
				# ------------------------------
				# require libs
    foreach $kwd (@kwdLib) {
	next if (! defined $kwd || length($kwd)<1);
	$Lok=
	    require $par{$kwd};
	next if ($Lok);
				# error
	$msg="*** ERROR during ini of $0: require $kwd (".$par{$kwd}.") failed";
	&msglog($msg);
	die ("$msg"); }
    
				# ------------------------------
				# shortcuts
    $exe_tmpname=$par{"exe_tmpname"};

				# ------------------------------
				# list of services
    @services=
	(
				# 3D structure
	 'swissmodel',		# SWISS-MODEL, Nicolas Guex, Geneva, REMARK: missing 

				# threading
#	 'genthreader',		# David Jones, REMARK: do NOT activate before his ok
#	 'pssm',		# Sternberg group, REMARK: do NOT activate before their ok
	 'frsvr',		# Daniel Fischer, REMARK: missing
	 'pscan',		# Arne Elofsson, REMARK: missing

				# alignment
#	 'blocks',		# Shmuel Pietrokovski (LAMA server), REMARK: not yet

				# 1D structure
	 'jpred',		# secondary structure prediction, EBI Hinxton
#	 'psipred',		# sec str, David Jones, REMARK: do NOT activate before his ok

				# membrane
	 'tmhmm',		# Hidden Markov Model, Anders Krogh, Copenhagen
#	 'memsat',		# David Jones, REMARK: do NOT activate before his ok (or never)
	 'das',			# Arne Elofsson, REMARK: missing
	 'toppred',		# Gunnar von Heijne, REMARK: missing

				# alignment

				# various
	 'netoglyc',		# glycosilation sites, CBS Copenhagen
	 'chlorop',		# chloroplast transit peptides, CBS Copenhagen
	 'signalp',		# signal peptides, CBS Copenhagen
	 );

    %services=
	(
	 'cgi_generic',       "http://",
	 'url_generic',       "http://",
	 'admin_generic',     "email,name of administrator",
	 'quote_generic',     "literature to quote for service", 
				# 
	 'cgi_basic',         "http://cape6.scripps.edu/leszek/genome/cgi-bin/comp.pl",
	 'url_basic',         "http://cape6.scripps.edu/leszek/genome/",
	 'admin_basic',       "",
	 'quote_basic',       "",
				# 
	 'cgi_chlorop',       "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_chlorop',       "http://www.cbs.dtu.dk/services/ChloroP/",
	 'admin_chlorop',     "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'quote_chlorop',     "O Emanuelsson, H Nielsen and G von Heijne:".
                              "ChloroP, a neural network-based method for ".
                              "predicting chloroplast transit peptides and ".
                              "their cleavage sites. ".
                              "Protein Science, in press, 1999",
				# 
	 'cgi_das',           "http://www.biokemi.su.se/~server/DAS/tmdas.cgi",
	 'url_das',           "http://www.biokemi.su.se/~server/DAS/",
	 'admin_das',         "Miklos Cserzo,miklos\@pugh.bip.bham.ac.uk",
	 'quote_das',         "M Cserzo, E Wallin, I Simon, G von Heijne and A Elofsson: ".
                              "Prediction of transmembrane alpha-helices in procariotic ".
                              "membrane proteins: the Dense Alignment Surface method. ". 
                              "Protein Engineering, 10, 673-676, 1997",
				# 
	 'cgi_frsvr',         "http://www.doe-mbi.ucla.edu/cgi-bin/fischer.pl",
	 'url_frsvr',         "http://www.doe-mbi.ucla.edu/people/fischer/TEST/getsequence.html",
	 'admin_frsvr',       "Daniel Fischer,dfischer\@cs.bgu.ac.il ",
	 'quote_frsvr',       "D Fischer and DA Eisenberg: ".
                              "Fold Recognition Using Sequence-Derived Properties. ".
                              "Protein Science, 5, 947-955, 1996".
           		      "\n".
                              "A Elofsson, D Fischer, DW Rice, S LeGrand and DA Eisenberg: ".
                              "Study of Combined Structure-sequence Profiles. ".
                              "Folding and Design, 1, 451-461, 1996",
				# 
	 'cgi_genthreader',   "http://137.205.156.147/cgi-bin/psipred/psipred.cgi",
	 'url_genthreader',   "http://137.205.156.147/psiform.html",
	 'admin_genthreader', "David Jones,jones\@globin.bio.warwick.ac.uk",
	 'quote_genthreader', "",
				# 
	 'cgi_jpred',         "http://circinus.ebi.ac.uk:8081/jpred-bin/pred_form",
	 'url_jpred',         "http://circinus.ebi.ac.uk:8081/",
	 'admin_jpred',       "James Cuff,james\@ebi.ac.uk",
	 'quote_jpred',       "J A Cuff and G J Barton: ".
                              "Evaluation and improvement of multiple sequence methods ".
                              "for protein secondary structure prediction. ".
                              "PROTEINS, 34, 508-519, 1999",
				# 
	 'cgi_memsat',        "http://137.205.156.147/cgi-bin/psipred/psipred.cgi",
	 'url_memsat',        "http://137.205.156.147/psiform.html",
	 'admin_memsat',      "David Jones,jones\@globin.bio.warwick.ac.uk",
	 'quote_memsat',      "",
				# 
	 'cgi_netoglyc',      "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_netoglyc',      "http://www.cbs.dtu.dk/services/NetOGlyc/",
	 'admin_netoglyc',    "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'quote_netoglyc',    "JE Hansen, O Lund, N Tolstrup, AA Gooley, KL Williams and ".
                              "S Brunak: NetOglyc: Prediction of mucin type O-glycosylation ".
                              "sites based on sequence context and surface accessibility. ".
                              "Glycoconjugate Journal, 15, 115-130, 1998".
                              "\n".
                              "JE Hansen, O Lund, K Rapacki and S Brunak:".
                              "O-glycbase version 2.0 - A revised database of O-glycosylated ".
                              "proteins. Nucleic Acids Research, 25, 278-282, 1997".
                              "\n".
                              "JE Hansen, O Lund, K Rapacki J Engelbrecht, H Bohr, ".
                              "JO Nielsen, J-E S Hansen and S Brunak: ".
                              "Prediction of O-glycosylation of mammalian proteins: ".
                              "Specificity patterns of ".
                              "UDP-GalNAc:-polypeptide N-acetylgalactosaminyltransferase. ".
                              "Biochemical Journal, 308, 801-813, 1995",
				# 
	 'cgi_pscan',         "http://www.biokemi.su.se/~server/pscan/profserver.cgi",
	 'url_pscan',         "http://www.biokemi.su.se/~server/pscan/",
	 'admin_pscan',       "Arne Elofsson,arne\@rune.biokemi.su.se",
	 'quote_pscan',       "",
				# 
	 'cgi_psipred',       "http://137.205.156.147/cgi-bin/psipred/psipred.cgi",
	 'url_psipred',       "http://137.205.156.147/psiform.html",
	 'admin_psipred',     "David Jones,jones\@globin.bio.warwick.ac.uk",
	 'quote_psipred',     "",
				# 
	 'cgi_pssm',          "http://bonsai.lif.icnet.uk/cgi-bin/fold_dir/master.pl",
	 'url_pssm',          "http://bonsai.lif.icnet.uk/foldfitnew/index.html",
	 'admin_pssm',        "",
	 'quote_pssm',        "",

	 'cgi_signalp',       "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_signalp',       "http://www.cbs.dtu.dk/services/SignalP/",
	 'admin_signalp',     "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'quote_signalp',     "H Nielsen, J Engelbrecht, S Brunak and G von Heijne: ".
                              "Identification of prokaryotic and eukaryotic signal ".
                              "peptides and prediction of their cleavage sites. ".
	                      "Protein Engineering 10, 1-6, 1997",
    				# 
	 'cgi_swissmodel',    "",
	 'url_swissmodel',    "",
	 'admin_swissmodel',  "",
	 'quote_swissmodel',  "",

	 'cgi_tmhmm',         "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_tmhmm',         "http://www.cbs.dtu.dk/services/TMHMM-1.0/",
	 'admin_tmhmm',       "Anders Krogh,krogh\@cbs.dtu.dk ",
	 'quote_tmhmm',       "H Nielsen and A Krogh: ".
                              "Prediction of signal peptides and signal anchors ".
                              "by a hidden Markov model. ".
                              "Proc of the Sixth Intern Conf on Intelligent Systems for ".
                              "Molecular Biology (ISMB98), 122-130, 1998".
                              "\n".
                              "ELL Sonnhammer, G von Heijne and A Krogh: ".
                              "A hidden Markov model for predicting transmembrane ".
                              "helices in protein sequences. ".
	                      "Proc of the Sixth Intern Conf on Intelligent Systems for ".
                              "Molecular Biology (ISMB98), 175-182, 1998",
				# 
	 'cgi_toppred',       "http://www.biokemi.su.se/~server/toppred2/toppredServer.cgi",
	 'url_toppred',       "http://www.biokemi.su.se/~server/toppred2/",
	 'admin_toppred',     "Erik Wallin,erikw\@biokemi.su.se",
	 'quote_toppred',     "G von Heijne: ".
                              "Membrane Protein Structure Prediction, ".
                              "Hydrophobicity Analysis and the Positive-inside Rule. ".
                              "J. Molecular Biology, 225, 487-494, 1992".
                              "\n".
                              "M Cserzo, E Wallin, I Simon, G von Heijne, and A Elofsson: ".
                              "Prediction of transmembrane alpha-helices in prokaryotic ".
                              "membrane proteins: the dense alignment surface method. ".
                              "Protein Engineering, 10, 673-676, 1997",
	 );

    %services_test=
	(
	 'cgi_generic',     "http://",
	 'cgi_basic',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_blocks',      "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_chlorop',     "http://www.chem.columbia.edu/~volker/cgi-bin/chlorop.cgi",
	 'cgi_das',         "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_frsvr',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_genthreader', "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_jpred',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_memsat',      "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_netoglyc',    "http://www.chem.columbia.edu/~volker/cgi-bin/netoglyc.cgi",
	 'cgi_pscan',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_psipred',     "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_pssm',        "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_signalp',     "http://www.chem.columbia.edu/~volker/cgi-bin/signalp.cgi",
	 'cgi_swissmodel',  "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_tmhmm',       "http://www.chem.columbia.edu/~volker/cgi-bin/tmhmm.cgi",
	 'cgi_toppred',     "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 );

				# ------------------------------
				# 


}				# end of iniEnv

1;
