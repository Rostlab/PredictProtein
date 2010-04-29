# quotes of methods
PROFQUOTE=PROF predictions
PROFTMBQUOTE=Prediction of transmembrane beta-barrelsfor entire proteomes (Bigelow, H., Petrey, D., Liu, J.,Przybylski, D. & Rost, B.)
MDQUOTE=MD - Protein disorder prediction based on orthogonal sources of information (Avner Schlessinger, Burkhard Rost)
COILSQUOTE=COILS prediction (A Lupas)
DISULFINDQUOTE=DISULFIND (A. Ceroni, A. Passerini, A. Vullo and P. Frasconi)
ASPQUOTE=Ambivalent Sequence Predictor(Malin Young, Kent Kirshenbaum, Stefan Highsmith)
NORSQUOTE=NORS predictions
ISISQUOTE=Predicted protein-protein interaction sites from local sequence information.(Ofran Y, Rost B)
PROSITEQUOTE=PROSITE motif search (A Bairoch; P Bucher and K Hofmann)
SEGQUOTE=SEG low-complexity regions (J C Wootton &amp; S Federhen)
FASTAQUOTE=Input Query
PHDQUOTE=PHD predictions
GLOBEQUOTE=GLOBE prediction of globularity
BLASTQUOTE=PSI-BLAST alignment header
# html headers for results

# tese are special cases where sed is used to append this header to top of results file
PHDHEAD="1i\<a name=\"prof_body\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('profhead')\"><strong>$(PROFQUOTE)</strong></div><div style=\"display: block;\" id=\"profhead\" class=\"advanced\">"
PHDHEAD="1i\<b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('phdhead')\"></div><div style=\"display: block;\" id=\"phdhead\" class=\"advanced\">"
BLASTHEAD="1i\<a name=\"ali_psiBlast_head\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('ali_psiBlasthead')\"><strong>$(BLASTQUOTE)</strong></div><div style=\"display: block;\" id=\"ali_psiBlasthead\" class=\"advanced\">"

#these are "noraml" cases
PROFTMBHEAD="<a name=\"proftmb\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('proftmbhead')\"><strong>$(PROFTMBQUOTE)</strong></div><div style=\"display: block;\" id=\"proftmbhead\" class=\"advanced\">"
MDHEAD="<a name=\"mdisorder\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('mdisorderhead')\"><strong>$(MDQUOTE)</strong></div><div style=\"display: block;\" id=\"mdisorderhead\" class=\"advanced\">"
COILSHEAD="<a name=\"coils\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('coilshead')\"><strong>$(COILSQUOTE)</strong></div><div style=\"display: block;\" id=\"coilshead\" class=\"advanced\">"


DISULFINDHEAD="<a name=\"disulfind\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('disulfindhead')\"><strong>$(DISULFINDHEAD)</strong></div><div style=\"display: block;\" id=\"disulfindhead\" class=\"advanced\">"

ASPHEAD="<a name=\"asp\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('asphead')\"><strong>$(ASPHEAD)</strong></div><div style=\"display: block;\" id=\"asphead\" class=\"advanced\">"
NORSHEAD="<a name=\"nors\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('norshead')\"><strong>$(NORSQUOTE)</strong></div><div style=\"display: block;\" id=\"norshead\" class=\"advanced\">"


PROSITEHEAD="<a name=\"prosite\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('prositehead')\"><strong>$(PROSITEQUOTE)</strong></div><div style=\"display: block;\" id=\"prositehead\" class=\"advanced\">"

SEGHEAD="<a name=\"seg_norm\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('seghead')\"><strong>$(SEGQUOTE)</strong></div><div style=\"display: block;\" id=\"seghead\" class=\"advanced\">"
FASTAHEAD="<a name=\"in_given\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('fastahead')\"><strong>$(FASTAQUOTE)</strong></div><div style=\"display: block;\" id=\"fastahead\" class=\"advanced\">"
GLOBEHEAD="<a name=\"profglobe\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('globehead')\"><strong>$(GLOBEQUOTE)</strong></div><div style=\"display: block;\" id=\"globehead\" class=\"advanced\">"
ISISHEAD="<a name=\"profglobe\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('isishead')\"><strong>$(ISISQUOTE)</strong></div><div style=\"display: block;\" id=\"isishead\" class=\"advanced\">"
TOCHEAD=<div id="container"><b class="b1fc"></b><b class="b2fc"></b><b class="b3fc"></b><b class="b4fc"></b><div id="maintop"></div><div id="main"><div style="padding: 10px">

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




