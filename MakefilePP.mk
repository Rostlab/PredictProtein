#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#	(c) 2010 Laszlo Kajan rostlab
#####################################

JOBID:=$(basename $(notdir $(INFILE)))

DEBUG:=
DESTDIR:=.

DISULFINDDIR:=$(abspath ./disulfinder)/

BLASTCORES := 1
PROFNUMRESMIN := 17

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
PFAM2DB:=/mnt/project/rost_db/data/pfam/Pfam_ls
PFAM3DB:=/mnt/project/rost_db/data/pfam/Pfam-A.hmm
PROSITECONVDAT:=/mnt/project/rost_db/data/prosite/prosite_convert.dat
PSICMAT:=/usr/share/psic/blosum62_psic.txt
SWISSBLASTDB:=/mnt/project/rost_db/data/blast/swiss

# TOOLS (CONFIGURABLE)
HMM2PFAMEXE:=hmm2pfam
HMM3SCANEXE:=hmmscan
NORSPEXE:=norsp
PSICEXE:=/usr/share/rost-runpsic/runNewPSIC.pl

# RESULTS FILES
HSSPFILE:=$(INFILE:%.in=%.hssp)
HSSP80FILE:=$(INFILE:%.in=%.hssp80)
HSSPFILTERFILE:=$(INFILE:%.in=%.hsspPsiFil)
COILSFILE:=$(INFILE:%.in=%.coils)
COILSRAWFILE:=$(INFILE:%.in=%.coils_raw)
NLSFILE:=$(INFILE:%.in=%.nls)
NLSDATFILE:=$(INFILE:%.in=%.nlsDat)
NLSSUMFILE:=$(INFILE:%.in=%.nlsSum)
PHDFILE:=$(INFILE:%.in=%.phdPred)
PHDRDBFILE:=$(INFILE:%.in=%.phdRdb)
# lkajan: never make PHDNOTHTMFILE a target - its creation depends on whether phd found an HTM region or not: it isn't always created
PHDNOTHTMFILE:=$(INFILE:%.in=%.phdNotHtm)
PROFFILE:=$(INFILE:%.in=%.profRdb)
# prof output generated explicitely from one sequence - NO alignment - Chris Schaefer initiated this - B approved
PROF1FILE:=$(INFILE:%.in=%.prof1Rdb)
ASPFILE:=$(INFILE:%.in=%.asp)
NORSFILE:=$(INFILE:%.in=%.nors)
NORSSUMFILE:=$(INFILE:%.in=%.sumNors)
NORSNETFILE:=$(INFILE:%.in=%.norsnet)
PROSITEFILE:=$(INFILE:%.in=%.prosite)
GLOBEFILE:=$(INFILE:%.in=%.globe)
SEGFILE:=$(INFILE:%.in=%.segNorm)
SEGGCGFILE:=$(INFILE:%.in=%.segNormGCG)
# this file is output from the first blastpgp call with 3 iterations
BLASTFILE:=$(INFILE:%.in=%.blastPsiOutTmp)
BLASTCHECKFILE:=$(INFILE:%.in=%.chk)
# as of 20110415 Guy says the following IS needed by the web interface
BLASTFILERDB:=$(INFILE:%.in=%.blastPsiRdb)
# as of 20110415 Guy says the following is NOT needed by the web interface
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
ISISFILE:=$(INFILE:%.in=%.isis)
DISISFILE:=$(INFILE:%.in=%.disis)
PPFILE:=$(INFILE:%.in=%.predictprotein)
TMHMMFILE:=$(INFILE:%.in=%.tmhmm)

DISULFINDERCTRL :=
LOWCOMPSEGCTRL := "NOT APPLICABLE"
METADISORDERCTRL :=
NORSNETCTRL := "NOT APPLICABLE"
NORSPCTRL := --win=70 --secCut=12 --accLen=10
PREDICTNLSCTRL :=
PROFCTRL := "NOT APPLICABLE"
PROFASPCTRL := --ws=5 --z=-1.75 --min=9
PROFBVALCTRL := "NOT APPLICABLE"
PROFDISISCTRL :=
PROFGLOBECTRL :=
PROFISISCTRL :=
PROFTMBCTRL :=

# lkajan: This target 'all' does NOT invoke all the methods! It only invokes the 'standard' methods: those that are available through hard Debian dependencies.
# lkajan: So 'optional' targets are NOT included since these are not guaranteed to work.
.PHONY: all
all:  $(FASTAFILE) $(GCGFILE) $(SEGGCGFILE) disorder function html interaction lowcompseg pfam profglobe sec-struct subcell-loc

.PHONY: disorder
disorder: metadisorder norsnet profasp profbval norsp

.PHONY: function
function: disulfinder predictnls prosite

.PHONY: html
html: $(BLASTFILERDB) $(HSSPFILE) $(SAFFILE)

.PHONY: interaction
interaction: profisis

.PHONY: pfam
pfam: hmm2pfam hmm3pfam

.PHONY: sec-struct
sec-struct: $(PROFTEXTFILE) coiledcoils phd prof proftmb

.PHONY: subcell-loc
subcell-loc:

# optional: these targets may not work in case the packages that provide them are missing - these packages are not hard requirements of PP
#           These packages are usually non-redistributable or have some other problem with them.
#           loctree depends on SignalP that is non-redistributable
#           The license of psic is unknown, it depends (through runNewPSIC.pl) on clustalw, clustalw is usable for non-commercial purposes only
#           tmhmm is non-redistributable
.PHONY: optional
optional: loctree profdisis psic tmhmm

.PHONY: coiledcoils
coiledcoils: $(COILSFILE)

.PHONY: loctree
loctree: $(LOCTREEANIMALFILE) $(LOCTREEANIMALTXTFILE) $(LOCTREEPLANTFILE) $(LOCTREEPLANTTXTFILE) $(LOCTREEPROKAFILE) $(LOCTREEPROKATXTFILE)

.PHONY: psic
psic: $(PSICFILE) $(CLUSTALNGZ)

# lkajan: rules that make multiple targets HAVE TO be expressed with %
%.loctreeAnimal %.loctreeAnimalTxt : $(FASTAFILE) $(BLASTPSWISSM8) $(HMM2PFAM) $(HSSPFILTERFILE) $(PROFFILE)
	loctree --fasta $(FASTAFILE) --loctreeres $(LOCTREEANIMALFILE) --loctreetxt $(LOCTREEANIMALTXTFILE) \
	  --use-blastall $(BLASTPSWISSM8) --use-blastall-names $(JOBID) --use-pfamres $(HMM2PFAM) --use-pfamres-names $(JOBID) --use-hssp-coll $(HSSPFILTERFILE) --use-rdbprof-coll $(PROFFILE) \
	  --org animal \
	  $(if $(DEBUG), --debug, )

%.loctreePlant %.loctreePlantTxt : $(FASTAFILE) $(BLASTPSWISSM8) $(HMM2PFAM) $(HSSPFILTERFILE) $(PROFFILE)
	loctree --fasta $(FASTAFILE) --loctreeres $(LOCTREEPLANTFILE) --loctreetxt $(LOCTREEPLANTTXTFILE) \
	  --use-blastall $(BLASTPSWISSM8) --use-blastall-names $(JOBID) --use-pfamres $(HMM2PFAM) --use-pfamres-names $(JOBID) --use-hssp-coll $(HSSPFILTERFILE) --use-rdbprof-coll $(PROFFILE) \
	  --org plant \
	  $(if $(DEBUG), --debug, )

%.loctreeProka %.loctreeProkaTxt : $(FASTAFILE) $(BLASTPSWISSM8) $(HMM2PFAM) $(HSSPFILTERFILE) $(PROFFILE)
	loctree --fasta $(FASTAFILE) --loctreeres $(LOCTREEPROKAFILE) --loctreetxt $(LOCTREEPROKATXTFILE) \
	  --use-blastall $(BLASTPSWISSM8) --use-blastall-names $(JOBID) --use-pfamres $(HMM2PFAM) --use-pfamres-names $(JOBID) --use-hssp-coll $(HSSPFILTERFILE) --use-rdbprof-coll $(PROFFILE) \
	  --org proka \
	  $(if $(DEBUG), --debug, )

%.psic %.clustalngz : $(FASTAFILE) $(BLASTFILE)
	# lkajan: Yana's $(PSICEXE) fails when there are no blast hits - catch those conditions
	$(PSICEXE) --use-blastfile $(BLASTFILE) --infile $< $(if $(DEBUG), --debug, ) --quiet --min-seqlen $(PROFNUMRESMIN) --blastdata_uniref $(BIGBLASTDB) --blastpgp_seg_filter F --blastpgp_processors $(BLASTCORES) --psic_matrix $(PSICMAT) --psicfile $@ --save-clustaln $(CLUSTALNGZ) --gzip-clustaln; \
	RETVAL=$$?; \
	case "$$RETVAL" in \
	  253) echo "blastpgp: No hits found" > $(PSICFILE); ;; \
	  254) echo "sequence too short" > $(PSICFILE); ;; \
	  *) exit $$RETVAL; ;; \
	esac

