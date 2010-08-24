#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#####################################

MAKE_PP:=MakefilePP.mk
include $(MAKE_PP)

#OUTPUTDIR:=/mnt/home/gyachdav/public_html/
OUTPUTDIR:=./
OUTPUTFILE:=$(OUTPUTDIR)$(JOBID).html

# quotes of methods
PROFQUOTE:=PROF predictions
PROFTMBQUOTE:=Prediction of transmembrane beta-barrelsfor entire proteomes (Bigelow, H., Petrey, D., Liu, J.,Przybylski, D. & Rost, B.)
MDQUOTE:=Meta Disorder (MD) - Protein disorder prediction based on orthogonal sources of information (Avner Schlessinger, Burkhard Rost)
COILSQUOTE:=COILS prediction (A Lupas)
DISULFINDQUOTE:=DISULFIND (A. Ceroni, A. Passerini, A. Vullo and P. Frasconi)
ASPQUOTE:=Ambivalent Sequence Predictor(Malin Young, Kent Kirshenbaum, Stefan Highsmith)
NORSQUOTE:=NORS predictions
ISISQUOTE:=Predicted protein-protein interaction sites from local sequence information.(Ofran Y, Rost B)
DISISQUOTE:=Prediction of DNA binding residues from sequence. (Ofran Y, Myso re V, Yachdav G & Rost B; submitted)
PROSITEQUOTE:=PROSITE motif search (A Bairoch; P Bucher and K Hofmann)
SEGQUOTE:=SEG low-complexity regions (J C Wootton &amp; S Federhen)
FASTAQUOTE:=Input Query
PHDQUOTE:=PHD predictions
GLOBEQUOTE:=GLOBE prediction of globularity
BLASTQUOTE:=PSI-BLAST alignment header
# html headers for results

# tese are special cases where sed is used to append this header to top of results file
PROFHEAD:="1i\<div id='prof_body' class='nice'><h2>Secondary Structure</h2></div>"
PHDHEAD:="1i\<div id='phd_body' class='nice'><h2>Transmembrane</h2></div>"
BLASTHEAD:="1i<div id='phd_body' class='nice'><h2>Alignmnet</h2></div>"
#these are "noraml" cases
PROFTMBHEAD:="<div id='proftmb' class='nice'><h2>Transmembrane Beta-Barrel</h2></div>"
MDHEAD:="<div id='mdisorder' class='nice'><h2>Protein Disorder</h2></div>"
COILSHEAD:="<div id='coils' class='nice'><h2>Coiled Coils</h2></div>"
DISULFINDHEAD:="<div id='disulfind' class='nice'><h2>Disulphide Bonds</h2></div>"
ASPHEAD:="<div id='asp' class='nice'><h2>Ambivalent Sequence Predictor</h2></div>"
NORSHEAD:="<div id='nors' class='nice'><h2>Non-Ordinary Secondary Structure</h2></div>"
PROSITEHEAD:="<div id='prosite' class='nice'><h2>Prosite</h2></div>"
SEGHEAD:="<div id='seg_norm' class='nice'><h2>Low complexity segments</h2></div>"
FASTAHEAD:="<div id='in_given' class='nice'><h2>Input</h2></div>"
GLOBEHEAD:="<div id='profglobe' class='nice'><h2>Globularity</h2></div>"
ISISHEAD:="<div id='isis' class='nice'><h2>Protein-Protein binding</h2></div>"
DISISHEAD:="<div id='disis' class='nice'><h2>Protein-DNA binding</h2></div>"

TOCHEAD:=<div class="toc">
#TOCHEAD:=<div id="container"><b class="b1fc"></b><b class="b2fc"></b><b class="b3fc"></b><b class="b4fc"></b><div id="maintop"></div><div id="main"><div style="padding: 10px">

# table of contents items
PROFTOC:='<a href="\#prof_body">Secondary Structure</a>'
PHDTOC:='<a href="\#phd_body">Transmembrane</a>'
PROFTMBTOC:='<a href="\#proftmb">Trans-Membrane Beta-Barrel</a>'
MDTOC:='<a href="\#mdisorder">Protein Disorder</a>'
COILSTOC:='<a href="\#coils">Coiled Coils</a>'
DISULFINDTOC:='<a href="\#disulfind">Disulphide Bonds</a>'
ASPTOC:='<a href="\#asp">Ambivalent Switches</a>'
NORSTOC:='<a href="\#nors">Non-Ordinary Secondary Structure</a>'
PROSITETOC:='<a href="\#prosite" >Prosite</a>'
SEGTOC:='<a href="\#seg_norm">Low complexity segments</a>'
FASTATOC:='<a href="\#in_given" >Input</a>'
GLOBETOC:='<a href="\#profglobe" >Globular</a>'
BLASTTOC:='<a href="\#ali_psiBlast_head">Alignmnet</a>'
ISISTOC:='<a href="\#isis"  >Protein-Protein binding</a>'
DISISTOC:='<a href="\#disis">Protein-DNA binding</a>'

ENCLOSURE_OPEN:="<div id=\"sections\">"
ENCLOSURE_CLOSE:='</div>'

