#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#####################################

JOBID:=$(basename $(notdir $(INFILE)))

TEMPDIR:=/tmp/pp/
DISULFINDDIR:=$(TEMPDIR)/disulfinder/

BLASTCORES := 1

# FOLDER LOCATION (CONFIGURABLE)
PPROOT:=/mnt/home/gyachdav/Development/predictprotein/
HELPERAPPSDIR:=$(PPROOT)helper_apps/
LIBRGUTILS:=/usr/share/librg-utils-perl/
PROFROOT:=/usr/share/profphd/prof/

# DATA (CONFIGURABLE)
BLASTDATADIR:=/mnt/project/rost_db/data/blast/
PRODOMDIR:=/mnt/project/rost_db/data/prodom/
DBSWISS:=/mnt/project/rost_db/data/swissprot/current/
PROSITEDIR:=/mnt/project/rost_db/data/prosite/

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
DISULFINDFILE:=$(DISULFINDDIR)$(notdir $(BLASTMATFILE))
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

.PHONY: all
all:  $(FASTAFILE) $(GCGFILE) $(PROSITEFILE) $(SEGGCGFILE) $(GLOBEFILE) $(HSSPFILTERFILE) $(BLASTPFILTERFILE) $(PRODOMFILE) $(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) $(NORSFILE) sec-struct disorder interaction function  $(DESTDIR) 
	rm -f $(HSSPFILE) $(BLASTFILE) $(BLASTCHECKFILE) $(BLASTPFILTERFILE) $(BLASTMATFILE) $(BLASTALIFILE) 
	mv $(TEMPDIR)/* $(DESTDIR)
	rm -rf $(TEMPDIR)
	@echo "Process complete. Results are in " $(DESTDIR)

.PHONY: sec-struct
sec-struct:  $(COILSFILE) $(PHDRDBFILE) $(PROFTEXTFILE) $(PROFTMBFILE)

.PHONY: disorder
disorder: $(ASPFILE) $(NORSFILE) $(METADISORDERFILE)

.PHONEY: function
function: $(NLSFILE) $(DISULFINDFILE)

.PHONEY: interaction
interaction: $(ISISFILE) $(DISISFILE)

$(PROFTMBFILE):  $(BLASTMATFILE)
	proftmb @/usr/share/proftmb/options -q $< -o $@

$(ISISFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profisis  --fastafile $(FASTAFILE)  --rdbproffile $(PROFFILE) --hsspfile $(HSSPBLASTFILTERFILE)  --outfile $@

$(DISISFILE): $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profdisis --hsspfile $(HSSPBLASTFILTERFILE)  --rdbproffile $(PROFFILE)  --outfile $@


$(PROFBVALFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profbval $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ 1 5 $(JOBID)

$(NORSNETFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE)
	norsnet $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ $(JOBID) $(PROFBVALFILE)

$(METADISORDERFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE) $(NORSNETFILE) $(BLASTCHECKFILE)
	metadisorder fasta=$(FASTAFILE) hssp=$(HSSPBLASTFILTERFILE) prof=$(PROFFILE) profbval_raw=$(PROFBVALFILE) norsnet=$(NORSNETFILE) chk=$(BLASTCHECKFILE) out=$@ out_mode=1

$(HSSPFILE): $(SAFFILE)
	 $(LIBRGUTILS)copf.pl $<  formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq dirWork=$(TEMPDIR)

$(HSSPBLASTFILTERFILE): $(HSSPFILE)
	 $(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@ dirWork=$(TEMPDIR)

$(BLASTPFILE):  $(FASTAFILE)
	blastall -p blastp -d $(BLASTDATADIR)swiss -b 4000 -i $< -o $@ 

$(BLASTPFILTERFILE): $(BLASTPFILE)
	$(PPROOT)filter_blastp_big.pl $< db=swiss dir=$(DBSWISS) > $@

$(HSSPFILTERFILE): $(HSSPBLASTFILTERFILE) |$(TEMPDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide exeFilterHssp=filter_hssp dirWork=$(TEMPDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen dirWork=$(TEMPDIR)

$(HSSPFILTERFORPHDFILE): $(HSSPBLASTFILTERFILE) |$(TEMPDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide red=90 exeFilterHssp=filter_hssp dirWork=$(TEMPDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen dirWork=$(TEMPDIR)

$(GLOBEFILE) : $(PROFFILE) 
	profglobe --prof_file $<  --output_file $@

$(COILSFILE) $(COILSRAWFILE): $(FASTAFILE)
	COILSTMP=$$(mktemp -d) && trap "rm -rf '$$COILSTMP'" EXIT; cd $$COILSTMP && coils-wrap.pl -m MTIDK -i $< -o $(COILSFILE) -r $(COILSRAWFILE);

$(DISULFINDFILE): $(BLASTMATFILE) $(DISULFINDDIR)  | $(TEMPDIR) 
	disulfinder -a 1 -p $<  -o $(DISULFINDDIR) -r $(DISULFINDDIR) -F html

$(NLSFILE) $(NLSSUMFILE): $(FASTAFILE) |$(TEMPDIR)
	predictnls dirOut=$(TEMPDIR) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) fileTrace=$(NLSFILE).nlsTrace html=1

$(PHDFILE) $(PHDRDBFILE) $(PHDNOTHTMFILE): $(HSSPBLASTFILTERFILE)
	$(PROFROOT)embl/phd.pl $(HSSPBLASTFILTERFILE) htm exePhd=phd1994 filterHsspMetric=$(PROFROOT)embl/mat/Maxhom_Blosum.metric  exeHtmfil=$(PROFROOT)embl/scr/phd_htmfil.pl \
	 exeHtmtop=$(PROFROOT)embl/scr/phd_htmtop.pl paraSec=$(PROFROOT)embl/para/Para-sec317-may94.com paraAcc=$(PROFROOT)embl/para/Para-exp152x-mar94.com \
	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader dirOut=$(TEMPDIR) dirWork=$(TEMPDIR) jobid=$(JOBID) fileOutPhd=$(PHDFILE) \
	fileOutRdb=$(PHDRDBFILE)  fileOutRdbHtm=$(PHDRDBHTMFILE) fileNotHtm=$(PHDNOTHTMFILE)  optDoHtmref=1  optDoHtmtop=1 optHtmisitMin=0.2 exeCopf=$(LIBRGUTILS)copf.pl \
	nresPerLineAli=60 exePhd2msf=$(PROFROOT)embl/scr/conv_phd2msf.pl exePhd2dssp=$(PROFROOT)/embl/scr/conv_phd2dssp.pl  exeConvertSeq=convert_seq \
	exeHsspFilter=filter_hssp doCleanTrace=1 > $(PHDFILE).screenPhd

$(PROFFILE): $(HSSPBLASTFILTERFILE)
	prof $< both  exeProfFor=profnet_prof  exePhd1994=$(PROFROOT)embl/phd.pl exePhd1994For=phd1994 para3=$(PROFROOT)net/PROFboth.par paraBoth=$(PROFROOT)net/PROFboth.par \
	paraSec=$(PROFROOT)net/PROFsec.par paraAcc=$(PROFROOT)net/PROFacc.par numresMin=17 nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=. \
	dirOut=$(TEMPDIR) dirWork=$(TEMPDIR) jobid=$(JOBID) fileRdb=$@ dbg verbose > $@.screenProf
	rm -f $(TEMPDIR)/PROF*

$(PROFTEXTFILE): $(PROFFILE)
	$(PROFROOT)scr/conv_prof.pl $< fileOut=$@ ascii nohtml nodet nograph

$(ASPFILE): $(PROFFILE)
	profasp  -ws 5 -z -1.75 -min 9 -in $< -out $@ -err $@.errASP

# NORS
NORSDIR:= $(HELPERAPPSDIR)
EXE_NORS:= $(NORSDIR)nors.pl
$(NORSFILE) $(NORSSUMFILE): $(FASTAFILE) $(HSSPBLASTFILTERFILE) $(PROFFILE) $(PHDRDBFILE) $(COILSFILE)
	$(EXE_NORS)  -win 70 -secCut 12 -accLen 10 -fileSeq $(FASTAFILE) -fileHssp $(HSSPBLASTFILTERFILE) \
	-filePhd $(PROFFILE) -filePhdHtm $(PHDRDBFILE) -fileCoils $(COILSFILE) -o $(NORSFILE) -fileSum $(NORSSUMFILE) -html

#PRODOM
$(PRODOMFILE):  $(FASTAFILE)
	blastall -p blastp -d $(PRODOMDIR)prodom -B 500 -i $< -o $@ 

$(PROSITEFILE): $(GCGFILE)
	$(HELPERAPPSDIR)prosite_scan.pl -h $(PROSITEDIR)prosite_convert.dat $< >> $@

$(SEGFILE): $(FASTAFILE)
	lowcompseg $< -x > $@
$(SEGGCGFILE): $(SEGFILE)
	/usr/share/librg-utils-perl/copf.pl $< formatOut=gcg fileOut=$@ dirWork=$(TEMPDIR)

$(BLASTFILE) $(BLASTCHECKFILE) $(BLASTMATFILE): $(FASTAFILE)
	blastpgp -a $(BLASTCORES) -j 3 -b 3000 -e 1 -F F -h 1e-3 -d $(BLASTDATADIR)big_80 -i $< -o $(BLASTFILE) -C $(BLASTCHECKFILE) -Q $(BLASTMATFILE)

$(BLASTALIFILE): $(BLASTCHECKFILE) $(FASTAFILE)
	blastpgp -a $(BLASTCORES) -b 1000 -e 1 -F F -d $(BLASTDATADIR)big -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE)

$(SAFFILE) $(BLASTFILERDB): $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$@ red=100 maxAli=3000 tile=0 fileOutErr=$@.blast2safErr

$(FASTAFILE): $(INFILE)
	$(LIBRGUTILS)copf.pl $< formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq dirWork=$(TEMPDIR)

$(GCGFILE): $(INFILE)
	$(LIBRGUTILS)copf.pl $< formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq dirWork=$(TEMPDIR)

.PRECIOUS: $(TEMPDIR)%.in
$(TEMPDIR)%.in: |$(TEMPDIR)
	tr -d '\000' < $@ > $(TEMPDIR)$*.in2  && \
	mv $(TEMPDIR)$*.in2 $@ &&\
	sed --in-place -e '/^\$$/d' $@ 

$(TEMPDIR) $(DESTDIR) $(DISULFINDDIR):
	mkdir -p $@

clean:
	rm -rf $(TEMPDIR) $(DESTDIR)

# Development purposes only remove this target in production
clean-html:
	rm -rf $(TEMPDIR)/*.html $(OUTPUTFILE) $(DISULFINDFILE).html

.PHONY: ECHO
ECHO:
	echo $(DISULFINDFILE)

.PHONY: help
help:
	@echo "Rules:"
	@echo "sec-struct - run secondary structure predictors"
	@echo "disorder - run disorder predictors"
	@echo "interaction - run bindingg site predictors"
	@echo "clean - purge the intermediary files foder."
	@echo "help - this message"
	@echo
	@echo "Variables:"
	@echo "BLASTCORES - default: 1"
	@echo "TEMPDIR - default: /tmp/pp/, mind the trailing /"

# vim:ai:
