# quotes of methods
PROFQUOTE=PROF predictions
PROFTMBQUOTE=Prediction of transmembrane beta-barrelsfor entire proteomes (Bigelow, H., Petrey, D., Liu, J.,Przybylski, D. & Rost, B.)
MDQUOTE=MD - Protein disorder prediction based on orthogonal sources of information (Avner Schlessinger, Burkhard Rost)
COILSQUOTE=Coils prediction (A Lupas)
DISULFINDQUOTE=DISULFIND (A. Ceroni, A. Passerini, A. Vullo and P. Frasconi)
ASPQUOTE=Ambivalent Sequence Predictor(Malin Young, Kent Kirshenbaum, Stefan Highsmith)
NORSQUOTE=NORS predictions
ISISQUOTE=Predicted protein-protein interaction sites from local sequence information.(Ofran Y, Rost B)
PROSITEQUOTE=PROSITE motif search (A Bairoch; P Bucher and K Hofmann)
SEGQUOTE=SEG low-complexity regions (J C Wootton &amp; S Federhen)
FASTAQUOTE=The following information has been received by the server
PHDQUOTE=PHD predictions
GLOBEQUOTE=GLOBE prediction of globularity
BLASTQUOTE=PSI-BLAST alignment header
# html headers for results
PROFHEAD='1i\<h2><a name="prof_body">$(PROFQUOTE)</a></h2>' # this is a special case where sed is used to append this header to top of results file
BLASTHEAD='1i\<h2><a name="ali_psiBlast_head">$(BLASTQUOTE)</a></h2>' # this is a special case where sed is used to append this header to top of results file
PROFTMBHEAD='<h2><a name ='proftmb'>$(PROFTMBQUOTE)</a></h2>'
MDHEAD='<h2><a name="mdisorder">$(MDQUOTE)</a></h2>'
COILSHEAD='<h2><a name="coils">$(COILSQUOTE)</a></h2>'
DISULFINDHEAD='<h2><a name="disulfind">$(DISULFINDQUOTE)</a></h2>'
ASPHEAD='<h2><a name="asp">$(ASPQUOTE)</a></h2>'
NORSHEAD='<h2><a name="nors">$(NORSQUOTE)</a></h2>'
PROSITEHEAD='<h2><a name="prosite">$(PROSITEQUOTE)</a></h2>'
SEGHEAD='<h2><a name="seg_norm">$(SEGQUOTE)</a></h2>'
FASTAHEAD='<h2><a name="in_given">$(FASTAQUOTE)</a></h2>'
GLOBEHEAD='<h2><a name="profglobe">$(GLOBEQUOTE)</a></h2>'
ISISHEAD='<h2><a name="isis">$(ISISQUOTE)</a></h2>'


# table of contents items
PROFTOC='<li><a href="\#prof_body">$(PROFQUOTE)</a></li>'
PHDTOC='<li><a href="\#phd_body">$(PHDQUOTE)</a></li>'
PROFTMBTOC='<li><a href ="\#proftmb">$(PROFTMBQUOTE)</a></li>'
MDTOC='<li><a href="\#mdisorder">$(MDQUOTE)</a></li>'
COILSTOC='<li><a href="\#coils">$(COILSQUOTE)</a></li>'
DISULFINDTOC='<li><a href="\#disulfind">$(DISULFINDQUOTE)</a></li>'
ASPTOC='<li><a href="\#asp">$(ASPQUOTE)</a></li>'
NORSTOC='<li><a href="\#nors">$(NORSQUOTE)</a></li>'
PROSITETOC='<li><a href="\#prosite">$(PROSITEQUOTE)</a></li>'
SEGTOC='<li><a href="\#seg_norm">$(SEGQUOTE)</a></li>'
FASTATOC='<li><a href="\#in_given">$(FASTAQUOTE)</a></li>'
GLOBETOC='<li><a href="\#profglobe">$(GLOBEQUOTE)</a></li>'
BLASTTOC='<li><a href="\#ali_psiBlast_head">$(BLASTQUOTE)</a></li>'
ISISTOC='<li><a href="\#isis">$(ISISQUOTE)</a></li>'