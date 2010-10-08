#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#	(c) 2010 Laszlo Kajan rostlab
#####################################

JOBID:=$(basename $(notdir $(INFILE)))

DEBUG:=
DESTDIR:=.
# lkajan: attention $(WORKDIR) is not to be used by the component methods themselves; allowing this could lead to them deleting each others files in a parallel (-j12) run. Each method is to use its own working directory.
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
DBSWISS:=/mnt/project/rost_db/data/swissprot/current/
PFAM2:=/mnt/project/rost_db/data/pfam/Pfam_ls
PFAM3:=/mnt/project/rost_db/data/pfam/v24/Pfam-A.hmm
PRODOMBLASTDB:=/mnt/project/rost_db/data/prodom/prodom
PROSITECONVDAT:=/mnt/project/rost_db/data/prosite/prosite_convert.dat
PSICMAT:=/usr/share/psic/blosum62_psic.txt
SWISSBLASTDB:=/mnt/project/rost_db/data/blast/swiss

# TOOLS (CONFIGURABLE)
HMM2PFAMEXE:=hmm2pfam
HMM3SCANEXE:=hmmscan
PSICEXE:=/usr/share/snapfun/runNewPSIC.pl

# STATIC FILES
HTMLHEAD=$(PPROOT)/resources/HtmlHead.html
HTMLQUOTE=$(PPROOT)/resources/HtmlQuote.html
HRFILE=$(PPROOT)/resources/HtmlHr.html
HTMLFOOTER=$(PPROOT)/resources/HtmlFooter.html
HTMLOPTIONS=$(PPROOT)/resources/HtmlOptions.html
# RESULTS FILES
HSSPFILE:=$(INFILE:%.in=%.hssp)
HSSP80FILE:=$(INFILE:%.in=%.hssp80)
HSSPFILTERFILE:=$(INFILE:%.in=%.hsspPsiFil)
COILSFILE:=$(INFILE:%.in=%.coils)
COILSRAWFILE:=$(INFILE:%.in=%.coils_raw)
NLSFILE:=$(INFILE:%.in=%.nls)
NLSSUMFILE:=$(INFILE:%.in=%.nlsSum)
NLSTRACEFILE:=$(INFILE:%.in=%.nlsTrace)
PHDFILE:=$(INFILE:%.in=%.phdPred)
PHDRDBFILE:=$(INFILE:%.in=%.phdRdb)
# lkajan: never make PHDNOTHTMFILE a target - its creation depends on whether phd found an HTM region or not: it isn't always created
PHDNOTHTMFILE:=$(INFILE:%.in=%.phdNotHtm)
PHDHTMLFILE:=$(INFILE:%.in=%.phd.html)
PROFFILE:=$(INFILE:%.in=%.profRdb)
# prof output generated explicitely from one sequence - NO alignment - Chris Schaefer initiated this - B approved
PROF1FILE:=$(INFILE:%.in=%.prof1Rdb)
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
# this file is output from the first blastpgp call with 3 iterations
BLASTFILE:=$(INFILE:%.in=%.blastPsiOutTmp)
BLASTCHECKFILE:=$(INFILE:%.in=%.chk)
BLASTFILERDB:=$(INFILE:%.in=%.blastPsiRdb)
BLAST80FILERDB:=$(INFILE:%.in=%.blastPsi80Rdb)
BLASTPSWISSM8:=$(INFILE:%.in=%.blastpSwissM8)
BLASTMATFILE:=$(INFILE:%.in=%.blastPsiMat)
BLASTALIFILE:=$(INFILE:%.in=%.blastPsiAli)
DISULFINDERFILE:=$(INFILE:%.in=%.disulfinder)
HMM2PFAM:=$(INFILE:%.in=%.hmm2pfam)
HMM3PFAM:=$(INFILE:%.in=%.hmm3pfam)
HMM3PFAMTBL:=$(INFILE:%.in=%.hmm3pfamTbl)
HMM3PFAMDOMTBL:=$(INFILE:%.in=%.hmm3pfamDomTbl)
SAFFILE:=$(INFILE:%.in=%.safBlastPsi)
SAF80FILE:=$(INFILE:%.in=%.safBlastPsi80)
FASTAFILE:=$(INFILE:%.in=%.fasta)
GCGFILE:=$(INFILE:%.in=%.seqGCG)
PROFBVALFILE:=$(INFILE:%.in=%.profbval)
METADISORDERFILE:=$(INFILE:%.in=%.mdisorder)
PROFTEXTFILE:=$(INFILE:%.in=%.profAscii)
# profcon is very slow and it is said not to have much effect on md results - so we do not run it
PROFCONFILE:=$(INFILE:%.in=%.profcon)
PROFTMBFILE:=$(INFILE:%.in=%.proftmb)
PCCFILE:=$(INFILE:%.in=%.pcc)
LOCTREEANIMALFILE:=$(INFILE:%.in=%.loctreeAnimal)
LOCTREEANIMALTXTFILE:=$(INFILE:%.in=%.loctreeAnimalTxt)
LOCTREEPLANTFILE:=$(INFILE:%.in=%.loctreePlant)
LOCTREEPLANTTXTFILE:=$(INFILE:%.in=%.loctreePlantTxt)
LOCTREEPROKAFILE:=$(INFILE:%.in=%.loctreeProka)
LOCTREEPROKATXTFILE:=$(INFILE:%.in=%.loctreeProkaTxt)
PSICFILE:=$(INFILE:%.in=%.psic)
SNAPFILE:=$(INFILE:%.in=%.snap)
ISISFILE:=$(INFILE:%.in=%.isis)
DISISFILE:=$(INFILE:%.in=%.disis)
PPFILE:=$(INFILE:%.in=%.predictprotein)
TOCFILE:=$(INFILE:%.in=%.toc.html)
TMHMMFILE:=$(INFILE:%.in=%.tmhmm)

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
all:  $(FASTAFILE) $(GCGFILE) $(PROSITEFILE) $(SEGGCGFILE) $(GLOBEFILE) disorder function interaction pfam psic sec-struct subcell-loc

.PHONY: pfam
pfam: hmm2pfam hmm3pfam

.PHONY: psic
psic: $(PSICFILE)

.PHONY: disorder
disorder: profasp profnors metadisorder

.PHONY: function
function: $(NLSFILE) $(DISULFINDERFILE) prodom

.PHONY: interaction
interaction: $(ISISFILE) $(DISISFILE)

.PHONY: subcell-loc
subcell-loc: loctree

.PHONY: loctree
loctree: $(LOCTREEANIMALFILE) $(LOCTREEANIMALTXTFILE) $(LOCTREEPLANTFILE) $(LOCTREEPLANTTXTFILE) $(LOCTREEPROKAFILE) $(LOCTREEPROKATXTFILE)

$(LOCTREEANIMALFILE) $(LOCTREEANIMALTXTFILE) : $(FASTAFILE) $(BLASTPSWISSM8) $(HMM2PFAM) $(HSSPFILTERFILE) $(PROFFILE)
	loctree --fasta $(FASTAFILE) --loctreeres $(LOCTREEANIMALFILE) --loctreetxt $(LOCTREEANIMALTXTFILE) \
	  --use-blastall $(BLASTPSWISSM8) --use-blastall-names $(JOBID) --use-pfamres $(HMM2PFAM) --use-pfamres-names $(JOBID) --use-hssp-coll $(HSSPFILTERFILE) --use-rdbprof-coll $(PROFFILE) \
	  --org animal \
	  $(if $(DEBUG), --debug, )

$(LOCTREEPLANTFILE) $(LOCTREEPLANTTXTFILE) : $(FASTAFILE) $(BLASTPSWISSM8) $(HMM2PFAM) $(HSSPFILTERFILE) $(PROFFILE)
	loctree --fasta $(FASTAFILE) --loctreeres $(LOCTREEPLANTFILE) --loctreetxt $(LOCTREEPLANTTXTFILE) \
	  --use-blastall $(BLASTPSWISSM8) --use-blastall-names $(JOBID) --use-pfamres $(HMM2PFAM) --use-pfamres-names $(JOBID) --use-hssp-coll $(HSSPFILTERFILE) --use-rdbprof-coll $(PROFFILE) \
	  --org plant \
	  $(if $(DEBUG), --debug, )

$(LOCTREEPROKAFILE) $(LOCTREEPROKATXTFILE) : $(FASTAFILE) $(BLASTPSWISSM8) $(HMM2PFAM) $(HSSPFILTERFILE) $(PROFFILE)
	loctree --fasta $(FASTAFILE) --loctreeres $(LOCTREEPROKAFILE) --loctreetxt $(LOCTREEPROKATXTFILE) \
	  --use-blastall $(BLASTPSWISSM8) --use-blastall-names $(JOBID) --use-pfamres $(HMM2PFAM) --use-pfamres-names $(JOBID) --use-hssp-coll $(HSSPFILTERFILE) --use-rdbprof-coll $(PROFFILE) \
	  --org proka \
	  $(if $(DEBUG), --debug, )

$(PSICFILE) : $(FASTAFILE)
	# lkajan: this fails if sequence is shorter than 50 AA!
	$(PSICEXE) --infile $< $(if $(DEBUG), --debug, ) --noconffiles --blastdata_uniref $(BIGBLASTDB) --blastpgp_seg_filter F --blastpgp_processors $(BLASTCORES) --psic_matrix $(PSICMAT) --psicfile $@; RETVAL=$$?; if (( $$RETVAL == 254 )); then echo "sequence too short" > $@; else exit $$RETVAL; fi

.PHONY: hmm2pfam
hmm2pfam: $(HMM2PFAM)

$(HMM2PFAM): $(FASTAFILE)
	$(HMM2PFAMEXE) --cpu $(BLASTCORES) --acc --cut_ga $(PFAM2) $< > $@

$(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL) : $(FASTAFILE)
	$(HMM3SCANEXE) --cpu 4 --acc --cut_ga --notextw --tblout $(HMM3PFAMTBL) --domtblout $(HMM3PFAMDOMTBL) -o $(HMM3PFAM) $(PFAM3) $<

.PHONY: hmm3pfam
hmm3pfam: $(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL)

.PHONY: sec-struct
sec-struct:  $(COILSFILE) $(PROFFILE) phd prof $(PROFTEXTFILE) $(PROFTMBFILE) tmhmm

.PHONY: tmhmm
tmhmm: $(TMHMMFILE)

$(TMHMMFILE): $(FASTAFILE)
	tmhmm $< > $@

$(PROFTMBFILE):  $(BLASTMATFILE)
	proftmb @$(PROFTMBROOT)/options $(PROFTMBCTRL) -q $< -o $@ --quiet

.PHONY: proftmb
proftmb: $(PROFTMBFILE)

$(ISISFILE): $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE)
	profisis $(PROFISISCTRL) --fastafile $(FASTAFILE)  --rdbproffile $(PROFFILE) --hsspfile $(HSSPFILTERFILE)  --outfile $@

.PHONY: profisis
profisis: $(ISISFILE)

$(DISISFILE): $(PROFFILE) $(HSSPFILTERFILE)
	profdisis $(PROFDISISCTRL) --hsspfile $(HSSPFILTERFILE)  --rdbproffile $(PROFFILE)  --outfile $@

.PHONY: profdisis
profdisis: $(DISISFILE)

$(PROFBVALFILE): $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE)
	profbval $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE) $@ 1 5 $(DEBUG)

.PHONY: profbval
profbval: $(PROFBVALFILE)

$(NORSNETFILE): $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE) $(PROFBVALFILE)
	norsnet $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE) $@ $(JOBID) $(PROFBVALFILE)

.PHONY: norsnet
norsnet: $(NORSNETFILE)

$(METADISORDERFILE): $(FASTAFILE) $(PROFFILE) $(PROFBVALFILE) $(NORSNETFILE) $(HSSPFILTERFILE) $(BLASTCHECKFILE)
	# This line reuses blast files used by other methods as well. On a handful of test cases this and Avner's version (below) gave only a tiny - seemingly insignificant - difference in results.
	metadisorder $(METADISORDERCTRL) fasta=$(FASTAFILE) prof=$(PROFFILE) profbval_raw=$(PROFBVALFILE) norsnet=$(NORSNETFILE) hssp=$(HSSPFILTERFILE) chk=$(BLASTCHECKFILE) out=$@ out_mode=1

.PHONY: metadisorder
metadisorder: $(METADISORDERFILE)

$(HSSPFILE): $(SAFFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq

$(HSSP80FILE): $(SAF80FILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq

$(HSSPFILTERFILE): $(HSSP80FILE)
	$(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@

.PHONY: blastpSwissM8
blastpSwissM8: $(BLASTPSWISSM8)

$(BLASTPSWISSM8): $(FASTAFILE)
	blastall -a $(BLASTCORES) -p blastp -d $(SWISSBLASTDB) -b 1000 -e 100 -m 8 -i $< -o $@

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

$(NLSFILE) $(NLSSUMFILE) $(NLSTRACEFILE): $(FASTAFILE)
	predictnls $(PREDICTNLSCTRL) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) fileTrace=$(NLSTRACEFILE) html=1

.PHONY: predictnls
predictnls: $(NLSFILE) $(NLSSUMFILE)

$(PHDFILE) $(PHDRDBFILE): $(HSSPFILTERFILE)
	$(PROFROOT)embl/phd.pl $(HSSPFILTERFILE) htm exePhd=phd1994 filterHsspMetric=$(PROFROOT)embl/mat/Maxhom_Blosum.metric  exeHtmfil=$(PROFROOT)embl/scr/phd_htmfil.pl \
	 exeHtmtop=$(PROFROOT)embl/scr/phd_htmtop.pl paraSec=$(PROFROOT)embl/para/Para-sec317-may94.com paraAcc=$(PROFROOT)embl/para/Para-exp152x-mar94.com \
	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader \
	fileOutPhd=$(PHDFILE)  fileOutRdb=$(PHDRDBFILE)  fileNotHtm=$(PHDNOTHTMFILE)  \
	optDoHtmref=1  optDoHtmtop=1 optHtmisitMin=0.2 exeCopf=$(LIBRGUTILS)/copf.pl \
	nresPerLineAli=60 exePhd2msf=$(PROFROOT)embl/scr/conv_phd2msf.pl exePhd2dssp=$(PROFROOT)/embl/scr/conv_phd2dssp.pl  exeConvertSeq=convert_seq \
	exeHsspFilter=filter_hssp doCleanTrace=1

#	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader dirOut=$(WORKDIR) dirWork=$(WORKDIR) jobid=$(JOBID) \
.PHONY: phd
phd: $(PHDFILE) $(PHDRDBFILE)

$(PROFFILE): $(HSSPFILTERFILE)
	prof $< both fileRdb=$@ $(if $(DEBUG), 'dbg', ) numresMin=17 nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=.

$(PROF1FILE): $(FASTAFILE)
	prof $< both fileRdb=$@ $(if $(DEBUG), 'dbg', ) numresMin=17 nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=.

.PHONY: prof
prof: $(PROFFILE) $(PROF1FILE)

$(PROFTEXTFILE): $(PROFFILE)
	$(PROFROOT)scr/conv_prof.pl $< fileOut=$@ ascii nohtml nodet nograph

$(ASPFILE): $(PROFFILE)
	profasp $(PROFASPCTRL) -in $< -out $@ -err $@.errASP

.PHONY: profasp
profasp: $(ASPFILE)

# NORS
NORSDIR:= $(HELPERAPPSDIR)
EXE_NORS:= $(NORSDIR)nors.pl
$(NORSFILE) $(NORSSUMFILE): $(FASTAFILE) $(HSSPFILTERFILE) $(PROFFILE) $(PHDRDBFILE) $(COILSFILE)
	# this call may throw warnings on STDERR (like 'wrong parsing coil file?? ctCoils=0') - silence it when we are not in debug mode
	$(EXE_NORS) $(PROFNORSCTRL) -fileSeq $(FASTAFILE) -fileHssp $(HSSPFILTERFILE) \
	-filePhd $(PROFFILE) -filePhdHtm $(PHDRDBFILE) -fileCoils $(COILSFILE) -o $(NORSFILE) -fileSum $(NORSSUMFILE) -html

.PHONY: profnors
profnors: $(NORSFILE) $(NORSSUMFILE)

#PRODOM
$(PRODOMFILE): $(FASTAFILE)
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
	$(LIBRGUTILS)/copf.pl $< formatOut=gcg fileOut=$@

$(BLASTFILE) $(BLASTCHECKFILE) $(BLASTMATFILE): $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	blastpgp -F F -a $(BLASTCORES) -j 3 -b 3000 -e 1 -h 1e-3 -d $(BIG80BLASTDB) -i $< -o $(BLASTFILE) -C $(BLASTCHECKFILE) -Q $(BLASTMATFILE) $(if $(DEBUG), , >&/dev/null)

$(BLASTALIFILE): $(BLASTCHECKFILE) $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	blastpgp -F F -a $(BLASTCORES) -b 1000 -e 1 -d $(BIGBLASTDB) -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE) $(if $(DEBUG), , >&/dev/null)

$(SAFFILE) $(BLASTFILERDB): $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$@ red=100 maxAli=3000 tile=0 fileOutErr=$@.blast2safErr

$(SAF80FILE) $(BLAST80FILERDB): $(BLASTFILE)  $(FASTAFILE)
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLAST80FILERDB) fileOutSaf=$@ red=100 maxAli=3000 tile=0 fileOutErr=$@.blast2safErr

$(FASTAFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=fasta formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq

$(GCGFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=fasta formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq

$(DISULFINDDIR):
	mkdir -p $@

clean:
	rm -rf $(WORKDIR)/*

# Development purposes only remove this target in production
clean-html:
	rm -rf $(WORKDIR)/*.html $(OUTPUTFILE) $(DISULFINDERFILE).html

.PHONY: install
install:
	for f in \
		$(ASPFILE) \
		$(BLASTFILE) $(BLASTALIFILE) $(BLASTMATFILE) $(BLASTFILERDB) $(BLAST80FILERDB) $(BLASTCHECKFILE) \
		$(BLASTPSWISSM8) \
		$(COILSFILE) $(COILSRAWFILE) \
		$(DISISFILE) \
		$(DISULFINDERFILE) \
		$(FASTAFILE) \
		$(GLOBEFILE) \
		$(HMM2PFAM) $(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL) \
		$(HSSPFILE) $(HSSP80FILE) $(HSSPFILTERFILE) \
		$(INFILE) \
		$(ISISFILE) \
		$(LOCTREEANIMALFILE) $(LOCTREEANIMALTXTFILE) $(LOCTREEPLANTFILE) $(LOCTREEPLANTTXTFILE) $(LOCTREEPROKAFILE) $(LOCTREEPROKATXTFILE) \
		$(METADISORDERFILE) \
		$(NLSFILE) $(NLSSUMFILE) \
		$(NORSFILE) $(NORSSUMFILE) \
		$(NORSNETFILE) \
		$(PHDFILE) $(PHDNOTHTMFILE) $(PHDRDBFILE) \
		$(PRODOMFILE) \
		$(PROFTEXTFILE) $(PROFFILE) $(PROF1FILE) \
		$(PROFBVALFILE) \
		$(PROFTMBFILE) \
		$(PROSITEFILE) \
		$(PSICFILE) \
		$(SAFFILE) $(SAF80FILE) \
		$(SEGFILE) $(SEGGCGFILE) \
		$(GCGFILE) \
		$(TMHMMFILE) \
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
