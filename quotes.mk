#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#####################################

include $(MAIN_PIPELINE)


# quotes of methods
PROFQUOTE=PROF predictions
PROFTMBQUOTE=Prediction of transmembrane beta-barrelsfor entire proteomes (Bigelow, H., Petrey, D., Liu, J.,Przybylski, D. & Rost, B.)
MDQUOTE=MD - Protein disorder prediction based on orthogonal sources of information (Avner Schlessinger, Burkhard Rost)
COILSQUOTE=COILS prediction (A Lupas)
DISULFINDQUOTE=DISULFIND (A. Ceroni, A. Passerini, A. Vullo and P. Frasconi)
ASPQUOTE=Ambivalent Sequence Predictor(Malin Young, Kent Kirshenbaum, Stefan Highsmith)
NORSQUOTE=NORS predictions
ISISQUOTE=Predicted protein-protein interaction sites from local sequence information.(Ofran Y, Rost B)
DISISQUOTE=Prediction of DNA binding residues from sequence. (Ofran Y, Myso re V, Yachdav G & Rost B; submitted)
PROSITEQUOTE=PROSITE motif search (A Bairoch; P Bucher and K Hofmann)
SEGQUOTE=SEG low-complexity regions (J C Wootton &amp; S Federhen)
FASTAQUOTE=Input Query
PHDQUOTE=PHD predictions
GLOBEQUOTE=GLOBE prediction of globularity
BLASTQUOTE=PSI-BLAST alignment header
# html headers for results

# tese are special cases where sed is used to append this header to top of results file
PROFHEAD="1i\<a name=\"prof_body\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('profhead')\"><strong>$(PROFQUOTE)</strong></div><div style=\"display: none;\" id=\"profhead\" class=\"advanced\">"
PHDHEAD="1i\<b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('phdhead')\"><strong>$(PHDQUOTE)</strong></div><div style=\"display: none;\" id=\"phdhead\" class=\"advanced\">"
BLASTHEAD="1i\<a name=\"ali_psiBlast_head\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('ali_psiBlasthead')\"><strong>$(BLASTQUOTE)</strong></div><div style=\"display: none;\" id=\"ali_psiBlasthead\" class=\"advanced\">"

#these are "noraml" cases
PROFTMBHEAD="<a name=\"proftmb\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('proftmbhead')\"><strong>$(PROFTMBQUOTE)</strong></div><div style=\"display: none;\" id=\"proftmbhead\" class=\"advanced\">"
MDHEAD="<a name=\"mdisorder\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('mdisorderhead')\"><strong>$(MDQUOTE)</strong></div><div style=\"display: none;\" id=\"mdisorderhead\" class=\"advanced\">"
COILSHEAD="<a name=\"coils\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('coilshead')\"><strong>$(COILSQUOTE)</strong></div><div style=\"display: none;\" id=\"coilshead\" class=\"advanced\">"
DISULFINDHEAD="<a name=\"disulfind\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('disulfindhead')\"><strong>$(DISULFINDQUOTE)</strong></div><div style=\"display: none;\" id=\"disulfindhead\" class=\"advanced\">"
ASPHEAD="<a name=\"asp\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('asphead')\"><strong>$(ASPQUOTE)</strong></div><div style=\"display: none;\" id=\"asphead\" class=\"advanced\">"
NORSHEAD="<a name=\"nors\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('norshead')\"><strong>$(NORSQUOTE)</strong></div><div style=\"display: none;\" id=\"norshead\" class=\"advanced\">"
PROSITEHEAD="<a name=\"prosite\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('prositehead')\"><strong>$(PROSITEQUOTE)</strong></div><div style=\"display: none;\" id=\"prositehead\" class=\"advanced\">"
SEGHEAD="<a name=\"seg_norm\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('seghead')\"><strong>$(SEGQUOTE)</strong></div><div style=\"display: none;\" id=\"seghead\" class=\"advanced\">"
FASTAHEAD="<a name=\"in_given\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('fastahead')\"><strong>$(FASTAQUOTE)</strong></div><div style=\"display: none;\" id=\"fastahead\" class=\"advanced\">"
GLOBEHEAD="<a name=\"profglobe\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('globehead')\"><strong>$(GLOBEQUOTE)</strong></div><div style=\"display: none;\" id=\"globehead\" class=\"advanced\">"
ISISHEAD="<a name=\"isis\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('isishead')\"><strong>$(ISISQUOTE)</strong></div><div style=\"display: none;\" id=\"isishead\" class=\"advanced\">"
DISISHEAD="<a name=\"disis\"></a><b class=\"b1f\"></b><b class=\"b2f\"></b><b class=\"b3f\"></b><b class=\"b4f\"></b><div class=\"titlebar\" onClick=\"showHide('disishead')\"><strong>$(DISISQUOTE)</strong></div><div style=\"display: none;\" id=\"disishead\" class=\"advanced\">"
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
DISISTOC='<li><a href="\#disis">$(DISISQUOTE)</a></li>'



