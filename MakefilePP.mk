#####################################
#	PREDICTPROTEIN PIPELINE
#
#	(c) 2010 Guy Yachdav rostlab
#	(c) 2010 Laszlo Kajan rostlab
#####################################

JOBID:=$(basename $(notdir $(INFILE)))

DEBUG:=
export DESTDIR:=.

# These temporary directories are automatically removed after use
DISULFINDDIR:=$(shell mktemp -d)
TMHMMDIR:=$(shell mktemp -d)
CONSURFDIR:=$(shell mktemp -d)

BLASTCORES := 1
PROFNUMRESMIN := 17

# FOLDER LOCATION (CONFIGURABLE)
PPROOT:=/usr/share/predictprotein
HELPERAPPSDIR:=$(PPROOT)/helper_apps/
LIBRGUTILS:=/usr/share/librg-utils-perl/
PROFROOT:=/usr/share/profphd/prof/

# DATA (CONFIGURABLE)
BIGBLASTDB:=/mnt/project/rost_db/data/blast/big
BIG80BLASTDB:=/mnt/project/rost_db/data/blast/big_80
DBSWISS:=/mnt/project/rost_db/data/swissprot/current/
PFAM2DB:=/mnt/project/rost_db/data/pfam/Pfam_ls
PFAM3DB:=/mnt/project/rost_db/data/pfam/Pfam-A.hmm
PROSITEDAT:=/mnt/project/rost_db/data/prosite/prosite.dat
PROSITECONVDAT:=/mnt/project/rost_db/data/prosite/prosite_convert.dat
PSICMAT:=/usr/share/psic/blosum62_psic.txt
SPKEYIDX:=/mnt/project/rost_db/data/swissprot/keyindex_loctree.txt
SWISSBLASTDB:=/mnt/project/rost_db/data/blast/swiss

# TOOLS (CONFIGURABLE)
HMM2PFAMEXE:=hmm2pfam
HMM3SCANEXE:=hmmscan
NORSPEXE:=norsp
PSICEXE:=/usr/share/rost-runpsic/runNewPSIC.pl

# RESULTS FILES
HSSPFILE:=$(INFILE:%.in=%.hssp)
HSSP80FILE:=$(INFILE:%.in=%.hssp80)
HSSPFILTERFILENZ:=$(INFILE:%.in=%.hsspPsiFil.nz)
HSSPFILTERFILEGZ:=$(INFILE:%.in=%.hsspPsiFil.gz)
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
# lkajan: 20120816: profasp is now removed (https://rostlab.org/bugzilla3/show_bug.cgi?id=154)
ASPFILE:=$(INFILE:%.in=%.asp)
NORSFILE:=$(INFILE:%.in=%.nors)
NORSSUMFILE:=$(INFILE:%.in=%.sumNors)
NORSNETFILE:=$(INFILE:%.in=%.norsnet)
PROSITEFILE:=$(INFILE:%.in=%.prosite)
SEGFILE:=$(INFILE:%.in=%.segNorm)
SEGGCGFILE:=$(INFILE:%.in=%.segNormGCG)
# this file is output from the first blastpgp call with 3 iterations
BLASTFILE:=$(INFILE:%.in=%.blastPsiOutTmp)
BLASTCHECKFILE:=$(INFILE:%.in=%.chk)
# as of 20110415 Guy says the following IS needed by the web interface
BLASTFILERDB:=$(INFILE:%.in=%.blastPsiRdb)
# as of 20110415 Guy says the following is not needed by the web interface
BLAST80FILERDB:=$(INFILE:%.in=%.blastPsi80Rdb)
BLASTPSWISSM8:=$(INFILE:%.in=%.blastpSwissM8)
BLASTMATFILE:=$(INFILE:%.in=%.blastPsiMat)
BLASTALIFILENZ:=$(INFILE:%.in=%.blastPsiAli.nz)
BLASTALIFILEGZ:=$(INFILE:%.in=%.blastPsiAli.gz)
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
PROFB4SNAPFILE:=$(INFILE:%.in=%.profb4snap)
METADISORDERFILE:=$(INFILE:%.in=%.mdisorder)
PROFTEXTFILE:=$(INFILE:%.in=%.profAscii)
# profcon is very slow and it is said not to have much effect on md results - so we do not run it
PROFCONFILE:=$(INFILE:%.in=%.profcon)
PROFTMBFILE:=$(INFILE:%.in=%.proftmb)
PROFTMBDATFILE:=$(INFILE:%.in=%.proftmbdat)
PCCFILE:=$(INFILE:%.in=%.pcc)

