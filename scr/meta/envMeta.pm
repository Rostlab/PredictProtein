#!/usr/local/bin/perl -w

#===============================================================================
sub iniEnv {
    local($Lfrom_cgi)=@_;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniEnv                      set global parameters for PPmeta
#       in:                     $Lfrom_cgi=1 if caller is CGI script (shortcut)
#       out GLOBAL:             all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="iniEnv";
				# ------------------------------
				# avoid warnings
    $#services=  0;
    $exe_tmpname="";
    $exe_uuencode = "";
				# ------------------------------
				# directories (end with '/')
                                # scripts (machine independent)
    $DIR_meta_scr=  "/home/meta/server/scr/";
    $DIR_meta_cgi=  "/home/www/cgi/var/meta/";
    
				# binaries (machine dependent)
    $DIR_meta_bin=  "/home/meta/server/bin/";
#    $DIR_meta_bin=  "";
				# all working files will go here
    $DIR_meta_work= "";

				# ------------------------------
				# 
    %par=
	(
				# program to send mail
	 'exe_mail',         "/usr/sbin/Mail",
				# sendmail for the massaged backup mail messages
	 'exe_sendmail',     "/usr/lib/sendmail",
				# -i: ignores dots on a line by themselves
	 'opt_sendmail',     "-i",

				# 
	 'exe_lynx',         "/usr/local/bin/lynx",
				# program generating temporary filenames
	 'exe_tmpname',      $DIR_meta_bin."tmpnam.SGI64",
	 'exe_uuencode',     "/usr/bsd/uuencode",
	                        # uuencode mail attachments
	 'exe_mutt',         "/usr/local/bin/mutt",
	                        # mutt mailer

				# libraries
	 'lib_meta',         $DIR_meta_scr."lib-meta.pm",
	 'lib_services',     $DIR_meta_scr."lib-meta-services.pm",
	 'lib_sequence',     $DIR_meta_scr."lib-meta-sequence.pm",
	 'lib_cgi',          $DIR_meta_scr."lib-cgi.pm",
	 'lib_ctime',        $DIR_meta_scr."ctime.pm",

	 'par_cgi_metamail', "meta\@dodo.cpmc.columbia.edu",
	 
	 
	 );

				# tasks now (see %services{"task_name"})
    @methods=
	(
	 'various',
	 'homology modelling',
	 'threading',
	 'secondary structure',
	 'transmembrane helices',
	 );

				# ------------------------------
				# list of services
    @services=
	(
				# ..............................
				# homology modelling
	 'swissmodel',		# SWISS-MODEL, Nicolas Guex, Geneva, REMARK: missing 
	 'cphmodels',		# CPHmodels from CBS, Copenhagen

				# ..............................
				# threading
#	 'genthreader',		# David Jones, REMARK: do NOT activate before his ok
#	 'pssm',		# Sternberg group, REMARK: do NOT activate before their ok

	 'frsvr',		# Daniel Fischer, REMARK: missing
#	 'pscan',		# Arne Elofsson, REMARK: missing
	 'samt98',              # Kevin Karplus, REMARK: missing

				# ..............................
				# alignment
#	 'blocks',		# Shmuel Pietrokovski (LAMA server), REMARK: not yet

				# ..............................
				# 1D structure
	 'jpred',		# secondary structure prediction, EBI Hinxton
#	 'psipred',		# sec str, David Jones, REMARK: do NOT activate before his ok

				# ..............................
				# membrane
	 'tmhmm',		# Hidden Markov Model, Anders Krogh, Copenhagen
#	 'memsat',		# David Jones, REMARK: do NOT activate before his ok (or never)
	 'toppred',		# Gunnar von Heijne, REMARK: missing
	 'das',			# Arne Elofsson, REMARK: missing

				# ..............................
				# alignment

				# ..............................
				# various
	 'signalp',		# signal peptides, CBS Copenhagen
	 'netoglyc',		# glycosilation sites, CBS Copenhagen
	 'netphos',		# phosphorylation sites, CBS Copenhagen
	 'netpico',             # cleavage sites of picornaviral protease
	 'chlorop',		# chloroplast transit peptides, CBS Copenhagen

	 'testali',		# test alignment format

	 );


				# ==================================================
				# <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- 
				# shortcut for CGI call
				# <-- <-- <-- <-- <-- <-- <-- <-- <-- <-- 
    return(1,'ok')              if (defined $Lfrom_cgi && $Lfrom_cgi);


				# ==================================================

				# ------------------------------
				# check correctness of settings
    $#kwdLib=0;
    foreach $kwd (keys %par) {
	next if (! defined $kwd || length($kwd)<1);
	next if ($kwd !~/^(file|exe|lib)/);
				# 
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
	&abort($msg); }
    
				# ------------------------------
				# shortcuts
    $exe_tmpname=$par{"exe_tmpname"};
    $exe_uuencode=$par{"exe_uuencode"};


    %services=
	(
	 'cgi_generic',       "",
	 'url_generic',       "",
	 'task_generic',      "unk",
	 'admin_generic',     "name of administrator,email",
	 'doneby_generic',    "",
	 'quote_generic',     "person::title. Journal, Vol, pp, year.", 
	 'abbr_generic',      "generic",
				# 
	 'cgi_testali',       "",
	 'url_testali',       "",
	 'task_testali',      "unk",
	 'admin_testali',     "name of administrator,email",
	 'doneby_testali',    "",
	 'quote_testali',     "person::title. Journal, Vol, pp, year.", 
	 'abbr_testali',      "generic",
				# 
#	 'cgi_basic',         "http://cape6.scripps.edu/leszek/genome/cgi-bin/comp.pl",
	 'cgi_basic',         "http://leszek.sdsc.edu/cgi-bin/fold.pl",
#	 'url_basic',         "http://cape6.scripps.edu/leszek/genome/",
	 'url_basic',         "http://leszek.sdsc.edu/cgi-bin/fold.pl",
	 'task_basic',        "threading",
	 'admin_basic',       "Leszek Rychlewski,leszek\@sdsc.edu",
	 'doneby_basic',      "Leszek Jaroszewski, Leszek Rychlewski, and Adam Godzik (Scripps, San Diego, USA)",
	 'quote_basic',       "L Jaroszewski, L Rychlewski, B Zhang, and A Godzik::".
	                      "Fold prediction by a hierarchy of sequence and ".
	                      "threading methods".
	                      "Protein Science, 7, 1431-1440, 1998".
			      "\n".
	                      "B Zhang, L Jaroszewski, L Rychlewski, and A Godzik::".
	                      "Similarities and differences between nonhomologous ".
	                      "proteins with similar folds: evaluation of ".
	                      "threading strategies".
	                      "Folding & Design, 2, 307-317, 1997",
	 'abbr_basic',        "BASIC",
				# 
	 'cgi_chlorop',       "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_chlorop',       "http://www.cbs.dtu.dk/services/ChloroP/",
	 'task_chlorop',      "various",
	 'admin_chlorop',     "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'doneby_chlorop',    "Olof Emanuelsson (CBS Copenhagen, Denmark, olof\@cbs.dtu.dk)",
	 'quote_chlorop',     "O Emanuelsson, H Nielsen, and G von Heijne:".
                              "ChloroP, a neural network-based method for ".
                              "predicting chloroplast transit peptides and ".
                              "their cleavage sites. ".
                              "Protein Science, 8, 978-984, 1999",
	 'abbr_chlorop',      "ChloroP",
    				# 
	 'cgi_cphmodels',     "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_cphmodels',     "http://www.cbs.dtu.dk/services/CPHmodels/",
	 'task_cphmodels',    "homology modelling",
	 'admin_cphmodels',   "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'doneby_cphmodels',  "Ole Lund (CBS, Copenhagen, Denmark)",
	 'quote_cphmodels',   "O Lund, K Frimand, J Gorodkin, H Bohr, J Bohr, J Hansen, and S Brunak::".
	                      "Protein distance constraints predicted by neural networks and ".
                              "probability density functions. ".
	                      "Protein Engineering, 10, 1241-1248, 1997",
	 'abbr_cphmodels',    "CPHmodels",
				# 
	 'cgi_das',           "http://www.biokemi.su.se/~server/DAS/tmdas.cgi",
	 'url_das',           "http://www.biokemi.su.se/~server/DAS/",
	 'task_das',          "transmembrane helices",
	 'admin_das',         "Miklos Cserzo,miklos\@pugh.bip.bham.ac.uk",
	 'doneby_das',        "Miklos Cserzo, Istvan Simon (both Academy of Sciences, Budapest, Hungary), Erik Wallin, Gunnar von Heijne, Arne Elofsson (Stockholm Univ, Sweden)",
	 'quote_das',         "M Cserzo, E Wallin, I Simon, G von Heijne, and A Elofsson:: ".
                              "Prediction of transmembrane alpha-helices in procariotic ".
                              "membrane proteins: the Dense Alignment Surface method. ". 
                              "Protein Engineering, 10, 673-676, 1997",
	 'abbr_das',          "DAS",
				# 
	 'cgi_frsvr',         "http://www.doe-mbi.ucla.edu/cgi-bin/fischer.pl",
	 'url_frsvr',         "http://www.doe-mbi.ucla.edu/people/fischer/TEST/getsequence.html",
	 'task_frsvr',        "threading",
	 'admin_frsvr',       "Daniel Fischer,dfischer\@cs.bgu.ac.il ",
	 'doneby_frsvr',      "Daniel Fischer (Ben Gurion Univ of the Negev, Israel)",
	 'quote_frsvr',       "D Fischer, and DA Eisenberg:: ".
                              "Fold Recognition Using Sequence-Derived Properties. ".
                              "Protein Science, 5, 947-955, 1996".
           		      "\n".
                              "A Elofsson, D Fischer, DW Rice, S LeGrand, and DA Eisenberg:: ".
                              "Study of Combined Structure-sequence Profiles. ".
                              "Folding and Design, 1, 451-461, 1996",
	 'abbr_frsvr',        "FRSVR",
				# 
	 'cgi_genthreader',   "http://137.205.156.147/cgi-bin/psipred/psipred.cgi",
	 'url_genthreader',   "http://137.205.156.147/psiform.html",
	 'task_genthreader',  "threading",
	 'admin_genthreader', "David Jones,jones\@globin.bio.warwick.ac.uk",
	 'doneby_genthreader',"David Jones (Warwick University, England)",
	 'quote_genthreader', "",
	 'abbr_genthreader',  "GenThreader",
				# 
	 'cgi_jpred',         "http://circinus.ebi.ac.uk:8081/jpred-bin/pred_form",
	 'url_jpred',         "http://circinus.ebi.ac.uk:8081/",
	 'task_jpred',        "secondary structure",
	 'admin_jpred',       "James Cuff,james\@ebi.ac.uk",
	 'doneby_jpred',      "James Cuff, and Geoff Barton (EBI Hinxton, England)",
	 'quote_jpred',       "J A Cuff, and G J Barton:: ".
                              "Evaluation and improvement of multiple sequence methods ".
                              "for protein secondary structure prediction. ".
                              "PROTEINS, 34, 508-519, 1999",
	 'abbr_jpred',        "JPRED",
				# 
	 'cgi_memsat',        "http://137.205.156.147/cgi-bin/psipred/psipred.cgi",
	 'url_memsat',        "http://137.205.156.147/psiform.html",
	 'task_memsat',       "transmembrane helices",
	 'admin_memsat',      "David Jones,jones\@globin.bio.warwick.ac.uk",
	 'doneby_memsat',     "David Jones (Warwick Univ, England)",
	 'quote_memsat',      "David Jones (Warwick Univ, England) and Willy Taylor (MRC Mill-Hill, London, England)",
	 'abbr_memsat',       "MEMSAT",
				# 
	 'cgi_netoglyc',      "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_netoglyc',      "http://www.cbs.dtu.dk/services/NetOGlyc/",
	 'task_netoglyc',     "various",
	 'admin_netoglyc',    "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'doneby_netoglyc',   "Jan Hansen (CBS, Copenhagen, Denmark)",
	 'quote_netoglyc',    "JE Hansen, O Lund, N Tolstrup, AA Gooley, KL Williams, and ".
                              "S Brunak:: NetOglyc: Prediction of mucin type O-glycosylation ".
                              "sites based on sequence context and surface accessibility. ".
                              "Glycoconjugate Journal, 15, 115-130, 1998".
                              "\n".
                              "JE Hansen, O Lund, K Rapacki, and S Brunak:: ".
                              "O-glycbase version 2.0 - A revised database of O-glycosylated ".
                              "proteins. Nucleic Acids Research, 25, 278-282, 1997".
                              "\n".
                              "JE Hansen, O Lund, K Rapacki J Engelbrecht, H Bohr, ".
                              "JO Nielsen, J-E S Hansen, and S Brunak:: ".
                              "Prediction of O-glycosylation of mammalian proteins: ".
                              "Specificity patterns of ".
                              "UDP-GalNAc:-polypeptide N-acetylgalactosaminyltransferase. ".
                              "Biochemical Journal, 308, 801-813, 1995",
	 'abbr_netoglyc',     "NetOglyc",
				# 
	 'cgi_netpico',       "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_netpico',       "http://www.cbs.dtu.dk/services/NetPicoRNA/",
	 'task_netpico',      "various",
	 'admin_netpico',     "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'doneby_netpico',    "Nikolaj Blom (CBS, Copenhagen, Denmark, nikob\@cbs.dtu.dk)",
	 'quote_netpico',     "N Blom, J Hansen, D Blaas, and S Brunak:: ".
                              "Cleavage site analysis in picornaviral polyproteins: Discovering ".
	                      "cellular targets by neural networks. ".
                              "Protein Science, 5, 2203-2216, 1996",
	 'abbr_netpico',      "NetPico",
				# 
	 'cgi_netphos',       "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_netphos',       "http://www.cbs.dtu.dk/services/NetPhos",
	 'task_netphos',      "various",
	 'admin_netphos',     "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'doneby_netphos',    "Nikolaj Blom (CBS, Copenhagen, Denmark, nikob\@cbs.dtu.dk)",
	 'quote_netphos',     "N Blom, S Gammeltoft, and S Brunak:: ".
	                      "Sequence- and structure-based prediction of eukaryotic ".
	                      "protein phosphorylation Sites".
	                      ". J of Molecular Biology, 294, 1351-1362, 1999.",
	 'abbr_netphos',      "NetPhos",
				# 
	 'cgi_pscan',         "http://www.biokemi.su.se/~server/pscan/profserver.cgi",
	 'url_pscan',         "http://www.biokemi.su.se/~server/pscan/",
	 'task_pscan',        "threading",
	 'admin_pscan',       "Arne Elofsson,arne\@rune.biokemi.su.se",
	 'doneby_pscan',      "Arne Elofsson (Stockholm Univ, Sweden)",
	 'quote_pscan',       "",
	 'abbr_pscan',        "Pscan",
				# 
	 'cgi_psipred',       "http://137.205.156.147/cgi-bin/psipred/psipred.cgi",
	 'url_psipred',       "http://137.205.156.147/psiform.html",
	 'task_psipred',      "secondary structure",
	 'admin_psipred',     "David Jones,jones\@globin.bio.warwick.ac.uk",
	 'quote_psipred',     "David Jones (Warwick Univ, England)",
	 'abbr_psipred',      "PSIpred",
				# 
	 'cgi_pssm',          "http://bonsai.lif.icnet.uk/cgi-bin/fold_dir/master.pl",
	 'url_pssm',          "http://bonsai.lif.icnet.uk/foldfitnew/index.html",
	 'task_pssm',         "threading",
	 'admin_pssm',        "Lawrence Kelley,kelley\@icrf.icnet.uk",
	 'doneby_pssm',       "Robert Russell (SmithKline, Harlow, England), Mansoor Saqi, and Roger Sayle (both Glaxo, Stevenage, England), Paul Bates, Bob Maccallum, Lawrence Kelley and Michael Sternberg (all ICRF, London, England)",
	 'quote_pssm',        "R B Russel, M A S Saqi, R A Sayle, P A Bates, M J E Sternberg:: ".
	                      "Recognition of analogous and homologous protein folds:".
	                      "analysis of sequence and structure conservation.".
	                      "J Molecular Biology, 269, 423-439, 1997.",
	 'abbr_pssm',         "PSSM",

	 'cgi_samt98',        "http://www.cse.ucsc.edu/cgi-bin/cgiwrap/farmer/model-library-search.pl",
	 'url_samt98',        "http://www.cse.ucsc.edu/research/compbio/HMM-apps/model-library-search.html",
	 'task_samt98',       "threading",
	 'admin_samt98',      "SAM-INFO,sam-info\@cse.ucsc.edu",
	 'doneby_samt98',     "Kevin Karplus, Christian Barrett, and Richard Hughey (UCSD, Santa Cruz, USA)",
	 'quote_samt98',      "Kevin Karplus, Christian Barrett, and Richard Hughey::".
	                      "Hidden Markov Models for Detecting Remote Protein Homologies".
	                      "Bioinformatics, 14, 846-856, 1998",
	 'abbr_samt98',       "SAMt98",
				# 
	 'cgi_signalp',       "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_signalp',       "http://www.cbs.dtu.dk/services/SignalP/",
	 'task_signalp',      "various",
	 'admin_signalp',     "Kristoffer Rapacki,rapacki\@cbs.dtu.dk",
	 'doneby_signalp',    "Henrik Nielsen, Soeren Brunak (both CBS Copenhagen), and Gunnar von Heijne (Univ Stockholm, Sweden)",
	 'quote_signalp',     "H Nielsen, J Engelbrecht, S Brunak, and G von Heijne:: ".
                              "Identification of prokaryotic and eukaryotic signal ".
                              "peptides and prediction of their cleavage sites. ".
	                      "Protein Engineering 10, 1-6, 1997",
	 'abbr_signalp',      "SignalP",
    				# 
	 'cgi_swissmodel',    "http://www.expasy.ch//cgi-bin/sm-submit-requestb.pl",
	 'url_swissmodel',    "http://www.expasy.ch/swissmod/SWISS-MODEL.html",
	 'task_swissmodel',   "homology modelling",
	 'admin_swissmodel',  "Nicolas Guex,ng45767\@GlaxoWellcome.co.uk",
	 'doneby_swissmodel', "Manuel Peitsch, , Torsten Schwede, and Nicolas Guex (Glaxo, Geneva, Switzerland)",
	 'quote_swissmodel',  "M C Peitsch:: Protein Modelling by E-mail.".
	                      "Bio/Technology, 13, 658-660, 1995.".
	                      "\n".
	                      "M C Peitsch:: ".
	                      "ProMod and Swiss-Model: Internet-based tools for automated".
	                      "comparative protein modelling.".
	                      "Biochem Soc Trans, 24, 274-279, 1996.".
	                      "\n".
	                      "N Guex, and M C Peitsch::".
	                      "SWISS-MODEL and the Swiss-PdbViewer:".
	                      "An environment for comparative protein modelling.".
	                      "Electrophoresis, 18, 2714-2723, 1997.",
	 'abbr_swissmodel',   "SWISS-MODEL",

				# 
	 'cgi_tmhmm',         "http://genome.cbs.dtu.dk/htbin/nph-webface",
	 'url_tmhmm',         "http://www.cbs.dtu.dk/services/TMHMM-1.0/",
	 'task_tmhmm',        "transmembrane helices",
	 'admin_tmhmm',       "Anders Krogh,krogh\@cbs.dtu.dk ",
	 'doneby_tmhmm',      "Anders Krogh (CBS, Copenhagen, Denmark)",
	 'quote_tmhmm',       
# 	                      "H Nielsen, and A Krogh:: ".
#                              "Prediction of signal peptides and signal anchors ".
#                              "by a hidden Markov model. ".
#                              "Proc of the Sixth Intern Conf on Intelligent Systems for ".
#                              "Molecular Biology (ISMB98), 122-130, 1998".
#                              "\n".
                              "ELL Sonnhammer, G von Heijne, and A Krogh:: ".
                              "A hidden Markov model for predicting transmembrane ".
                              "helices in protein sequences. ".
	                      "Proc of the Sixth Intern Conf on Intelligent Systems for ".
                              "Molecular Biology (ISMB98), 175-182, 1998",
	 'abbr_tmhmm',        "TMHMM",
				# 
	 'cgi_toppred',       "http://www.biokemi.su.se/~server/toppred2/toppredServer.cgi",
	 'url_toppred',       "http://www.biokemi.su.se/~server/toppred2/",
	 'task_toppred',      "transmembrane helices",
	 'admin_toppred',     "Erik Wallin,erikw\@biokemi.su.se",
	 'doneby_toppred',    "Erik Wallin, and Gunnar von Heijne (Stockholm Univ, Sweden)",
	 'quote_toppred',     "G von Heijne:: ".
                              "Membrane Protein Structure Prediction, ".
                              "Hydrophobicity Analysis and the Positive-inside Rule. ".
                              "J. Molecular Biology, 225, 487-494, 1992".
                              "\n".
                              "M Cserzo, E Wallin, I Simon, G von Heijne, and A Elofsson:: ".
                              "Prediction of transmembrane alpha-helices in prokaryotic ".
                              "membrane proteins: the dense alignment surface method. ".
                              "Protein Engineering, 10, 673-676, 1997",
	 'abbr_toppred',      "TopPred",
	 );

    %services_test=
	(
	 'cgi_testali',    "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",

	 'cgi_generic',     "http://",
	 'cgi_basic',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_blocks',      "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_chlorop',     "http://www.chem.columbia.edu/~volker/cgi-bin/chlorop.cgi",
	 'cgi_cphmodels',   "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_das',         "http://butane.chem.columbia.edu/~volker/cgi-bin/tmdas.cgi",
	 'cgi_frsvr',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_genthreader', "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_jpred',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_memsat',      "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_netoglyc',    "http://www.chem.columbia.edu/~volker/cgi-bin/netoglyc.cgi",
	 'cgi_netpico',     "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_netphos',     "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_pscan',       "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_psipred',     "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_pssm',        "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_samt98',      "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_signalp',     "http://www.chem.columbia.edu/~volker/cgi-bin/signalp.cgi",
	 'cgi_swissmodel',  "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi",
	 'cgi_tmhmm',       "http://www.chem.columbia.edu/~volker/cgi-bin/tmhmm.cgi",
	 'cgi_toppred',     "http://butane.chem.columbia.edu/~volker/services/toppred/toppred.pl",
	 );

				# ------------------------------
				# 


}				# end of iniEnv

1;
