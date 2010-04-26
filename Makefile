#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#####################################

include quotes.mk

JOBID:=$(basename $(notdir $(INFILE)))

TEMPDIR:=/tmp/pp/
OUTPUTDIR:=/mnt/home/gyachdav/public_html/
OUTPUTFILE:=$(OUTPUTDIR)$(JOBID).html

# FOLDER LOCATION (CONFIGURABLE)
PPROOT:=/mnt/home/gyachdav/Development/predictprotein/
HELPERAPPSDIR:=$(PPROOT)helper_apps/

LIBRGUTILS:=/usr/share/librg-utils-perl/
PROFROOT:=/usr/share/profphd/prof/

# DATA (CONFIGURABLE)
BLASTDATADIR:=/mnt/project/rost_db/data/blast/
PRODOMDIR:=/mnt/project/rost_db/data/prodom/
DBSWISS:=/mnt/project/rost_db/data/swissprot/current/
PROSITEDIR:=$(HELPERAPPSDIR)prosite/
PROSITEMATDIR:=$(PROSITEDIR)mat/

# STATIC FILES
HTMLHEAD=$(PPROOT)/resources/HtmlHead.html
HTMLQUOTE=$(PPROOT)/resources/HtmlQuote.html
HRFILE=$(PPROOT)/resources/HtmlHr.html
HTMLFOOTER=$(PPROOT)/resources/HtmlFooter.html

# RESULTS FILES
HSSPFILE:=$(INFILE:%.in=%.hssp)
HSSPBLASTFILTERFILE:=$(INFILE:%.in=%.hsspPsiFil)
HSSPFILTERFILE:=$(INFILE:%.in=%.hsspFilter)
HSSPFILTERFORPHDFILE:=$(INFILE:%.in=%.hsspMax4phd)
COILSFILE:=$(INFILE:%.in=%.coils)
COILSRAWFILE:=$(INFILE:%.in=%.coils_raw)
DISULFINDFILE:=$(INFILE:%.in=%.disulfind)
NLSFILE:=$(INFILE:%.in=%.nls)
NLSSUMFILE:=$(INFILE:%.in=%.nlsSum)
PHDFILE:=$(INFILE:%.in=%.phdPred)
PHDRDBFILE:=$(INFILE:%.in=%.phdRdb)
PHDRDBHTMFILE:=$(INFILE:%.in=%.phdRdbHtm)
PHDNOTHTMFILE:=$(INFILE:%.in=%.phdNotHtm)
PHDHTMLFILE:=$(INFILE:%.in=%.phd.html)
PROFFILE:=$(INFILE:%.in=%.profRdb)
PROFHTMLFILE:=$(INFILE:%.in=%.prof.html)
ASPFILE:=$(INFILE:%.in=%.asp)
NORSFILE:=$(INFILE:%.in=%.nors)
NORSSUMFILE:=$(INFILE:%.in=%.sumNors)
PRODOMFILE:=$(INFILE:%.in=%.proDdom)
PROSITEFILE:=$(INFILE:%.in=%.prosite)
GLOBEFILE:=$(INFILE:%.in=%.globe)
SEGFILE:=$(INFILE:%.in=%.segNorm)
SEGGCGFILE:=$(INFILE:%.in=%.segNormGCG)
BLASTFILE:=$(INFILE:%.in=%.blastPsiOutTmp)
BLASTCHECKFILE:=$(INFILE:%.in=%.chk)
BLASTFILERDB:=$(INFILE:%.in=%.blastPsiRdb)
BLASTPFILE:=$(INFILE:%.in=%.aliBlastp)
BLASTPFILTERFILE:=$(INFILE:%.in=%.aliFil_list)
BLASTMATFILE:=$(INFILE:%.in=%.blastPsiMat)
BLASTALIFILE:=$(INFILE:%.in=%.blastPsiAli)
SAFFILE:=$(INFILE:%.in=%.safBlastPsi)
FASTAFILE:=$(INFILE:%.in=%.fasta)
GCGFILE:=$(INFILE:%.in=%.seqGCG)
PROFBVALFILE:=$(INFILE:%.in=%.profbval)
NORSNETFILE:=$(INFILE:%.in=%.norsnet)
METADISORDERFILE:=$(INFILE:%.in=%.metadisorder)
PROFFILE:=$(INFILE:%.in=%.profRdb)
PROFTEXTFILE:=$(INFILE:%.in=%.profAscii)
PROFCONFILE:=$(INFILE:%.in=%.profcon)
PROFTMBFILE:=$(INFILE:%.in=%.proftmb)
PCCFILE:=$(INFILE:%.in=%.pcc)
SNAPFILE:=$(INFILE:%.in=%.snap)
ISISFILE:=$(INFILE:%.in=%.isis)
DISISFILE:=$(INFILE:%.in=%.disis)
PPFILE:=$(INFILE:%.in=%.predictprotein)
TOCFILE:=$(INFILE:%.in=%.toc.html)