$(OUTPUTFILE): $(FASTAFILE).html $(GCGFILE) $(PROSITEFILE).html $(SEGGCGFILE).html $(HSSPFILTERFILE) $(BLASTPFILTERFILE) $(PRODOMFILE) $(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) $(BLASTFILERDB).html $(COILSFILE).html $(DISULFINDFILE).html $(PHDHTMLFILE)  $(PROFTEXTFILE) $(PROFHTMLFILE) $(GLOBEFILE).html  $(ASPFILE).html $(PROFTMBFILE).html $(NORSFILE).html $(METADISORDERFILE).html $(ISISFILE).html
	sed -i '1i\<ol>'  $(TOCFILE) 
	sed -i  '$$a\</ol>' $(TOCFILE)
	sed -i '1i\$(TOCHEAD)'  $(TOCFILE) 
	cat $(HTMLHEAD) $(TOCFILE) $(FASTAFILE).html $(HRFILE) $(PROSITEFILE).html $(HRFILE) $(BLASTFILERDB).html $(HRFILE) $(DISULFINDFILE).html $(HRFILE) $(SEGGCGFILE).html $(HRFILE)  $(COILSFILE).html $(HRFILE)  $(PHDHTMLFILE) $(HRFILE) $(PROFHTMLFILE) $(HRFILE) $(GLOBEFILE).html $(HRFILE) $(ASPFILE).html $(HRFILE) $(PROFTMBFILE).html $(HRFILE) $(NORSFILE).html $(HRFILE) $(METADISORDERFILE).html $(HRFILE) $(ISISFILE).html $(HRFILE)  $(HTMLQUOTE) $(HTMLFOOTER) > $@
	sed -i 's/VAR_jobid/$(JOBID)/' $@ 

$(PROFTMBFILE).html: $(PROFTMBFILE)
	echo $(PROFTMBHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(PROFTMBTOC) >> $(TOCFILE)


$(ISISFILE).html: $(ISISFILE)
	echo $(ISISHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(ISISTOC) >> $(TOCFILE)

$(METADISORDERFILE).html: $(METADISORDERFILE)
	echo $(MDHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(MDTOC) >> $(TOCFILE)

$(BLASTFILERDB).html: $(BLASTFILERDB)
	$(HELPERAPPSDIR)blast2html.pl $< $@ html $(DBSWISS)
	sed -i $(BLASTHEAD) $@  && \
	echo '</div>' >> $@ 
	echo $(BLASTTOC) >> $(TOCFILE)

$(GLOBEFILE).html: $(GLOBEFILE)
	echo $(GLOBEHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(GLOBETOC) >> $(TOCFILE)

$(COILSFILE).html: $(COILSFILE)
	echo $(COILSHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(COILSTOC) >> $(TOCFILE)

$(DISULFINDFILE).html: $(DISULFINDFILE)
	echo $(DISULFINDHEAD) > $@ && \
	cat $< >> $@ && \
	echo '</div>' >> $@ 
	echo $(DISULFINDTOC) >> $(TOCFILE)

$(NLSFILE).html: $(NLSFILE)
	echo '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(NLSTOC) >> $(TOCFILE)

$(PHDHTMLFILE): $(PHDRDBFILE)
	$(PROFROOT)embl/scr/conv_phd2html.pl $< fileOut=$@ parHtml=html:body,data:brief,data:normal
	sed -i $(PHDHEAD) $@ && \
	echo '</div>' >> $@ 
	echo $(PHDTOC) >> $(TOCFILE)	

$(PROFHTMLFILE): $(PROFFILE)
	$(PROFROOT)/scr/conv_prof.pl $< fileOut=$@ html noascii parHtml=html:body,data:brief,data:normal
	sed -i $(PROFHEAD) $@ && \
	echo '</div>' >> $@ 
	echo $(PROFTOC) >> $(TOCFILE)


$(NORSFILE).html: $(NORSFILE)
	echo  $(NORSHEAD) > $@ && \
	cat $< >> $@ && \
	echo '</div>' >> $@ 
	echo $(NORSTOC) >> $(TOCFILE)

$(PROSITEFILE).html: $(PROSITEFILE)
	echo $(PROSITEHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(PROSITETOC) >> $(TOCFILE)

$(SEGGCGFILE).html: $(SEGGCGFILE)
	sed -i 's/\(x\s\?\)\+/<font style=\"color:red\">&<\/font>/g' $< 	# highlight all X's in red
	echo $(SEGHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(SEGTOC) >> $(TOCFILE)

$(FASTAFILE).html: $(FASTAFILE)
	echo  $(FASTAHEAD) '<pre>' >  $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(FASTATOC) >> $(TOCFILE)

$(ASPFILE).html: $(ASPFILE)
	echo $(ASPHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ && \
	echo '</div>' >> $@ 
	echo $(ASPTOC) >> $(TOCFILE)

clean-html:
	rm -rf $(TEMPDIR)/*.html $(OUTPUTFILE) $(DISULFINDFILE).html
