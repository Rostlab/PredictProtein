#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#####################################

JOBID:=$(basename $(notdir $(INFILE)))

DEBUG:=
DESTDIR:=.
WORKDIR:=/tmp/pp/

DISULFINDDIR:=$(WORKDIR)/disulfinder/

BLASTCORES := 1

# FOLDER LOCATION (CONFIGURABLE)
PPROOT:=/usr/share/predictprotein
HELPERAPPSDIR:=$(PPROOT)/helper_apps/
LIBRGUTILS:=/usr/share/librg-utils-perl/
PROFROOT:=/usr/share/profphd/prof/
PROFTMBROOT:=/usr/share/proftmb/

# DATA (CONFIGURABLE)
BIGBLASTDB:=/mnt/project/rost_db/data/blast/big
BIG80BLASTDB:=/mnt/project/rost_db/data/blast/big_80
SWISSBLASTDB:=/mnt/project/rost_db/data/blast/swiss
PRODOMBLASTDB:=/mnt/project/rost_db/data/prodom/prodom
DBSWISS:=/mnt/project/rost_db/data/swissprot/current/
PROSITECONVDAT:=/mnt/project/rost_db/data/prosite/prosite_convert.dat

# STATIC FILES
HTMLHEAD=$(PPROOT)/resources/HtmlHead.html
HTMLQUOTE=$(PPROOT)/resources/HtmlQuote.html
HRFILE=$(PPROOT)/resources/HtmlHr.html
HTMLFOOTER=$(PPROOT)/resources/HtmlFooter.html

# RESULTS FILES
HSSPFILE:=$(INFILE:%.in=%.hssp)
HSSPFILE4MD:=$(INFILE:%.in=%.hssp4md)
HSSPBLASTFILTERFILE:=$(INFILE:%.in=%.hsspPsiFil)
HSSPBLASTFILTERFILE4MD:=$(INFILE:%.in=%.hsspPsiFil4md)
HSSPFILTERFILE:=$(INFILE:%.in=%.hsspFilter)
HSSPFILTERFORPHDFILE:=$(INFILE:%.in=%.hsspMax4phd)
COILSFILE:=$(INFILE:%.in=%.coils)
COILSRAWFILE:=$(INFILE:%.in=%.coils_raw)
NLSFILE:=$(INFILE:%.in=%.nls)
NLSSUMFILE:=$(INFILE:%.in=%.nlsSum)
NLSTRACEFILE:=$(INFILE:%.in=%.nlsTrace)
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
NORSNETFILE:=$(INFILE:%.in=%.norsnet)
PRODOMFILE:=$(INFILE:%.in=%.proDom)
PROSITEFILE:=$(INFILE:%.in=%.prosite)
GLOBEFILE:=$(INFILE:%.in=%.globe)
SEGFILE:=$(INFILE:%.in=%.segNorm)
SEGGCGFILE:=$(INFILE:%.in=%.segNormGCG)
BLASTFILE:=$(INFILE:%.in=%.blastPsiOutTmp)
BLASTFILE4MD:=$(INFILE:%.in=%.blastPsiOutTmp4md)
BLASTCHECKFILE:=$(INFILE:%.in=%.chk)
BLASTCHECKFILE4MD:=$(INFILE:%.in=%.chk4md)
BLASTFILERDB:=$(INFILE:%.in=%.blastPsiRdb)
BLASTPSWISS:=$(INFILE:%.in=%.aliBlastpSwiss)
# aliFil_list is not used by other rules. Guy says it may be used by loctree - we do not have loctree now.
BLASTPFILTERFILE:=$(INFILE:%.in=%.aliFil_list)
BLASTMATFILE:=$(INFILE:%.in=%.blastPsiMat)
BLASTALIFILE:=$(INFILE:%.in=%.blastPsiAli)
DISULFINDERFILE:=$(INFILE:%.in=%.disulfinder)
SAFFILE:=$(INFILE:%.in=%.safBlastPsi)
SAFFILE4MD:=$(INFILE:%.in=%.safBlastPsi4md)
FASTAFILE:=$(INFILE:%.in=%.fasta)
GCGFILE:=$(INFILE:%.in=%.seqGCG)
PROFBVALFILE:=$(INFILE:%.in=%.profbval)
METADISORDERFILE:=$(INFILE:%.in=%.mdisorder)
PROFTEXTFILE:=$(INFILE:%.in=%.profAscii)
# profcon is very slow and it is said not to have much effect on md results - so we do not run it
PROFCONFILE:=$(INFILE:%.in=%.profcon)
PROFTMBFILE:=$(INFILE:%.in=%.proftmb)
PCCFILE:=$(INFILE:%.in=%.pcc)
SNAPFILE:=$(INFILE:%.in=%.snap)
ISISFILE:=$(INFILE:%.in=%.isis)
DISISFILE:=$(INFILE:%.in=%.disis)
PPFILE:=$(INFILE:%.in=%.predictprotein)
TOCFILE:=$(INFILE:%.in=%.toc.html)