.PHONY: sec-struct
sec-struct:  $(COILSFILE) $(PHDHTMLFILE) $(PROFTEXTFILE) $(PROFHTMLFILE) $(PROFTMBFILE).html 

.PHONY: disorder
disorder: $(ASPFILE) $(NORSFILE) $(METADISORDERFILE)

.PHONEY: function
function: $(NLSFILE) $(DISULFINDFILE).html

.PHONEY: interaction
function: $(DISISFILE).html $(DISISFILE).html

.PHONY: all
all: $(FASTAFILE) $(GCGFILE) $(PROSITEFILE) $(SEGGCGFILE) $(GLOBEFILE) $(HSSPFILTERFILE) $(BLASTPFILTERFILE) $(PRODOMFILE) $(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) $(COILSFILE) $(NLSFILE) $(PHDHTMLFILE)  $(PROFTEXTFILE) $(PROFHTMLFILE)  $(ASPFILE) $(NORSFILE) $(METADISORDERFILE)

$(OUTPUTFILE): $(FASTAFILE).html $(GCGFILE) $(PROSITEFILE).html $(SEGGCGFILE).html $(HSSPFILTERFILE) $(BLASTPFILTERFILE) $(PRODOMFILE) $(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) $(COILSFILE).html $(PHDHTMLFILE)  $(PROFTEXTFILE) $(PROFHTMLFILE) $(GLOBEFILE).html  $(ASPFILE).html $(PROFTMBFILE).html $(NORSFILE).html $(METADISORDERFILE).html
	sed -i '1i\<h2>Table Of Contents</h2>'  $(TOCFILE) 
	sed -i '1i\<ol>'  $(TOCFILE) 
	sed -i  '$$a\</ol>' $(TOCFILE)
	cat $(HTMLHEAD) $(TOCFILE) $(FASTAFILE).html $(HRFILE) $(PROSITEFILE).html $(HRFILE)  $(SEGGCGFILE).html $(HRFILE)  $(COILSFILE).html $(HRFILE)  $(PHDHTMLFILE) $(HRFILE) $(PROFHTMLFILE) $(HRFILE) $(GLOBEFILE).html  $(HRFILE) $(ASPFILE).html $(HRFILE) $(PROFTMBFILE).html $(HRFILE) $(NORSFILE).html $(HRFILE) $(METADISORDERFILE).html $(HRFILE)  $(HTMLQUOTE) $(HTMLFOOTER) > $@
	sed -i 's/VAR_jobid/$(JOBID)/' $@ 



$(PROFTMBFILE):  $(BLASTMATFILE)
	proftmb @/usr/share/proftmb/options -q $< -o $@
$(PROFTMBFILE).html: $(PROFTMBFILE)
	echo '<pre>' $(PROFTMBHEAD) > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(PROFTMBTOC) >> $(TOCFILE)

$(PROFBVALFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profbval $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ 1 5 $(JOBID)

$(NORSNETFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE)
	norsnet $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ $(JOBID) $(PROFBVALFILE)

$(METADISORDERFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE) $(NORSNETFILE) $(BLASTCHECKFILE)
	metadisorder fasta=$(FASTAFILE) hssp=$(HSSPBLASTFILTERFILE) prof=$(PROFFILE) profbval_raw=$(PROFBVALFILE) norsnet=$(NORSNETFILE) chk=$(BLASTCHECKFILE) out=$@ out_mode=1

$(METADISORDERFILE).html: $(METADISORDERFILE)
	echo '<pre>' $(MDHEAD)> $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(MDTOC) >> $(TOCFILE)

$(HSSPFILE): $(SAFFILE)
	 $(LIBRGUTILS)copf.pl $<  formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq

$(HSSPBLASTFILTERFILE): $(HSSPFILE)
	 $(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@

$(BLASTPFILE):  $(FASTAFILE)
	blastall -p blastp -d $(BLASTDATADIR)swiss -b 4000 -i $< -o $@ 

$(BLASTPFILTERFILE): $(BLASTPFILE)
	$(PPROOT)filter_blastp_big.pl $< db=swiss dir=$(DBSWISS) > $@

$(HSSPFILTERFILE): $(HSSPBLASTFILTERFILE) |$(TEMPDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide exeFilterHssp=filter_hssp dirWork=$(TEMPDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen fileOutTrace=$@.filterTrace

$(HSSPFILTERFORPHDFILE): $(HSSPBLASTFILTERFILE) |$(TEMPDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide red=90 exeFilterHssp=filter_hssp dirWork=$(TEMPDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen fileOutTrace=$@.filterTrace
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/RetNoali >> /tmp/gyachdav/pp_work/tquick.pred_temp

$(GLOBEFILE) : $(PROFFILE) 
	profglobe --prof_file $<  --output_file $@
$(GLOBEFILE).html: $(GLOBEFILE)
	echo '<pre>' $(GLOBEHEAD) > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(GLOBETOC) >> $(TOCFILE)

$(COILSFILE) $(COILSRAWFILE): $(FASTAFILE) 
	coils-wrap.pl -m MTIDK -i $< -o $(COILSFILE) -r $(COILSRAWFILE)

$(COILSFILE).html: $(COILSFILE)
	echo '<pre>' $(COILSHEAD) > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(COILSTOC) >> $(TOCFILE)

$(DISULFINDFILE): $(BLASTMATFILE) | $(TEMPDIR) 
	disulfinder -a 1 -p $< $(JOBID) -o $(TEMPDIR) -r $(TEMPDIR) 

$(DISULFINDFILE).html: $(DISULFINDFILE)
	echo '<pre>' $(DISULFINDHEAD)> $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(DISULFINDTOC) >> $(TOCFILE)


$(NLSFILE) $(NLSSUMFILE): $(FASTAFILE) |$(TEMPDIR)
	predictnls dirOut=$(TEMPDIR) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) fileTrace=$(NLSFILE).nlsTrace html=1
# /mnt/project/predictprotein/no_arch/pub//nls//pp_resonline.pl  dirOut=/tmp/gyachdav/pp_work/ fileIn=/tmp/gyachdav/pp_work/tquick.fasta fileOut=/tmp/gyachdav/pp_work/tquick.nls fileSummary=/tmp/gyachdav/pp_work/tquick.nlsSum fileTrace=/tmp/gyachdav/pp_work/tquick.nlsTrace html=1  
$(NLSFILE).html: $(NLSFILE)
	echo '<pre>' > $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(NLSTOC) >> $(TOCFILE)


$(PHDFILE) $(PHDRDBFILE) $(PHDNOTHTMFILE): $(HSSPBLASTFILTERFILE)
	$(PROFROOT)embl/phd.pl $(HSSPBLASTFILTERFILE) htm exePhd=phd1994 filterHsspMetric=$(PPROOT)Maxhom_Blosum.metric exeHtmfil=$(PROFROOT)embl/scr/phd_htmfil.pl \
	 exeHtmtop=$(PROFROOT)embl/scr/phd_htmtop.pl paraSec=$(PROFROOT)embl/para/Para-sec317-may94.com paraAcc=$(PROFROOT)embl/para/Para-exp152x-mar94.com \
	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader dirOut=$(TEMPDIR) dirWork=$(TEMPDIR) jobid=$(JOBID) fileOutPhd=$(PHDFILE) \
	fileOutRdb=$(PHDRDBFILE)  fileOutRdbHtm=$(PHDRDBHTMFILE) fileNotHtm=$(PHDNOTHTMFILE)  optDoHtmref=1  optDoHtmtop=1 optHtmisitMin=0.2 exeCopf=$(LIBRGUTILS)copf.pl \
	nresPerLineAli=60 exePhd2msf=$(PROFROOT)embl/scr/conv_phd2msf.pl exePhd2dssp=$(PROFROOT)/embl/scr/conv_phd2dssp.pl  exeConvertSeq=convert_seq \
	exeHsspFilter=filter_hssp doCleanTrace=1 > $(PHDFILE).screenPhd

$(PHDHTMLFILE): $(PHDRDBFILE)
	$(PROFROOT)embl/scr/conv_phd2html.pl $< fileOut=$@ parHtml=html:body,data:brief,data:normal
	echo $(PHDTOC) >> $(TOCFILE)	

$(PROFFILE): $(HSSPBLASTFILTERFILE)
	prof $< both  exeProfFor=profnet_prof  exePhd1994=$(PROFROOT)embl/phd.pl exePhd1994For=phd1994 para3=$(PROFROOT)net/PROFboth.par paraBoth=$(PROFROOT)net/PROFboth.par \
	paraSec=$(PROFROOT)net/PROFsec.par paraAcc=$(PROFROOT)net/PROFacc.par numresMin=17 nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=. \
	dirOut=$(TEMPDIR) dirWork=$(TEMPDIR) jobid=$(JOBID) fileRdb=$@ dbg verbose > $@.screenProf

$(PROFTEXTFILE): $(PROFFILE)
	$(PROFROOT)scr/conv_prof.pl $< fileOut=$@ ascii nohtml nodet nograph

$(PROFHTMLFILE): $(PROFFILE)
	$(PROFROOT)/scr/conv_prof.pl $< fileOut=$@ html noascii parHtml=html:body,data:brief,data:normal
	sed -i $(PROFHEAD) $@
	echo $(PROFTOC) >> $(TOCFILE)

$(ASPFILE): $(PROFFILE)
	profasp  -ws 5 -z -1.75 -min 9 -in $< -out $@ -err $@.errASP

$(ASPFILE).html: $(ASPFILE)
	echo '<pre>' $(ASPHEAD)> $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(ASPTOC) >> $(TOCFILE)

# NORS
NORSDIR:= $(HELPERAPPSDIR)nors/
EXE_NORS:= $(NORSDIR)nors.pl
$(NORSFILE) $(NORSSUMFILE): $(FASTAFILE) $(HSSPBLASTFILTERFILE) $(PROFFILE) $(PHDRDBFILE) $(COILSFILE)
	$(EXE_NORS)  -win 70 -secCut 12 -accLen 10 -fileSeq $(FASTAFILE) -fileHssp $(HSSPBLASTFILTERFILE) \
	-filePhd $(PROFFILE) -filePhdHtm $(PHDRDBFILE) -fileCoils $(COILSFILE) -o $(NORSFILE) -fileSum $(NORSSUMFILE)

$(NORSFILE).html: $(NORSFILE)
	echo '<pre>' $(NORSHEAD)> $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(NORSTOC) >> $(TOCFILE)

#PRODOM
$(PRODOMFILE):  $(FASTAFILE)
	blastall -p blastp -d $(PRODOMDIR)prodom -B 500 -i $< -o $@ 

# PROSITE
EXE_PROSITE:=$(PROSITEDIR)prosite_scan.pl
$(PROSITEFILE): $(GCGFILE)
	$(EXE_PROSITE) -h $(PROSITEMATDIR)prosite_convert.dat $< >> $@

$(PROSITEFILE).html: $(PROSITEFILE)
	echo '<pre>' $(PROSITEHEAD)> $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(PROSITETOC) >> $(TOCFILE)

$(SEGFILE): $(FASTAFILE)
	lowcompseg $< -x > $@
$(SEGGCGFILE): $(SEGFILE)
	/usr/share/librg-utils-perl/copf.pl $< formatOut=gcg fileOut=$@

$(SEGGCGFILE).html: $(SEGGCGFILE)
	sed -i 's/\(x\s\?\)\+/<font style=\"color:red\">&<\/font>/g' $< 	# highlight all X's in red
	echo '<pre>' $(SEGHEAD)> $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(SEGTOC) >> $(TOCFILE)


$(BLASTFILE) $(BLASTCHECKFILE) $(BLASTMATFILE): $(FASTAFILE)
	blastpgp  -j 3 -b 3000 -e 1 -F F -h 1e-3 -d $(BLASTDATADIR)big_80 -i $< -o $(BLASTFILE) -C $(BLASTCHECKFILE) -Q $(BLASTMATFILE)

$(BLASTALIFILE)  $(BLASTMATFILE): $(BLASTCHECKFILE) $(FASTAFILE)
	blastpgp  -b 1000 -e 1 -F F -d $(BLASTDATADIR)big -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE) -Q  $(BLASTMATFILE)

$(SAFFILE): $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$@ red=100 maxAli=3000 tile=0 fileOutErr=$@.blast2safErr

$(FASTAFILE): $(INFILE)
	$(LIBRGUTILS)copf.pl $< formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq

$(FASTAFILE).html: $(FASTAFILE)
	echo '<pre>' $(FASTAHEAD)>  $@ && \
	cat $< >> $@ && \
	echo '</pre>' >> $@
	echo $(FASTATOC) >> $(TOCFILE)


$(GCGFILE): $(INFILE)
	$(LIBRGUTILS)copf.pl $< formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq

.PRECIOUS: $(TEMPDIR)%.in
$(TEMPDIR)%.in: |$(TEMPDIR)
	tr -d '\000' < $*.in > $*.in2  && \
	mv  $*.in2  $*.in &&\
	sed --in-place -e '/^\$$/d' $*.in 

$(TEMPDIR):
	mkdir -p $(TEMPDIR)

clean:
	rm -rf $(TEMPDIR)

.PHONY: ECHO
ECHO:
	echo $(JOBID)

.PHONY: help
help:
	@echo "Rules:"
	@echo "all - run pipeline"
	@echo "sec-struct - run secondary structure predictors"
	@echo "disorder - run disorder predictors"
	@echo "interaction - run bindingg site predictors"
	@echo "clean - purge the intermediary files foder."
	@echo "help - this message"
	@echo
	@echo "Variables:"
	@echo ""