# loctree 1 and loctree2 is now deprecated (GY 10/02/2014)
LOCTREE3ARCH:=$(INFILE:%.in=%.arch.lc3)
LOCTREE3BACT:=$(INFILE:%.in=%.bact.lc3)
LOCTREE3EUKA:=$(INFILE:%.in=%.euka.lc3)

CONSURFFILE:=$(INFILE:%.in=%_consurf.grades)
CONSURFFILE_BASENAME:=$(CONSURFFILE)##*/

PSICFILE:=$(INFILE:%.in=%.psic)
CLUSTALNGZ:=$(INFILE:%.in=%.clustalngz)
ISISFILE:=$(INFILE:%.in=%.isis)
DISISFILE:=$(INFILE:%.in=%.disis)
PPFILE:=$(INFILE:%.in=%.predictprotein)
TMHMMFILE:=$(INFILE:%.in=%.tmhmm)
METASTUDENTBPO:=$(INFILE:%.in=%.metastudent.BPO.txt)
METASTUDENTMPO:=$(INFILE:%.in=%.metastudent.MFO.txt)

DISULFINDERCTRL :=
NCBISEGCTRL := "NOT APPLICABLE"
METADISORDERCTRL :=
NORSNETCTRL := "NOT APPLICABLE"
NORSPCTRL := --win=70 --secCut=12 --accLen=10
PREDICTNLSCTRL :=
PROFCTRL := "NOT APPLICABLE"
PROFBVALCTRL := "NOT APPLICABLE"
PROFDISISCTRL :=
PROFISISCTRL :=
PROFTMBCTRL :=

# lkajan: This target 'all' does NOT invoke all the methods! It only invokes the 'standard' methods: those that are available through hard Debian dependencies.
# lkajan: So 'optional' targets are NOT included since these are not guaranteed to work.
# lkajan: List only non-intermediate targets.
.PHONY: all
all:  $(FASTAFILE) $(GCGFILE) $(SEGGCGFILE) blast disorder function go html hssp interaction  ncbi-seg pfam sec-struct subcell-loc

.PHONY: blast
blast: $(BLASTALIFILEGZ) $(BLASTCHECKFILE) $(BLASTMATFILE) $(BLASTPSWISSM8)

.PHONY: disorder
disorder: norsnet profbval norsp

.PHONY: function
function: disulfinder predictnls prosite

.PHONY: hssp
hssp: $(HSSPFILTERFILEGZ)

# lkajan: this target is for files that are solely needed by the web interface
.PHONY: html
html: $(BLASTFILERDB)

.PHONY: interaction
interaction: profisis

.PHONY: go
go: metastudent


.PHONY: pfam
pfam: hmm2pfam hmm3pfam

.PHONY: sec-struct
sec-struct: $(PROFTEXTFILE) coiledcoils phd prof proftmb

.PHONY: subcell-loc
subcell-loc:

# optional: these targets may not work in case the packages that provide them are missing - these packages are not hard requirements of PP
#           These packages are usually non-redistributable or have some other problem with them.
#           loctree depends on SignalP
#           loctree2 contains non-free binary
#           loctree3 contains non-free binary
#           profdisis depends on svm-light5
#
#           psic is non-redistributable
#           SignalP is non-redistributable
#           svm-light5 is non-redistributable but there is an exception for the Rost Lab
#           tmhmm is non-redistributable
#
# Optional targets should never appear in other aggregate targets (such as 'interaction').
.PHONY: optional
optional: loctree3 metadisorder psic tmhmm