DISULFINDERCTRL :=
LOWCOMPSEGCTRL := "NOT APPLICABLE"
METADISORDERCTRL :=
NORSNETCTRL := "NOT APPLICABLE"
PREDICTNLSCTRL :=
PROFCTRL := "NOT APPLICABLE"
PROFASPCTRL := --ws=5 --z=-1.75 --min=9
PROFBVALCTRL := "NOT APPLICABLE"
PROFDISISCTRL :=
PROFGLOBECTRL :=
PROFISISCTRL :=
PROFNORSCTRL := --win=70 --secCut=12 --accLen=10
PROFTMBCTRL :=

.PHONY: all
all:  $(FASTAFILE) $(GCGFILE) $(PROSITEFILE) $(SEGGCGFILE) $(GLOBEFILE) disorder function interaction sec-struct

.PHONY: disorder
disorder: profasp profnors metadisorder

.PHONY: function
function: $(NLSFILE) $(DISULFINDERFILE) prodom

.PHONY: interaction
interaction: $(ISISFILE) $(DISISFILE)

.PHONY: sec-struct
sec-struct:  $(COILSFILE) $(PROFFILE) prof $(PROFTEXTFILE) $(PROFTMBFILE)

# these files do not seem to be required by any method:
.PHONY: hsspfilterfile
hsspfilterfile:	$(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) 

$(PROFTMBFILE):  $(BLASTMATFILE)
	proftmb @$(PROFTMBROOT)/options $(PROFTMBCTRL) -q $< -o $@ --quiet

.PHONY: proftmb
proftmb: $(PROFTMBFILE)