$(OUTPUTFILE): $(FASTAFILE).html $(PROFHTMLFILE) $(PHDHTMLFILE) $(COILSFILE).html $(SEGGCGFILE).html $(NORSFILE).html $(PROFTMBFILE).html  $(METADISORDERFILE).html $(ASPFILE).html $(ISISFILE).html $(GLOBEFILE).html $(PROSITEFILE).html $(BLASTFILERDB).html $(PROFTMBFILE).html $(HTMLQUOTE) $(HTMLFOOTER)
	sed -i '1i\$(TOCHEAD)'  $(TOCFILE)
	sed -i  '$$a\</div>' $(TOCFILE) 
	cat $(HTMLHEAD) $(HTMLOPTIONS) $(TOCFILE) >$@
	echo $(ENCLOSURE_OPEN) >>  $@ 
	cat  $(FASTAFILE).html $(PROFHTMLFILE) $(PHDHTMLFILE) $(COILSFILE).html $(SEGGCGFILE).html $(NORSFILE).html $(PROFTMBFILE).html  $(METADISORDERFILE).html $(ASPFILE).html $(ISISFILE).html $(GLOBEFILE).html $(PROSITEFILE).html $(BLASTFILERDB).html $(PROFTMBFILE).html $(HTMLQUOTE)  >> $@
	echo $(ENCLOSURE_CLOSE) >>  $@ 
	cat $(HTMLFOOTER) >> $@
	sed -i 's/VAR_jobid/$(JOBID)/' $@ 

$(PROFTMBFILE).html: $(SRCFOLDER)$(PROFTMBFILE)
	echo $(PROFTMBFILE)
	echo $(PROFTMBHEAD) '<pre>' > $@ && \
	cat $(SRCFOLDER)$(PROFTMBFILE) >> $@ && \
	echo '</pre>' >> $@ 
#	echo '</div>' >> $@ 
	echo $(PROFTMBTOC) >> $(TOCFILE)


$(ISISFILE).html: $(ISISFILE)
	echo $(ISISHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ 
#	echo '</div>' >> $@ 
	echo $(ISISTOC) >> $(TOCFILE)

$(METADISORDERFILE).html: $(METADISORDERFILE)
	echo $(MDHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
#	echo '</div>' >> $@ 
	echo $(MDTOC) >> $(TOCFILE)

$(BLASTFILERDB).html: $(BLASTFILERDB)
	$(HELPERAPPSDIR)blast2html.pl $< $@ html $(DBSWISS)
	sed -i $(BLASTHEAD) $@  
#	echo '</div>' >> $@ 
	echo $(BLASTTOC) >> $(TOCFILE)

$(GLOBEFILE).html: $(GLOBEFILE)
	echo $(GLOBEHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ 
#	echo '</div>' >> $@ 
	echo $(GLOBETOC) >> $(TOCFILE)

$(COILSFILE).html: $(COILSFILE)
	echo $(COILSHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ 
#	echo '</div>' >> $@ 
	echo $(COILSTOC) >> $(TOCFILE)

#$(DISULFINDFILE).html: $(DISULFINDFILE)
#	echo $(DISULFINDHEAD) > $@ && \
#	cat $< >> $@ && \
#	echo '</div>' >> $@ 
#	echo $(DISULFINDTOC) >> $(TOCFILE)



$(NLSFILE).html: $(NLSFILE)
	echo '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ 
#	echo '</div>' >> $@ 
	echo $(NLSTOC) >> $(TOCFILE)

$(PHDHTMLFILE): $(PHDRDBFILE)
	$(HELPERAPPSDIR)/conv_phd2html.pl $< fileOut=$@ parHtml=html:body,data:brief,data:normal
#	$(PROFROOT)embl/scr/conv_phd2html.pl $< fileOut=$@ parHtml=html:body,data:brief,data:normal
	sed -i $(PHDHEAD) $@ 
#	echo '</div>' >> $@ 
	echo $(PHDTOC) >> $(TOCFILE)	

$(PROFHTMLFILE): $(PROFFILE)
#	$(PROFROOT)/scr/conv_prof.pl $< fileOut=$@ html noascii noscroll nohead nobody
	$(HELPERAPPSDIR)/conv_prof.pl $< fileOut=$@ html noscroll html noascii
	sed -i $(PROFHEAD) $@ 
#	echo '</div>' >> $@ 
	echo $(PROFTOC) >> $(TOCFILE)


$(NORSFILE).html: $(NORSFILE)
	echo  $(NORSHEAD) > $@ && \
	cat $< >> $@ 
#	echo '</div>' >> $@ 
	echo $(NORSTOC) >> $(TOCFILE)

$(PROSITEFILE).html: $(PROSITEFILE)
	echo $(PROSITEHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@ 
#	echo '</div>' >> $@ 
	echo $(PROSITETOC) >> $(TOCFILE)

$(SEGGCGFILE).html: $(SEGGCGFILE)
	sed -i 's/\(x\s\?\)\+/<font style=\"color:red\">&<\/font>/g' $< 	# highlight all X's in red
	echo $(SEGHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
#	echo '</div>' >> $@ 
	echo $(SEGTOC) >> $(TOCFILE)

$(FASTAFILE).html: $(FASTAFILE)
	echo  $(FASTAHEAD) '<div class="input-section"><pre>' >  $@ && \
	cat $< >> $@ && \
	echo '</pre></div>' >> $@
#	echo '</div>' >> $@ 
	echo $(FASTATOC) >> $(TOCFILE)

$(ASPFILE).html: $(ASPFILE)
	echo $(ASPHEAD) '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
#	echo '</div>' >> $@ 
	echo $(ASPTOC) >> $(TOCFILE)