.PHONY: coiledcoils
coiledcoils: $(COILSFILE)


.PHONE: consurf
consurf: $(CONSURFFILE)

$(CONSURFFILE): $(FASTAFILE) 
	trap "rm -rf '$(CONSURFDIR)' error.log" EXIT; \
	if ! ( consurf --Seq_File $< --Out_Dir $(CONSURFDIR) -m --quiet $(if $(DEBUG), , >>error.log 2>&1) ); then \
		EXIT=$$?; cat error.log >&2; exit $$EXIT; \
	else \cp -a $(CONSURFDIR)/$(CONSURFFILE_BASENAME) $@; fi

# loctree1 and loctree2 are now deprecated
.PHONY: loctree3
loctree3: $(LOCTREE3ARCH) $(LOCTREE3BACT) $(LOCTREE3EUKA)

.PHONY: psic
psic: $(PSICFILE) $(CLUSTALNGZ)

# lkajan: rules that make multiple targets HAVE TO be expressed with %
$(LOCTREE3ARCH): $(FASTAFILE) $(BLASTMATFILE)
	loctree3 --quiet --domain arch --fasta '$(FASTAFILE)' --blastmat '$(BLASTMATFILE)' --resfile '$@' -a 

$(LOCTREE3BACT): $(FASTAFILE) $(BLASTMATFILE)
	loctree3 --quiet --domain bact --fasta '$(FASTAFILE)' --blastmat '$(BLASTMATFILE)' --resfile '$@' -a

$(LOCTREE3EUKA): $(FASTAFILE) $(BLASTMATFILE)
	loctree3 --quiet --domain euka --fasta '$(FASTAFILE)' --blastmat '$(BLASTMATFILE)' --resfile '$@' -a

.SECONDARY: $(PSICFILE) $(CLUSTALNGZ)
%.psic %.clustalngz : %.fasta %.blastPsiOutTmp
	# lkajan: Yana's $(PSICEXE) fails when there are no blast hits - catch those conditions. Even in those conditions we have to make the targets, preferably in the expected format (compressed for clustalngz).
	# lkajan: there's a blast in here - remove its empty error.log
	trap "rm -f error.log" EXIT; \
	$(PSICEXE) --use-blastfile $*.blastPsiOutTmp --infile $*.fasta $(if $(DEBUG), --debug, ) --quiet --min-seqlen $(PROFNUMRESMIN) --blastdata_uniref $(BIGBLASTDB) --blastpgp_seg_filter F --blastpgp_processors $(BLASTCORES) --psic_matrix $(PSICMAT) --psicfile $(PSICFILE) --save-clustaln '$(CLUSTALNGZ)' --gzip-clustaln; \
	RETVAL=$$?; \
	if [ -s error.log ]; then cat error.log >&2; fi; \
	case "$$RETVAL" in \
	  253) MSG="blastpgp: No hits found"; echo $$MSG > $(PSICFILE); echo $$MSG | gzip -c > $(CLUSTALNGZ) ;; \
	  254) MSG="sequence too short"; echo $$MSG > $(PSICFILE); echo $$MSG | gzip -c > $(CLUSTALNGZ) ;; \
	  *) exit $$RETVAL; ;; \
	esac

.PHONY: hmm2pfam
hmm2pfam: $(HMM2PFAM)

$(HMM2PFAM): $(FASTAFILE)
	$(HMM2PFAMEXE) --cpu $(BLASTCORES) --acc --cut_ga $(PFAM2DB) $< > $@

.SECONDARY: $(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL)
%.hmm3pfam %.hmm3pfamTbl %.hmm3pfamDomTbl : $(FASTAFILE)
	$(HMM3SCANEXE) --cpu $(BLASTCORES) --acc --cut_ga --notextw --tblout $(HMM3PFAMTBL) --domtblout $(HMM3PFAMDOMTBL) -o $(HMM3PFAM) $(PFAM3DB) $<

.PHONY: hmm3pfam
hmm3pfam: $(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL)

.PHONY: tmhmm
tmhmm: $(TMHMMFILE)

$(TMHMMFILE): $(FASTAFILE)
	trap "rm -rf '$(TMHMMDIR)'" EXIT; tmhmm --workdir=$(TMHMMDIR) --nohtml --noplot $< > $@

.PHONY: proftmb
proftmb: $(PROFTMBFILE) $(PROFTMBDATFILE)

.SECONDARY: $(PROFTMBFILE) $(PROFTMBDATFILE)
%.proftmb %.proftmbdat: $(BLASTMATFILE)
	proftmb -d /usr/share/proftmb -a StateRedux4 -b ReduxDecode4 -m StrandStates -z Swiss_Zcurve -x ZCalibration -n bact.comp -c 4 -s Swiss8.arch -t Swiss8.params -w '$(JOBID)' $(PROFTMBCTRL) -q '$<' --outfile-pretty '$(PROFTMBFILE)' --outfile-tab '' --outfile-dat '$(PROFTMBDATFILE)' --quiet

$(ISISFILE): $(FASTAFILE) $(PROFFILE) $(HSSPFILTERFILE)
	profisis $(PROFISISCTRL) --fastafile $(FASTAFILE)  --rdbproffile $(PROFFILE) --hsspfile $(HSSPFILTERFILE)  --outfile $@  

.PHONY: profisis
profisis: $(ISISFILE)

$(DISISFILE): $(PROFFILE) $(HSSPFILTERFILE)
	profdisis $(PROFDISISCTRL) --hsspfile $(HSSPFILTERFILE)  --rdbproffile $(PROFFILE)  --outfile $@

.PHONY: profdisis
profdisis: $(DISISFILE)

.SECONDARY: $(PROFBVALFILE) $(PROFB4SNAPFILE)
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