$(ISISFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profisis $(PROFISISCTRL) --fastafile $(FASTAFILE)  --rdbproffile $(PROFFILE) --hsspfile $(HSSPBLASTFILTERFILE)  --outfile $@

.PHONY: profisis
profisis: $(ISISFILE)

$(DISISFILE): $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profdisis $(PROFDISISCTRL) --hsspfile $(HSSPBLASTFILTERFILE)  --rdbproffile $(PROFFILE)  --outfile $@

.PHONY: profdisis
profdisis: $(DISISFILE)

$(PROFBVALFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE)
	profbval $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ 1 5 $(DEBUG)

.PHONY: profbval
profbval: $(PROFBVALFILE)

$(NORSNETFILE): $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $(PROFBVALFILE)
	norsnet $(FASTAFILE) $(PROFFILE) $(HSSPBLASTFILTERFILE) $@ $(JOBID) $(PROFBVALFILE)

.PHONY: norsnet
norsnet: $(NORSNETFILE)

$(METADISORDERFILE): $(FASTAFILE) $(PROFFILE) $(PROFBVALFILE) $(NORSNETFILE) $(HSSPBLASTFILTERFILE) $(BLASTCHECKFILE)
	# This line reuses blast files used by other methods as well. On a handful of test cases this and Avner's version (below) gave only a tiny - seemingly insignificant - difference in results.
	metadisorder $(METADISORDERCTRL) fasta=$(FASTAFILE) prof=$(PROFFILE) profbval_raw=$(PROFBVALFILE) norsnet=$(NORSNETFILE) hssp=$(HSSPBLASTFILTERFILE) chk=$(BLASTCHECKFILE) out=$@ out_mode=1

#$(METADISORDERFILE): $(FASTAFILE) $(PROFFILE) $(PROFBVALFILE) $(NORSNETFILE) $(HSSPBLASTFILTERFILE4MD) $(BLASTCHECKFILE4MD)
#	# This call depends on files prepared the way Avner's runMD.pl does it.
#	metadisorder $(METADISORDERCTRL) fasta=$(FASTAFILE) prof=$(PROFFILE) profbval_raw=$(PROFBVALFILE) norsnet=$(NORSNETFILE) hssp=$(HSSPBLASTFILTERFILE4MD) chk=$(BLASTCHECKFILE4MD) out=$@ out_mode=1

.PHONY: metadisorder
metadisorder: $(METADISORDERFILE)

$(HSSPFILE): $(SAFFILE)
	 $(LIBRGUTILS)/copf.pl $<  formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq dirWork=$(WORKDIR)

$(HSSPFILE4MD): $(SAFFILE4MD)
	$(LIBRGUTILS)/copf.pl $< formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq dirWork=$(WORKDIR)

$(HSSPBLASTFILTERFILE4MD): $(HSSPFILE4MD)
	$(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@ dirWork=$(WORKDIR)

$(HSSPBLASTFILTERFILE): $(HSSPFILE)
	$(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@ dirWork=$(WORKDIR)

$(BLASTPSWISS):  $(FASTAFILE)
	blastall -a $(BLASTCORES) -p blastp -d $(SWISSBLASTDB) -b 4000 -i $< -o $@ 

$(BLASTPFILTERFILE): $(BLASTPSWISS)
	$(HELPERAPPSDIR)filter_blastp_big.pl $< db=swiss dir=$(DBSWISS) > $@

$(HSSPFILTERFILE): $(HSSPBLASTFILTERFILE) |$(WORKDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide exeFilterHssp=filter_hssp dirWork=$(WORKDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen dirWork=$(WORKDIR)

$(HSSPFILTERFORPHDFILE): $(HSSPBLASTFILTERFILE) |$(WORKDIR)
	 $(LIBRGUTILS)/hssp_filter.pl $(HSSPBLASTFILTERFILE) fileOut=$@  thresh=8 threshSgi=-10 mode=ide red=90 exeFilterHssp=filter_hssp dirWork=$(WORKDIR) jobid=$(JOBID)  fileOutScreen=$@.filterScreen dirWork=$(WORKDIR)

$(GLOBEFILE) : $(PROFFILE) 
	profglobe $(PROFGLOBECTRL) --prof_file $<  --output_file $@

.PHONY: profglobe
profglobe: $(GLOBEFILE)

$(COILSFILE) $(COILSRAWFILE): $(FASTAFILE)
	COILSTMP=$$(mktemp -d) && trap "rm -rf '$$COILSTMP'" EXIT; cd $$COILSTMP && coils-wrap.pl -m MTIDK -i $< -o $(COILSFILE) -r $(COILSRAWFILE);

$(DISULFINDERFILE): $(BLASTMATFILE) | $(DISULFINDDIR)
	disulfinder $(DISULFINDERCTRL) -a 1 -p $<  -o $(DISULFINDDIR) -r $(DISULFINDDIR) -F html && \cp -a $(DISULFINDDIR)/$(notdir $<) $@

.PHONY: disulfinder
disulfinder: $(DISULFINDERFILE)

$(NLSFILE) $(NLSSUMFILE) $(NLSTRACEFILE): $(FASTAFILE) |$(WORKDIR)
	predictnls $(PREDICTNLSCTRL) dirOut=$(WORKDIR) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) fileTrace=$(NLSTRACEFILE) html=1

.PHONY: predictnls
predictnls: $(NLSFILE) $(NLSSUMFILE)

$(PHDFILE) $(PHDRDBFILE) $(PHDNOTHTMFILE): $(HSSPBLASTFILTERFILE)
	$(PROFROOT)embl/phd.pl $(HSSPBLASTFILTERFILE) htm exePhd=phd1994 filterHsspMetric=$(PROFROOT)embl/mat/Maxhom_Blosum.metric  exeHtmfil=$(PROFROOT)embl/scr/phd_htmfil.pl \
	 exeHtmtop=$(PROFROOT)embl/scr/phd_htmtop.pl paraSec=$(PROFROOT)embl/para/Para-sec317-may94.com paraAcc=$(PROFROOT)embl/para/Para-exp152x-mar94.com \
	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader dirOut=$(WORKDIR) dirWork=$(WORKDIR) jobid=$(JOBID) fileOutPhd=$(PHDFILE) \
	fileOutRdb=$(PHDRDBFILE)  fileOutRdbHtm=$(PHDRDBHTMFILE) fileNotHtm=$(PHDNOTHTMFILE)  optDoHtmref=1  optDoHtmtop=1 optHtmisitMin=0.2 exeCopf=$(LIBRGUTILS)/copf.pl \
	nresPerLineAli=60 exePhd2msf=$(PROFROOT)embl/scr/conv_phd2msf.pl exePhd2dssp=$(PROFROOT)/embl/scr/conv_phd2dssp.pl  exeConvertSeq=convert_seq \
	exeHsspFilter=filter_hssp doCleanTrace=1 > $(PHDFILE).screenPhd

$(PROFFILE): $(HSSPBLASTFILTERFILE)
	prof $< both  exeProfFor=profnet_prof  exePhd1994=$(PROFROOT)embl/phd.pl exePhd1994For=phd1994 para3=$(PROFROOT)net/PROFboth.par paraBoth=$(PROFROOT)net/PROFboth.par \
	paraSec=$(PROFROOT)net/PROFsec.par paraAcc=$(PROFROOT)net/PROFacc.par numresMin=17 nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=. \
	dirOut=$(WORKDIR) dirWork=$(WORKDIR) jobid=$(JOBID) fileRdb=$@ $(if $(DEBUG), 'dbg', ) verbose > $@.screenProf
	rm -f $(WORKDIR)/PROF*

.PHONY: prof
prof: $(PROFFILE)

$(PROFTEXTFILE): $(PROFFILE)
	$(PROFROOT)scr/conv_prof.pl $< fileOut=$@ ascii nohtml nodet nograph

$(ASPFILE): $(PROFFILE)
	profasp $(PROFASPCTRL) -in $< -out $@ -err $@.errASP

.PHONY: profasp
profasp: $(ASPFILE)

# NORS
NORSDIR:= $(HELPERAPPSDIR)
EXE_NORS:= $(NORSDIR)nors.pl
$(NORSFILE) $(NORSSUMFILE): $(FASTAFILE) $(HSSPBLASTFILTERFILE) $(PROFFILE) $(PHDRDBFILE) $(COILSFILE)
	# this call may throw warnings on STDERR (like 'wrong parsing coil file?? ctCoils=0') - silence it when we are not in debug mode
	$(EXE_NORS) $(PROFNORSCTRL) -fileSeq $(FASTAFILE) -fileHssp $(HSSPBLASTFILTERFILE) \
	-filePhd $(PROFFILE) -filePhdHtm $(PHDRDBFILE) -fileCoils $(COILSFILE) -o $(NORSFILE) -fileSum $(NORSSUMFILE) -html

.PHONY: profnors
profnors: $(NORSFILE) $(NORSSUMFILE)

#PRODOM
$(PRODOMFILE):  $(FASTAFILE)
	blastall -a $(BLASTCORES)  -p blastp -d $(PRODOMBLASTDB) -B 500 -i $< -o $@ 

.PHONY: prodom
prodom: $(PRODOMFILE)

$(PROSITEFILE): $(GCGFILE)
	$(HELPERAPPSDIR)prosite_scan.pl -h $(PROSITECONVDAT) $< >> $@

.PHONY: prosite
prosite: $(PROSITEFILE)

$(SEGFILE): $(FASTAFILE)
	lowcompseg $< -x > $@

.PHONY: lowcompseg
lowcompseg: $(SEGFILE)

$(SEGGCGFILE): $(SEGFILE)
	$(LIBRGUTILS)/copf.pl $< formatOut=gcg fileOut=$@ dirWork=$(WORKDIR)

$(BLASTFILE) $(BLASTCHECKFILE) $(BLASTMATFILE): $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	blastpgp -F F -a $(BLASTCORES) -j 3 -b 3000 -e 1 -h 1e-3 -d $(BIG80BLASTDB) -i $< -o $(BLASTFILE) -C $(BLASTCHECKFILE) -Q $(BLASTMATFILE) $(if $(DEBUG), , >&/dev/null)

$(BLASTALIFILE): $(BLASTCHECKFILE) $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	blastpgp -F F -a $(BLASTCORES) -b 1000 -e 1 -d $(BIGBLASTDB) -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE) $(if $(DEBUG), , >&/dev/null)

#$(BLASTFILE4MD) $(BLASTCHECKFILE4MD): $(FASTAFILE)
#	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
#	blastpgp -F F -a $(BLASTCORES) -j 3 -d $(BIGBLASTDB) -i $(FASTAFILE) -o $(BLASTFILE4MD) -C $(BLASTCHECKFILE4MD) $(if $(DEBUG), , >&/dev/null)

$(SAFFILE) $(BLASTFILERDB): $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$@ red=100 maxAli=3000 tile=0 fileOutErr=$@.blast2safErr

$(SAFFILE4MD): $(BLASTFILE4MD)
	$(LIBRGUTILS)/blast2saf.pl $< maxAli=3000 eSaf=1 saf=$@

$(FASTAFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq dirWork=$(WORKDIR)

$(GCGFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq dirWork=$(WORKDIR)

$(WORKDIR) $(DISULFINDDIR):
	mkdir -p $@

clean:
	rm -rf $(WORKDIR)

# Development purposes only remove this target in production
clean-html:
	rm -rf $(WORKDIR)/*.html $(OUTPUTFILE) $(DISULFINDERFILE).html

.PHONY: install
install:
	for f in \
		$(ASPFILE) \
		$(BLASTALIFILE) $(BLASTMATFILE) $(BLASTFILERDB) $(BLASTCHECKFILE) \
		$(BLASTPFILTERFILE) \
		$(COILSFILE) $(COILSRAWFILE) \
		$(DISISFILE) \
		$(DISULFINDERFILE) \
		$(FASTAFILE) \
		$(GLOBEFILE) \
		$(HSSPFILE) $(HSSPFILTERFILE) $(HSSPFILTERFORPHDFILE) $(HSSPBLASTFILTERFILE) \
		$(INFILE) \
		$(ISISFILE) \
		$(METADISORDERFILE) \
		$(NLSFILE) $(NLSSUMFILE) \
		$(NORSFILE) $(NORSSUMFILE) \
		$(NORSNETFILE) \
		$(PHDNOTHTMFILE) $(PHDFILE) $(PHDRDBFILE) \
		$(PRODOMFILE) \
		$(PROFTEXTFILE) $(PROFFILE) \
		$(PROFBVALFILE) \
		$(PROFTMBFILE) \
		$(PROSITEFILE) \
		$(SAFFILE) \
		$(SEGFILE) $(SEGGCGFILE) \
		$(GCGFILE) \
		$(HSSPFILE4MD) $(HSSPBLASTFILTERFILE4MD) $(BLASTFILE4MD) $(BLASTCHECKFILE4MD) $(SAFFILE4MD) \
	; do if [ -e $$f ]; then cp -a $$f $(DESTDIR)/ ; fi; done

.PHONY: help
help:
	@echo "Targets:"
	@echo "all - default"
	@echo "clean - purge the intermediary files foder"
	@echo "disorder - run disorder predictors"
	@echo "disulfinder"
	@echo "install - copy results to DESTDIR"
	@echo "interaction - run binding site predictors"
	@echo "proftmb"
	@echo "sec-struct - run secondary structure predictors"
	@echo
	@echo "help - this message"
	@echo
	@echo "Variables:"
	@echo "BLASTCORES - default: 1"
	@echo "DESTDIR - result files are copied here on 'install'"
	@echo "WORKDIR - default: /tmp/pp/, mind the trailing /"

# vim:ai:
