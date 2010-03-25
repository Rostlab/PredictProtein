#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#####################################

JOBID:=$(basename $(notdir $(INFILE)))

TEMPDIR:=/tmp/pp/

# FOLDER LOCATION (CONFIGURABLE)
PPROOT:=/mnt/project/predictprotein/Development/
HELPERAPPSDIR:=$(PPROOT)helper_apps/

LIBRGUTILS:=/usr/share/librg-utils-perl/
PROFROOT:=/usr/share/profphd/prof/

# DATA (CONFIGURABLE)
BLASTDATADIR:=/mnt/project/rost_db/data/blast/
PRODOMDIR:=/mnt/project/rost_db/data/prodom/
PROSITEDIR:=$(HELPER_APPS)prosite/
PROSITEMATDIR:=$(PROSITEDIR)mat/

# RESULTS FILES
HSSPFILE:=$(TEMPDIR)$(INFILE:%.in=%.hssp)
HSSPBLASTFILTERFILE:=$(TEMPDIR)$(INFILE:%.in=%.hsspPsiFil)
HSSPFILTERFILE:=$(TEMPDIR)$(INFILE:%.in=%.hsspFilter)
HSSPFILTERFORPHDFILE:=$(TEMPDIR)$(INFILE:%.in=%.hsspMax4phd)
COILSFILE:=$(TEMPDIR)$(INFILE:%.in=%.coils)
COILSRAWFILE:=$(TEMPDIR)$(INFILE:%.in=%.coils_raw)
DISULFINDFILE:=$(TEMPDIR)$(INFILE:%.in=%.disulfind)
NLSFILE:=$(TEMPDIR)$(INFILE:%.in=%.nls)
NLSSUMFILE:=$(TEMPDIR)$(INFILE:%.in=%.nlsSum)
PHDFILE:=$(TEMPDIR)$(INFILE:%.in=%.phdPred)
PHDRDBFILE:=$(TEMPDIR)$(INFILE:%.in=%.phdRdb)
PHDRDBHTMFILE:=$(TEMPDIR)$(INFILE:%.in=%.phdRdbHtm)
PHDNOTHTMFILE:=$(TEMPDIR)$(INFILE:%.in=%.phdNotHtm)
PHDHTMLFILE:=$(TEMPDIR)$(INFILE:%.in=%.html_phd)
PROFFILE:=$(TEMPDIR)$(INFILE:%.in=%.profRdb)
PROFHTMLFILE:=$(TEMPDIR)$(INFILE:%.in=%.html_prof)
ASPFILE:=$(TEMPDIR)$(INFILE:%.in=%.asp)
NORSFILE:=$(TEMPDIR)$(INFILE:%.in=%.nors)
NORSSUMFILE:=$(TEMPDIR)$(INFILE:%.in=%.sumNors)
PRODOMFILE:=$(TEMPDIR)$(INFILE:%.in=%.proDdom)
PROSITEFILE:=$(TEMPDIR)$(INFILE:%.in=%.prosite)

SEGFILE:=$(TEMPDIR)$(INFILE:%.in=%.segNorm)
BLASTFILE:=$(TEMPDIR)$(INFILE:%.in=%.blastPsiOutTmp)
BLASTCHECKFILE:=$(TEMPDIR)$(INFILE:%.in=%.chk)
BLASTFILERDB:=$(TEMPDIR)$(INFILE:%.in=%.blastPsiRdb)
BLASTPFILE:=$(TEMPDIR)$(INFILE:%.in=%.aliBlastp)
BLASTPFILTERFILE:=$(TEMPDIR)$(INFILE:%.in=%.aliFil_list)
BLASTMATFILE:=$(TEMPDIR)$(INFILE:%.in=%.blastPsiMat)
BLASTALIFILE:=$(TEMPDIR)$(INFILE:%.in=%.blastPsiAli)
SAFFILE:=$(TEMPDIR)$(INFILE:%.in=%.safBlastPsi)
FASTAFILE:=$(TEMPDIR)$(INFILE:%.in=%.fasta)
GCGFILE:=$(TEMPDIR)$(INFILE:%.in=%.seqGCG)
PROFBVALFILE:=$(TEMPDIR)$(INFILE:%.in=%.profbval)
NORSNETFILE:=$(TEMPDIR)$(INFILE:%.in=%.norsnet)
METADISORDERFILE:=$(TEMPDIR)$(INFILE:%.in=%.metadisorder)
PROFFILE:=$(TEMPDIR)$(INFILE:%.in=%.profRdb)
PROFCONFILE:=$(TEMPDIR)$(INFILE:%.in=%.profcon)
PCCFILE:=$(TEMPDIR)$(INFILE:%.in=%.pcc)
SNAPFILE:=$(TEMPDIR)$(INFILE:%.in=%.snap)
ISISFILE:=$(TEMPDIR)$(INFILE:%.in=%.isis)
DISISFILE:=$(TEMPDIR)$(INFILE:%.in=%.disis)
PPFILE:=$(TEMPDIR)$(INFILE:%.in=%.predictprotein)

.PHONY: all
all: $(FASTAFILE) $(GCGFILE) $(PROSITEFILE) $(SEGFILE) $(HSSPFILTERFILE) $(BLASTPFILTERFILE) $(PRODOMFILE) $(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) $(COILSFILE) $(DISULFINDFILE) $(NLSFILE) $(PHDHTMLFILE) $(PROFTEXTFILE) $(PROFHTMLFILE) $(ASPFILE) $(NORSFILE) $(METADISORDERFILE)
	cat $(FASTAFILE) $(SEGFILE) $(COILSFILE) $(DISULFINDFILE) $(NLSFILE) $(PROFTEXTFILE) $(PROFHTMLFILE) $(ASPFILE) $(METADISORDERFILE) >> $(PPFILE) 
$(PROFBVALFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profbval $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ 1 5 $(JOBID)

$(NORSNETFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE)
	norsnet $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ $(JOBID) $(PROFBVALFILE)

$(METADISORDERFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE) $(NORSNETFILE) $(BLASTCHECKFILE)
	metadisorder fasta=$(FASTAFILE) hssp=$(HSSPBLASTFILTERFILE) prof=$(PROFFILE) profbval_raw=$(PROFBVALFILE) norsnet=$(NORSNETFILE) chk=$(BLASTCHECKFILE) out=$@ out_mode=1

$(HSSPFILE): $(SAFFILE)
	 $(LIBRGUTILS)copf.pl $<  formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq

$(HSSPBLASTFILTERFILE): $(HSSPFILE)
	 $(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@

$(BLASTPFILE):  $(FASTAFILE)
	blastall -p blastp -d $(BLASTDATADIR)swiss -b 4000 -i $< -o $@ 

$(BLASTPFILTERFILE): $(BLASTPFILE)
	$(PPROOT)filter_blastp_big.pl $< db=swiss > $@

$(HSSPFILTERFILE): $(HSSPBLASTFILTERFILE) |$(TEMPDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide exeFilterHssp=filter_hssp dirWork=$(TEMPDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen fileOutTrace=$@.filterTrace

$(HSSPFILTERFORPHDFILE): $(HSSPBLASTFILTERFILE) |$(TEMPDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide red=90 exeFilterHssp=filter_hssp dirWork=$(TEMPDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen fileOutTrace=$@.filterTrace
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/RetNoali >> /tmp/gyachdav/pp_work/tquick.pred_temp


$(COILSFILE) $(COILSRAWFILE): $(FASTAFILE) 
	coils-wrap.pl -m MTIDK -i $< -o $(COILSFILE) -r $(COILSRAWFILE)
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Coils >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /tmp/gyachdav/pp_work/tquick.coils >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Line >> /tmp/gyachdav/pp_work/tquick.pred_temp


$(DISULFINDFILE): $(BLASTMATFILE) | $(TEMPDIR) 
	disulfinder -a 1 -p $< $(JOBID) -o $(TEMPDIR) 
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Disulfind >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /tmp/gyachdav/pp_work/tquick.disulfind >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Line >> /tmp/gyachdav/pp_work/tquick.pred_temp

$(NLSFILE) $(NLSSUMFILE): $(FASTAFILE) |$(TEMPDIR)
	predictnls dirOut=$(TEMPDIR) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) fileTrace=$(NLSFILE).nlsTrace html=1
# /mnt/project/predictprotein/no_arch/pub//nls//pp_resonline.pl  dirOut=/tmp/gyachdav/pp_work/ fileIn=/tmp/gyachdav/pp_work/tquick.fasta fileOut=/tmp/gyachdav/pp_work/tquick.nls fileSummary=/tmp/gyachdav/pp_work/tquick.nlsSum fileTrace=/tmp/gyachdav/pp_work/tquick.nlsTrace html=1  

$(PHDFILE) $(PHDRDBFILE) $(PHDNOTHTMFILE): $(HSSPBLASTFILTERFILE)
	$(PROFROOT)embl/phd.pl $(HSSPBLASTFILTERFILE) htm exePhd=phd1994 filterHsspMetric=$(PPROOT)Maxhom_Blosum.metric exeHtmfil=$(PROFROOT)embl/scr/phd_htmfil.pl \
	 exeHtmtop=$(PROFROOT)embl/scr/phd_htmtop.pl paraSec=$(PROFROOT)embl/para/Para-sec317-may94.com paraAcc=$(PROFROOT)embl/para/Para-exp152x-mar94.com \
	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader dirOut=$(TEMPDIR) dirWork=$(TEMPDIR) jobid=$(JOBID) fileOutPhd=$(PHDFILE) \
	fileOutRdb=$(PHDFILE)  fileOutRdbHtm=$(PHDFILE) fileNotHtm=$(PHDNOTHTMFILE)  optDoHtmref=1  optDoHtmtop=1 optHtmisitMin=0.2 exeCopf=$(LIBRGUTILS)copf.pl \
	nresPerLineAli=60 exePhd2msf=$(PROFROOT)embl/scr/conv_phd2msf.pl exePhd2dssp=$(PROFROOT)/embl/scr/conv_phd2dssp.pl  exeConvertSeq=convert_seq \
	exeHsspFilter=filter_hssp doCleanTrace=1 > $(PHDFILE).screenPhd
#cat < /usr/share/profphd/prof/embl//mat/headPhdConcise.txt >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/PredPhd >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /tmp/gyachdav/pp_work/tquick.phdPred >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Line >> /tmp/gyachdav/pp_work/tquick.pred_temp

$(PHDHTMLFILE): $(PHDRDBFILE)
	$(PROFROOT)embl/scr/conv_phd2html.pl $< fileOut=$@ parHtml=html:body,data:brief,data:normal

$(PROFFILE): $(HSSPBLASTFILTERFILE)
	prof $< both  exeProfFor=profnet_prof  exePhd1994=$(PROFROOT)embl/phd.pl exePhd1994For=phd1994 para3=$(PROFROOT)net/PROFboth.par paraBoth=$(PROFROOT)net/PROFboth.par \
	paraSec=$(PROFROOT)net/PROFsec.par paraAcc=$(PROFROOT)net/PROFacc.par numresMin=17 nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=. \
	dirOut=$(TEMPDIR) dirWork=$(TEMPDIR) jobid=$(JOBID) fileRdb=$@ dbg verbose > $@.screenProf

$(PROFTEXTFILE): $(PROFFILE)
	$(PROFROOT)embl/scr/conv_phd2html.pl $< fileOut=$@ ascii nohtml nodet nograph
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/PredProf >> /tmp/gyachdav/pp_work/tquick.pred_temp'
#cat < /tmp/gyachdav/pp_work/tquick.profAscii >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Line >> /tmp/gyachdav/pp_work/tquick.pred_temp

$(PROFHTMLFILE): $(PROFFILE)
		$(PROFROOT)embl/scr/conv_phd2html.pl $< fileOut=$@ parHtml=html:body,data:brief,data:normal
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Globe >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /tmp/gyachdav/pp_work/tquick.globeProf >> /tmp/gyachdav/pp_work/tquick.pred_temp

#GLOBE
# &globeOne(/tmp/gyachdav/pp_work/tquick.profRdb,STDOUT)
# /usr/share/profphd/prof/scr/conv_prof.pl /tmp/gyachdav/pp_work/tquick.profRdb ascii nohtml fileOut=/tmp/gyachdav/pp_work/tquick.profAscii nodet nograph


$(ASPFILE): $(PROFFILE)
	profasp  -ws 5 -z -1.75 -min 9 -in $< -out $@ -err $@.errASP
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Asp >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /tmp/gyachdav/pp_work/tquick.asp >> /tmp/gyachdav/pp_work/tquick.pred_temp
#cat < /mnt/project/predictprotein/no_arch/scr///txt//app/Line >> /tmp/gyachdav/pp_work/tquick.pred_temp

# NORS
NORSDIR:= $(HELPERAPPSDIR)nors/
EXE_NORS:= $(NORSDIR)nors.pl
$(NORSFILE) $(NORSSUMFILE): $(FASTAFILE) $(HSSPBLASTFILTERFILE) $(PROFFILE) $(PHDRDBFILE) $(COILSFILE)
	$(EXE_NORS)  -win 70 -secCut 12 -accLen 10 -fileSeq $(FASTAFILE) -fileHssp $(HSSPBLASTFILTERFILE) \
	-filePhd $(PROFFILE) -filePhdHtm $(PHDRDBFILE) -fileCoils $(COILSFILE) -o $(NORSFILE) -fileSum $(NORSSUMFILE)

#PRODOM
$(PRODOMFILE):  $(FASTAFILE)
	blastall -p blastp -d $(PRODOMDIR)prodom -B 500 -i $< -o $@ 

# PROSITE
EXE_PROSITE:=$(PROSITEDIR)prosite_scan.pl
$(PROSITEFILE): $(GCGFILE)
	$(EXE_PROSITE) -h $(PROSITEMATDIR)prosite_convert.dat $< >> $@

$(SEGFILE): $(FASTAFILE)
	lowcompseg $< -x > $@

$(BLASTFILE) $(BLASTCHECKFILE) $(BLASTMATFILE): $(FASTAFILE)
	blastpgp  -j 3 -b 3000 -e 1 -F T -h 1e-3 -d $(BLASTDATADIR)big_80 -i $< -o $(BLASTFILE) -C $(BLASTCHECKFILE) -Q $(BLASTMATFILE)

$(BLASTALIFILE)  $(BLASTMATFILE): $(BLASTCHECKFILE) $(FASTAFILE)
	blastpgp  -b 1000 -e 1 -F F -d $(BLASTDATADIR)big -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE) -Q  $(BLASTMATFILE)

$(SAFFILE): $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$@ red=100 maxAli=3000 tile=0 fileOutErr=$@.blast2safErr

$(FASTAFILE): $(FASTAFILE).tmp
	$(LIBRGUTILS)copf.pl $< formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq

$(GCGFILE): $(FASTAFILE).tmp
	$(LIBRGUTILS)copf.pl $< formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq

$(FASTAFILE).tmp:  $(TEMPDIR)$(INFILE)
	./interpretSeq.pl $@ < $<  

.PRECIOUS: $(TEMPDIR)%.in
$(TEMPDIR)%.in: |$(TEMPDIR)
	cp -aL $*.in $@ && \
	tr -d '\000' < $(TEMPDIR)$*.in > $(TEMPDIR)$*.in2  && \
	mv  $(TEMPDIR)$*.in2  $(TEMPDIR)$*.in &&\
	sed --in-place -e '/^\$$/d' $(TEMPDIR)$*.in 

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
	@echo "all* - run pipeline"
	@echo "clean - purge the intermediary files foder."
	@echo "help - this message"
	@echo
	@echo "Variables:"
	@echo ""