.INTERMEDIATE: $(HSSPFILE)
$(HSSPFILE): $(SAFFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq

.INTERMEDIATE: $(HSSP80FILE)
$(HSSP80FILE): $(SAF80FILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=saf formatOut=hssp fileOut=$@ exeConvertSeq=convert_seq

.INTERMEDIATE: $(HSSPFILTERFILENZ)
$(HSSPFILTERFILENZ): $(HSSP80FILE)
	$(LIBRGUTILS)/hssp_filter.pl  red=80 $< fileOut=$@

$(HSSPFILTERFILEGZ): $(HSSPFILTERFILENZ)
	gzip -c -6 < '$<' > '$@'

.INTERMEDIATE: $(HSSPFILTERFILE)
$(HSSPFILTERFILE): $(HSSPFILTERFILEGZ)
	gunzip -c < '$<' > '$@'

.PHONY: blastpSwissM8
blastpSwissM8: $(BLASTPSWISSM8)

$(BLASTPSWISSM8): $(FASTAFILE)
	# lkajan: we have to switch off filtering (default for blastpgp) or sequences like ASDSADADASDASDASDSADASA fail with
	# 'WARNING: query: Could not calculate ungapped Karlin-Altschul parameters due to an invalid query sequence or its translation. Please verify the query sequence(s) and/or filtering options'
	# Does switching off filtering hurt us? Loctree uses the results of this for extracting keywords from swissprot, so I am not worried.
	# This blast call also often writes 'Selenocysteine (U) at position 59 replaced by X' - we are not really interested. Silence this in non-debug mode.
	trap "rm -f error.log" EXIT; \
	if ! ( blastall -F F -a $(BLASTCORES) -p blastp -d $(SWISSBLASTDB) -b 1000 -e 100 -m 8 -i $< -o $@ $(if $(DEBUG), , >>error.log 2>&1) ); then \
		EXIT=$$?; cat error.log >&2; exit $$EXIT; \
	fi

.SECONDARY: $(COILSFILE) $(COILSRAWFILE)
%.coils %.coils_raw : $(FASTAFILE)
	coils-wrap -m MTIDK -i $< -o $(COILSFILE) -r $(COILSRAWFILE)

$(DISULFINDERFILE): $(BLASTMATFILE)
	# lkajan: disulfinder now is talkative on STDERR showing progress - silence it when not DEBUG
	trap "rm -rf '$(DISULFINDDIR)' error.log" EXIT; \
	if ! ( disulfinder $(DISULFINDERCTRL) -a 1 -p $<  -o $(DISULFINDDIR) -r $(DISULFINDDIR) -F html $(if $(DEBUG), , >>error.log 2>&1) ); then \
		EXIT=$$?; cat error.log >&2; exit $$EXIT; \
	else \cp -a $(DISULFINDDIR)/$(notdir $<) $@; fi

.PHONY: disulfinder
disulfinder: $(DISULFINDERFILE)

.SECONDARY: $(NLSFILE) $(NLSDATFILE) $(NLSSUMFILE)
%.nls %.nlsDat %.nlsSum : %.fasta
	predictnls $(PREDICTNLSCTRL) fileIn=$< fileOut=$(NLSFILE) fileSummary=$(NLSSUMFILE) html=1 nlsdat=$(NLSDATFILE)

.PHONY: predictnls
predictnls: $(NLSFILE) $(NLSDATFILE) $(NLSSUMFILE)

.SECONDARY: $(PHDFILE) $(PHDRDBFILE)
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
	# conv_prof creates query.profAscii.tmp in case query.profAscii already exists - make sure it does not
	rm -f $(PROFTEXTFILE); $(PROFROOT)scr/conv_prof.pl $< fileOut=$@ ascii nohtml nodet nograph

.PHONY: metastudent
metastudent: $(METASTUDENTBPO) $(METASTUDENTMPO)

.SECONDARY: $(METASTUDENTBPO) $(METASTUDENTMPO)
%.metastudent.BPO.txt %.metastudent.MFO.txt : $(FASTAFILE)
	metastudent -i $(FASTAFILE) -o query.metastudent --silent $(if $(DEBUG), --debug, )


# NORSp
.SECONDARY: $(NORSFILE) $(NORSSUMFILE)
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
	ncbi-seg $< -x > $@

# lkajan: legacy name for ncbi-seg
.PHONY: lowcompseg
lowcompseg: ncbi-seg

.PHONY: ncbi-seg
ncbi-seg: $(SEGFILE)

$(SEGGCGFILE): $(SEGFILE)
	$(LIBRGUTILS)/copf.pl $< formatOut=gcg fileOut=$@

.SECONDARY: $(BLASTCHECKFILE) $(BLASTMATFILE)
%.blastPsiOutTmp %.chk %.blastPsiMat : %.fasta
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode; blastpgp and blastall create a normally 0-sized 'error.log' - remove it
	trap "rm -f error.log" EXIT; \
	if ! ( blastpgp -F F -a $(BLASTCORES) -j 3 -b 3000 -e 1 -h 1e-3 -d $(BIG80BLASTDB) -i $*.fasta -o $*.blastPsiOutTmp -C $*.chk -Q $*.blastPsiMat $(if $(DEBUG), , >>error.log 2>&1) ); then \
		EXIT=$$?; cat error.log >&2; exit $$EXIT; \
	fi

.INTERMEDIATE: $(BLASTALIFILENZ)
$(BLASTALIFILENZ): $(BLASTCHECKFILE) $(FASTAFILE)
	# blast call may throw warnings on STDERR - silence it when we are not in debug mode
	trap "rm -f error.log" EXIT; \
	if ! ( blastpgp -F F -a $(BLASTCORES) -b 1000 -e 1 -d $(BIGBLASTDB) -i $(FASTAFILE) -o $@ -R $(BLASTCHECKFILE) $(if $(DEBUG), , >>error.log 2>&1) ); then \
		EXIT=$$?; cat error.log >&2; exit $$EXIT; \
	fi

$(BLASTALIFILEGZ): $(BLASTALIFILENZ)
	gzip -c -6 < '$<' > '$@'

.INTERMEDIATE: $(BLASTALIFILE)
$(BLASTALIFILE): $(BLASTALIFILEGZ)
	gunzip -c < '$<' > '$@'

.INTERMEDIATE: $(SAFFILE)
.SECONDARY: $(BLASTFILERDB)
%.safBlastPsi %.blastPsiRdb : $(BLASTALIFILE)  $(FASTAFILE)
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$(FASTAFILE)  fileOutRdb=$(BLASTFILERDB) fileOutSaf=$(SAFFILE) red=100 maxAli=3000 tile=0

.INTERMEDIATE: $(SAF80FILE) $(BLAST80FILERDB)
%.safBlastPsi80 %.blastPsi80Rdb : %.blastPsiOutTmp %.fasta
	$(LIBRGUTILS)/blastpgp_to_saf.pl fileInBlast=$< fileInQuery=$*.fasta  fileOutRdb=$*.blastPsi80Rdb fileOutSaf=$*.safBlastPsi80 red=100 maxAli=3000 tile=0

$(FASTAFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=fasta formatOut=fasta fileOut=$@ exeConvertSeq=convert_seq

$(GCGFILE): $(INFILE)
	$(LIBRGUTILS)/copf.pl $< formatIn=fasta formatOut=gcg fileOut=$@ exeConvertSeq=convert_seq

$(DISULFINDDIR):
	mkdir -p $@

# lkajan: list only non-INTERMEDIATE targets here
.PHONY: install
install:
	for f in \
		$(ASPFILE) \
		$(BLASTALIFILEGZ) $(BLASTMATFILE) $(BLASTFILERDB) $(BLASTCHECKFILE) \
		$(BLASTPSWISSM8) \
		$(COILSFILE) $(COILSRAWFILE) \
		$(CONSURFFILE) \
		$(DISISFILE) \
		$(DISULFINDERFILE) \
		$(FASTAFILE) \
		$(HMM2PFAM) $(HMM3PFAM) $(HMM3PFAMTBL) $(HMM3PFAMDOMTBL) \
		$(HSSPFILTERFILEGZ) \
		$(INFILE) \
		$(ISISFILE) \
		$(LOCTREE3ARCH) $(LOCTREE3BACT) $(LOCTREE3EUKA) \
		$(LOCTREE3ARCH).pb $(LOCTREE3BACT).pb $(LOCTREE3EUKA).pb \
		$(METADISORDERFILE) \
		$(METASTUDENTBPO) $(METASTUDENTMPO) \
		$(NLSFILE) $(NLSDATFILE) $(NLSSUMFILE) \
		$(NORSFILE) $(NORSSUMFILE) \
		$(NORSNETFILE) \
		$(PHDFILE) $(PHDNOTHTMFILE) $(PHDRDBFILE) \
		$(PROFTEXTFILE) $(PROFFILE) $(PROF1FILE) \
		$(PROFBVALFILE) $(PROFB4SNAPFILE) \
		$(PROFTMBFILE) $(PROFTMBDATFILE) \
		$(PROSITEFILE) \
		$(PSICFILE) $(CLUSTALNGZ) \
		$(SEGFILE) $(SEGGCGFILE) \
		$(GCGFILE) \
		$(TMHMMFILE) \
	; do if [ -e $$f ]; then cp -a $$f "$$DESTDIR/" ; fi; done

.PHONY: help
help:
	@echo "Targets:"
	@echo "all - default"
	@echo "install - copy results to DESTDIR"
	@echo
	@echo "disorder - run disorder predictors"
	@echo "function - function prediction"
	@echo "go - Gene Ontology terms prediction"
	@echo "interaction - run binding site predictors"
	@echo "pfam, hmm2pfam, hmm3pfam"
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