.PHONY: hmm2pfam
hmm2pfam: $(HMM2PFAM)

$(HMM2PFAM): $(FASTAFILE)
	$(HMM2PFAMEXE) --cpu $(BLASTCORES) --acc --cut_ga $(PFAM2DB) $< > $@

%.hmm3pfam %.hmm3pfamTbl %.hmm3pfamDomTbl : $(FASTAFILE)
	$(HMM3SCANEXE) --cpu $(BLASTCORES) --acc --cut_ga --notextw --tblout $(HMM3PFAMTBL) --domtblout $(HMM3PFAMDOMTBL) -o $(HMM3PFAM) $(PFAM3DB) $<

.PHONY: hmm3pfam
hmm3pfam: $(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL)

.PHONY: tmhmm
tmhmm: $(TMHMMFILE)

$(TMHMMFILE): $(FASTAFILE)
	WD=$$(mktemp -d) && trap "rm -rf '$$WD'" EXIT; cd $$WD && tmhmm --nohtml --noplot $< > $@

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

%.profbval %.profb4snap : $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE)
	profbval $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE) $(PROFBVALFILE),$(PROFB4SNAPFILE) 1 5,snap $(DEBUG)

.PHONY: profbval
profbval: $(PROFBVALFILE) $(PROFB4SNAPFILE)

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
	# lkajan: we have to switch off filtering (default for blastpgp) or sequences like ASDSADADASDASDASDSADASA fail with
	# 'WARNING: query: Could not calculate ungapped Karlin-Altschul parameters due to an invalid query sequence or its translation. Please verify the query sequence(s) and/or filtering options'
	# Does switching off filtering hurt us? Loctree uses the results of this for extracting keywords from swissprot, so I am not worried.
	# This blast call also often writes 'Selenocysteine (U) at position 59 replaced by X' - we are not really interested. Silence this in non-debug mode.
	blastall -F F -a $(BLASTCORES) -p blastp -d $(SWISSBLASTDB) -b 1000 -e 100 -m 8 -i $< -o $@ $(if $(DEBUG), , >/dev/null 2>&1)

$(GLOBEFILE) : $(PROFFILE) 
	profglobe $(PROFGLOBECTRL) --prof_file $<  --output_file $@

.PHONY: profglobe
profglobe: $(GLOBEFILE)

%.coils %.coils_raw : $(FASTAFILE)
	coils-wrap.pl -m MTIDK -i $< -o $(COILSFILE) -r $(COILSRAWFILE)

$(DISULFINDERFILE): $(BLASTMATFILE) | $(DISULFINDDIR)
	# lkajan: disulfinder now is talkative on STDERR showing progress - silence it when not DEBUG
	disulfinder $(DISULFINDERCTRL) -a 1 -p $<  -o $(DISULFINDDIR) -r $(DISULFINDDIR) -F html $(if $(DEBUG), , >/dev/null 2>&1) && \cp -a $(DISULFINDDIR)/$(notdir $<) $@

.PHONY: disulfinder
disulfinder: $(DISULFINDERFILE)

%.nls %.nlsDat %.nlsSum : %.fasta
	predictnls $(PREDICTNLSCTRL) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) html=1 nlsdat=$(NLSDATFILE)

.PHONY: predictnls
predictnls: $(NLSFILE) $(NLSDATFILE) $(NLSSUMFILE)

%.phdPred %.phdRdb : $(HSSPFILTERFILE)
	$(PROFROOT)embl/phd.pl $(HSSPFILTERFILE) htm exePhd=phd1994 filterHsspMetric=$(PROFROOT)embl/mat/Maxhom_Blosum.metric  exeHtmfil=$(PROFROOT)embl/scr/phd_htmfil.pl \
	 exeHtmtop=$(PROFROOT)embl/scr/phd_htmtop.pl paraSec=$(PROFROOT)embl/para/Para-sec317-may94.com paraAcc=$(PROFROOT)embl/para/Para-exp152x-mar94.com \
	paraHtm=$(PROFROOT)embl/para/Para-htm69-aug94.com user=phd noPhdHeader \
	fileOutPhd=$(PHDFILE)  fileOutRdb=$(PHDRDBFILE)  fileNotHtm=$(PHDNOTHTMFILE)  \
	optDoHtmref=1  optDoHtmtop=1 optHtmisitMin=0.2 exeCopf=$(LIBRGUTILS)/copf.pl \
	nresPerLineAli=60 exePhd2msf=$(PROFROOT)embl/scr/conv_phd2msf.pl exePhd2dssp=$(PROFROOT)/embl/scr/conv_phd2dssp.pl  exeConvertSeq=convert_seq \
	exeHsspFilter=filter_hssp doCleanTrace=1

.PHONY: phd
phd: $(PHDFILE) $(PHDRDBFILE)

$(PROFFILE): $(HSSPFILTERFILE)
	prof $< both fileRdb=$@ $(if $(DEBUG), 'dbg', ) numresMin=$(PROFNUMRESMIN) nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=.

$(PROF1FILE): $(FASTAFILE)
	prof $< both fileRdb=$@ $(if $(DEBUG), 'dbg', ) numresMin=$(PROFNUMRESMIN) nresPerLineAli=60 riSubSec=4 riSubAcc=3 riSubSym=.

.PHONY: prof
prof: $(PROFFILE) $(PROF1FILE)

$(PROFTEXTFILE): $(PROFFILE)
	$(PROFROOT)scr/conv_prof.pl $< fileOut=$@ ascii nohtml nodet nograph

$(ASPFILE): $(PROFFILE)
	profasp $(PROFASPCTRL) -in $< -out $@ -err $@.errASP

.PHONY: profasp
profasp: $(ASPFILE)

# NORSp
%.nors %.sumNors : $(FASTAFILE) $(HSSPFILTERFILE) $(PROFFILE) $(PHDRDBFILE) $(COILSFILE)
	# this call may throw warnings on STDERR (like 'wrong parsing coil file?? ctCoils=0') - silence it when we are not in debug mode
	$(NORSPEXE) $(NORSPCTRL) -fileSeq $(FASTAFILE) -fileHssp $(HSSPFILTERFILE) \
	-filePhd $(PROFFILE) -filePhdHtm $(PHDRDBFILE) -fileCoils $(COILSFILE) -o $(NORSFILE) -fileSum $(NORSSUMFILE) -html

.PHONY: norsp
norsp: $(NORSFILE) $(NORSSUMFILE)

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

%.blastPsiOutTmp %.chk %.blastPsiMat : $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	blastpgp -F F -a $(BLASTCORES) -j 3 -b 3000 -e 1 -h 1e-3 -d $(BIG80BLASTDB) -i $< -o $(BLASTFILE) -C $(BLASTCHECKFILE) -Q $(BLASTMATFILE) $(if $(DEBUG), , >/dev/null 2>&1)

$(BLASTALIFILE): $(BLASTCHECKFILE) $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	blastpgp -F F -a $(BLASTCORES) -b 1000 -e 1 -d $(BIGBLASTDB) -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE) $(if $(DEBUG), , >/dev/null 2>&1)

%.safBlastPsi %.blastPsiRdb : $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$(SAFFILE) red=100 maxAli=3000 tile=0 fileOutErr=$(SAFFILE).blast2safErr

%.safBlastPsi80 %.blastPsi80Rdb : $(BLASTFILE)  $(FASTAFILE)
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLAST80FILERDB) fileOutSaf=$(SAF80FILE) red=100 maxAli=3000 tile=0 fileOutErr=$(SAF80FILE).blast2safErr

$(FASTAFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=fasta formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq

$(GCGFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=fasta formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq

$(DISULFINDDIR):
	mkdir -p $@

clean:
	rm -rf ./*

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
		$(PROFTEXTFILE) $(PROFFILE) $(PROF1FILE) \
		$(PROFBVALFILE) \
		$(PROFTMBFILE) \
		$(PROSITEFILE) \
		$(PSICFILE) $(CLUSTALNGZ) \
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
	@echo "install - copy results to DESTDIR"
	@echo
	@echo "disorder - run disorder predictors"
	@echo "function - function prediction"
	@echo "interaction - run binding site predictors"
	@echo "pfam"
	@echo "profbval"
	@echo "psic"
	@echo "sec-struct - secondary structure prediction"
	@echo
	@echo "optional - optional targets available when respective packages are"
	@echo "  installed"
	@echo
	@echo "help - this message"
	@echo
	@echo "Variables:"
	@echo "BLASTCORES - default: 1"
	@echo "DESTDIR - result files are copied here on 'install'"

# vim:ai:
