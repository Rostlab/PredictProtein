package      libGenome;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(@fullOrgList getIdList);
@EXPORT_OK = qw(%name_latin_short %name_latin %org2kingdom @euclidClasses14
		@euclidClasses3 @energyClass @infoClass @commClass
		%aa3to1 %aa2mw %aa2flex %aa_pdb 
		aaCompFromList calcMW getSeq pep2hash
		getPepEntry regionOverlap getOverlap);



@fullOrgList=qw ( aerpe arcfu haln1 metac metja metka metmp mettm pyrab 
		  pyrfu pyrho sulso sulto theac thevo
		  agrt5 aquae bacsu biflo borbu brume camje caucr chlpn 
		  chlte chltr cloab clope deira ecoli entfa fusnu geosu
		  haein helpy lacla lepin 
		  lisin lismo mycge mycle mycpn myctu neime oceih
		  pasmu pseae psesm
		  riccn ricpr rhilo rhopa staau straw strco strpy synel syny3 
		  thema trepa ureur vibch xanci xylfa
		  arath caeel drome enccu yeast mouse human
		  hcmva bacaa wolsu schpo yerpe chlcv coxbu pholu
		  clote bacce xancp xanac strmu staep sheon salty
		  borpa borpe haedu 
		  niteu porgi psepu ralso
		  agrtu bachd strag
		  );

%name_latin_short = ( 
		      'aerpe' => "A pernix K1",
		      'agrt5' => "A tumefaciens",
		      'agrtu' => "A tumefaciens",
		      'aquae' => "A aeolicus",
		      'arath' => "A thaliana",
		      'arcfu' => "A fulgidus",
		      'bacaa' => "B anthracis_Ames",
		      'bacce' => "B cereus (ATCC 14579)",
		      'bacsu' => "B subtilis",
		      'bachd' => "B halodurans",
		      'biflo' => "B longum",
		      'borpa' => "B parapertussis",
		      'borpe' => "B pertussis",
		      'borbu' => "B burgdorferi",
		      'brume' => "B melitensis",
		      'caeel' => "C elegans",
		      'camje' => "C jejuni",
		      'caucr' => "C crescentus",
		      'chlcv' => "C caviae",
		      'chlpn' => "C pneumoniae",
		      'chlte' => "C tepidum",
		      'chltr' => "C trachomatis",
		      'cloab' => "C acetobutylicum",
		      'clope' => "C perfringens",
		      'clote' => "C tetani",
		      'coxbu' => "C burnetii",
		      'deira' => "D radiodurans",
		      'drome' => "D melanogaster",
		      'ecoli' => "E coli",
		      'enccu' => "E cuniculi",
		      'entfa' => "E faecalis",
		      'fusnu' => "F nucleatum",
		      'geosu' => "G sulfurreducens",
		      'haedu' => "H ducreyi",
		      'haein' => "H influenzae",
		      'haln1' => "H sp. (strain NRC-1)",
		      'hcmva' => "H cytomegalovirus (strain AD169)",
		      'helpy' => "H pylori",
		      'human' => "H sapiens",
		      'lacla' => "L lactis (subsp. lactis)",
		      'lepin' => "L interrogans",
		      'lisin' => "L innocua",
		      'lismo' => "L monocytogenes",
		      'metac' => "M acetivorans",
		      'metja' => "M jannaschii",
		      'metka' => "M kandleri",
		      'metma' => "M mazei",
		      'metmp' => "M maripaludis",
		      'mettm' => "M thermoautotrophicum",
		      'mouse' => "M musculus",
		      'muhv4' => "Murine herpesvirus 68 strain WUMS",
		      'mycge' => "M genitalium",
		      'mycle' => "M leprae",
		      'mycpn' => "M pneumoniae",
		      'myctu' => "M tuberculosis",
		      'niteu' => "N europaea",
		      'neime' => "N meningitidis",
		      'oceih' => "O iheyensis",
		      'pasmu' => "P multocida",
		      'pholu' => "P luminescens",
		      'porgi' => "P gingivalis",
		      'pseae' => "P aeruginosa",
		      'psesm' => "P syringae",
		      'psepu' => "P putida",
		      'pyrab' => "P abyssi",
		      'pyrfu' => "P furiosus",
		      'pyrho' => "P horikoshii",
		      'ralso' => "R solanacearum",
		      'rhilo' => "R loti",
		      'rhime' => "R meliloti",
		      'rhopa' => "R palustris",
		      'riccn' => "R conorii",
		      'ricpr' => "R prowazekii",
		      'rhime' => "R meliloti",
		      'salty' => "S typhimurium LT2",
		      'sheon' => "S oneidensis",
		      'staau' => "S aureus",
		      'staep' => "S epidermidis",
		      'shifl' => "S flexneri",
		      'strag' => "S agalactiae",
		      'straw' => "S avermitilis",
		      'strco' => "S coelicolor",
		      'strmu' => "S mutans",
		      'strpn' => "S pneumoniae",
		      'strpy' => "S pyogenes",
		      'sulso' => "S solfataricus",
		      'sulto' => "S tokodaii",
		      'synel' => "S elongatus",
		      'syny3' => "S PCC6803",
		      'theac' => "T acidophilum",
		      'thema' => "T maritima",
		      'thevo' => "T volcanium",
		      'trepa' => "T pallidum",
		      'ureur' => "U urealyticum",
		      'vibch' => "V cholerae",
		      'wolsu' => "W succinogenes",
		      'schpo' => "S pombe",
		      'xanci' => "X campestris (pv. citri)",
		      'xylfa' => "X fastidiosa",
		      'yeast' => "S cerevisiae",
		      'yerpe' => "Y pestis",
		      'xanac' => "X axonopodis (pv. citri)",
		      'xancp' => "X campestris",
		      );


%name_latin = ( 'aerpe' => "Aeropyrum pernix K1",
		'agrt5' => "Agrobacterium tumefaciens (strain C58 / ATCC 33970)",
		'agrtu' => "Agrobacterium tumefaciens",
		'aquae' => "Aquifex aeolicus",
		'arath' => "Arabidopsis thaliana",
		'arcfu' => "Achaeoglobus fulgidus",
		'bacaa' => "Bacillus anthracis (strain Ames)",
		'bacce' => "Bacillus cereus (ATCC 14579)",
		'bachd' => "Bacillus halodurans",
		'bacsu' => "Bacillus subtilis",
		'biflo' => "Bifidobacterium longum",
		'borpa' => "Bordetella parapertussis",
		'borpe' => "Bordetella pertussis",
		'borbu' => "Borrelia burgdorferi",
		'brume' => "Brucella melitensis",
		'caeel' => "Caenorhabditis elegans",
		'camje' => "Campylobacter jejuni",
		'caucr' => "Caulobacter crescentus",
		'chlcv' => "Chlamydophila caviae",
		'chlpn' => "Chlamydia pneumoniae",
		'chlte' => "Chlorobium tepidum",
		'chltr'	=> "Chlamydia trachomatis",
		'cloab' => "Clostridium acetobutylicum",
		'clope' => "Clostridium perfringens",
		'clote' => "Clostridium tetani",
		'coxbu' => "Coxiella burnetii",
		'deira' => "Deinococcus radiodurans",
		'drome' => "Drosophila melanogaster",
		'ecoli' => "Escherichia coli",
		'enccu' => "Encephalitozoon cuniculi",
		'entfa' => "Enterococcus faecalis",
		'fusnu' => "Fusobacterium nucleatum",
		'geosu' => "Geobacter  sulfurreducens",
		'haedu' => "Haemophilus ducreyi",
		'haein' => "Haemophilus influenzae",
		'haln1' => "Halobacterium sp. (strain NRC-1)",
		'hcmva' => "Human cytomegalovirus (strain AD169)",
		'helpy' => "Helicobacter pylori",
		'human' => "Homo sapiens",
		'lacla' => "Lactococcus lactis (subsp. lactis)",
		'lepin' => "Leptospira interrogans",
		'lisin' => "Listeria innocua",
		'lismo' => "Listeria monocytogenes",
		'metac' => "Methanosarcina acetivorans",
		'metja' => "Methanococcus jannaschii",
		'metka' => "Methanopyrus kandleri",
		'metma' => "Methanosarcina mazei",
		'metmp' => "Methanococcus maripaludis",
		'mettm' => "Methanobacterium thermoautotrophicum",
		'mouse' => "Mus musculus",
		'muhv4' => "Murine herpesvirus 68 strain WUMS",
		'mycge' => "Mycoplasma genitalium",
		'mycpn' => "Mycoplasma pneumoniae",
		'myctu' => "Mycobacterium tuberculosis",
		'mycle' => "Mycobacterium leprae",
		'niteu' => "Nitrosomonas europaea",
		'neime' => "Neisseria meningitidis",
		'oceih' => "Oceanobacillus iheyensis",
		'pasmu' => "Pasteurella multocida",
		'pholu' => "Photorhabdus luminescens",
		'porgi' => "Porphyromonas gingivalis",
		'pseae' => "Pseudomonas aeruginosa",
		'psesm' => "Pseudomonas syringae (pv. tomato)",
		'psepu' => "Pseudomonas putida",
		'pyrab' => "Pyrococcus abyssi",
		'pyrfu' => "Pyrococcus furiosus",
		'pyrho' => "Pyrococcus horikoshii",
		'ralso' => "Ralstonia solanacearum",
		'rhime' => "Rhizobium meliloti",
		'rhopa' => "Rhodopseudomonas palustris",
		'riccn' => "Rickettsia conorii",
		'ricpr' => "Rickettsia prowazekii",
		'rhilo' => "Rhizobium loti",
		'rhime' => "Rhizobium meliloti",
		'salty' => "Salmonella typhimurium LT2",
		'schpo' => "Schizosaccharomyces pombe",
		'sheon' => "Shewanella oneidensis",
		'staep' => "Staphylococcus epidermidis",
		'staau' => "Staphylococcus aureus",
		'shifl' => "Shigella flexneri",
		'strag' => "Streptococcus agalactiae",
		'straw' => "Streptomyces avermitilis",
		'strco' => "Streptomyces coelicolor",
		'strmu' => "Streptococcus mutans",
		'strpn' => "Streptococcus pneumoniae",
		'strpy' => "Streptococcus pyogenes",
		'sulso' => "Sulfolobus solfataricus",
		'sulto' => "Sulfolobus tokodaii",
		'synel' => "Synechococcus elongatus",
		'syny3' => "Synechocystis PCC6803",
		'theac' => "Thermoplasma acidophilum",
		'thema' => "Thermotoga maritima",
		'thevo' => "Thermoplasma volcanium",
		'trepa' => "Treponema pallidum",
		'ureur' => "Ureaplasma urealyticum",
		'vibch' => "Vibrio cholerae",
		'wolsu' => "Wolinella succinogenes",
		'xanac' => "Xanthomonas axonopodis (pv. citri)",
		'xanci' => "Xanthomonas campestris (pv. citri)",
		'xancp' => "Xanthomonas campestris",
		'xylfa' => "Xylella fastidiosa",
		'yeast' => "Saccharomyces cerevisiae",
		'yerpe' => "Yersinia pestis",
		);

%org2kingdom = 
    ('aerpe' => "Archae",
     'arcfu' => "Archae",
     'haln1' => "Archae",
     'metac' => "Archae",
     'metma' => "Archae",
     'metja' => "Archae",
     'metka' => "Archae",
     'metmp' => "Archae",
     'mettm' => "Archae",
     'pyrab' => "Archae",
     'pyrfu' => "Archae",
     'pyrho' => "Archae",
     'sulso' => "Archae",	
     'sulto' => "Archae",
     'theac' => "Archae",
     'thevo' => "Archae",
     'agrt5' => "Prokaryote",
     'agrtu' => "Prokaryote",
     'aquae' => "Prokaryote",
     'bacaa' => "Prokaryote",
     'bacce' => "Prokaryote",
     'bachd' => "Prokaryote",
     'bacsu' => "Prokaryote",
     'biflo' => "Prokaryote",
     'borpa' => "Prokaryote",
     'borpe' => "Prokaryote",
     'borbu' => "Prokaryote",
     'brume' => "Prokaryote",
     'camje' => "Prokaryote",
     'caucr' => "Prokaryote",
     'chlcv' => "Prokaryote",
     'chlpn' => "Prokaryote",
     'chlte' => "Prokaryote",
     'chltr' => "Prokaryote",
     'cloab' => "Prokaryote",
     'clope' => "Prokaryote",
     'clote' => "Prokaryote",
     'coxbu' => "Prokaryote",
     'deira' => "Prokaryote",
     'ecoli' => "Prokaryote",
     'entfa' => "Prokaryote",
     'fusnu' => "Prokaryote",
     'geosu' => "Prokaryote",
     'haedu' => "Prokaryote",
     'haein' => "Prokaryote",
     'helpy' => "Prokaryote",
     'lacla' => "Prokaryote",
     'lepin' => "Prokaryote",
     'lisin' => "Prokaryote",
     'lismo' => "Prokaryote",
     'mycge' => "Prokaryote",
     'mycle' => "Prokaryote",
     'mycpn' => "Prokaryote",
     'myctu' => "Prokaryote",
     'niteu' => "Prokaryote",
     'neime' => "Prokaryote",
     'oceih' => "Prokaryote",
     'pasmu' => "Prokaryote",
     'pholu' => "Prokaryote",
     'porgi' => "Prokaryote",
     'pseae' => "Prokaryote",
     'psepu' => "Prokaryote",
     'psesm' => "Prokaryote",
     'ralso' => "Prokaryote",
     'riccn' => "Prokaryote",
     'ricpr' => "Prokaryote",
     'rhilo' => "Prokaryote",
     'rhopa' => "Prokaryote",
     'shifl' => "Prokaryote",
     'salty' => "Prokaryote",
     'sheon' => "Prokaryote",
     'staep' => "Prokaryote",
     'staau' => "Prokaryote",
     'strag' => "Prokaryote",
     'straw' => "Prokaryote",
     'strco' => "Prokaryote",
     'strmu' => "Prokaryote",
     'strpn' => "Prokaryote",
     'strpy' => "Prokaryote",
     'synel' => "Prokaryote",
     'syny3' => "Prokaryote",
     'thema' => "Prokaryote",
     'trepa' => "Prokaryote",
     'ureur' => "Prokaryote",	
     'vibch' => "Prokaryote",	
     'wolsu' => "Prokaryote",	
     'xanac' => "Prokaryote",
     'xanci' => "Prokaryote",	
     'xancp' => "Prokaryote",
     'xylfa' => "Prokaryote",
     'yerpe' => "Prokaryote",
     'arath' => "Eukaryote",
     'caeel' => "Eukaryote",
     'drome' => "Eukaryote",
     'enccu' => "Eukaryote",
     'yeast' => "Eukaryote",
     'mouse' => "Eukaryote",
     'human' => "Eukaryote",
     'schpo' => "Eukaryote",	
     'hcmva' => "virus",
     'muhv4' => "virus");

@euclidClasses14 = (
		    'Amino acid biosynthesis',
		    'Biosynthesis of cofactors, prosthetic groups, and carriers',
		    'Cell envelope','Cellular processes',
		    'Central intermediary metabolism','Energy metabolism',
		    'Fatty acid and phospholipid metabolism','Other categories',
		    'Purines, pyrimidines, nucleosides, and nucleotides','Regulatory functions',
		    'Replication','Transcription','Translation',
		    'Transport and binding proteins',
		    'Unclassified');

@euclidClasses3 = ( 'Energy', 'Communication','Information',
		'Other categories','Unclassified');

@energyClass = ( 'Amino acid biosynthesis',
		 'Biosynthesis of cofactors, prosthetic groups, and carriers',
		 'Central intermediary metabolism','Energy metabolism',
		 'Energy metabolism',
		 'Fatty acid and phospholipid metabolism',
		 'Purines, pyrimidines, nucleosides, and nucleotides',
		 'Transport and binding proteins');
@infoClass = ( 'Replication','Transcription','Translation');
@commClass = ( 'Cell envelope','Cellular processes','Regulatory functions');



%aa3to1 = 
    ( 'Ala' => 'A',
      'Arg' => 'R',
      'Asn' => 'N',
      'Asp' => 'D',
      'Cys' => 'C',
      'Gln' => 'Q',
      'Glu' => 'E',
      'Gly' => 'G',
      'His' => 'H',
      'Ile' => 'I',
      'Leu' => 'L',
      'Lys' => 'K',
      'Met' => 'M',
      'Phe' => 'F',
      'Pro' => 'P',
      'Ser' => 'S',
      'Thr' => 'T',
      'Trp' => 'W',
      'Tyr' => 'Y',
      'Val' => 'V',
      );


%aa2mw = 
    ( 'A' => 89.09,
      'C' => 121.15,
      'D' => 133.10,
      'E' => 147.13,
      'F' => 165.19,
      'G' => 75.07,
      'H' => 155.16,
      'I' => 131.17,
      'K' => 146.19,
      'L' => 131.17,
      'M' => 149.21,
      'N' => 132.12,
      'P' => 115.13,
      'Q' => 146.15,
      'R' => 174.20,
      'S' => 105.09,
      'T' => 119.12,
      'V' => 117.15,
      'W' => 204.23,
      'Y' => 181.19
      );



#=========================================================
# Vihinen's flexibility index
#
# Normalized flexibility parameters (B-values), average (Vihinen et al., 1994)
# A Vihinen, M., Torkkila, E. and Riikonen, P.
# Accuracy of protein flexibility predictions
# Proteins 19, 141-149 (1994)
#I    A/L     R/K     N/M     D/F     C/P     Q/S     E/T     G/W     H/Y     I/V
#   0.984   1.008   1.048   1.068   0.906   1.037   1.094   1.031   0.950   0.927
#   0.935   1.102   0.952   0.915   1.049   1.046   0.997   0.904   0.929   0.931
%aa2flex =
    ( 'A' => 40,
      'C' => 1,
      'D' => 82,
      'E' => 95,
      'F' => 5,
      'G' => 64,
      'H' => 23,
      'I' => 11,
      'K' => 100,
      'L' => 15,
      'M' => 24,
      'N' => 72,
      'P' => 73,
      'Q' => 67,
      'R' => 52,
      'S' => 71,
      'T' => 46,
      'V' => 13,
      'W' => 0,
      'X' => 50,		# modified unknown aa
      'Y' => 12
      );

%aa_pdb = 
    ('A' => 7.81,
     'C' => 2.23,
     'D' => 5.73,
     'E' => 6.62,
     'F' => 3.87,
     'G' => 7.58,
     'H' => 2.25,
     'I' => 5.31,
     'K' => 6.73,
     'L' => 8.32,
     'M' => 2.11,
     'N' => 4.48,
     'P' => 4.53,
     'Q' => 3.89,
     'R' => 4.89,
     'S' => 6.15,
     'T' => 5.82,
     'V' => 6.75,
     'W' => 1.44,
     'Y' => 3.52
     );


sub aaCompFromList {
#======================================================
# take a fasta list file as input and spit out the aa compostion
# for all the sequences in the list
#=======================================================
    my ( $fileList ) = @_;
    my %aa = ();
    my $errMsg = "";


    my ( @letters, $aa, %isAA, @tmp, $ctTotal );
    if ( ! -e $fileList ) {
	$errMsg .=  "file list $fileList not found, exiting..\n";
	return ({%aa}, 0, $errMsg);
    }

    @letters = qw( A C D E F G H I K L M N P Q R S T V W Y );
    foreach $aa ( @letters ) {
	$isAA{$aa} = 1;
    }


    $ctTotal = 0;
    open (LIST, $fileList) or die "cannot open $fileList:$!";
    while (<LIST>) {
	next if ( /^\s*\>/ );
	s/\s+//g;
	@tmp = split //;
	foreach $aa ( @tmp ) {
	    next if ( ! $isAA{$aa} );
	    $aa{$aa}{'ct'}++;
	    $ctTotal++;
	}
    }
    close LIST;
    
    

    foreach $aa ( @letters ) {
	$aa{$aa}{'freq'} = $aa{$aa}{'ct'}/$ctTotal*100;
    }


    return ( {%aa}, 1, "ok" );
}


sub calcMW {
    my ( $seqRef ) = @_;
    my ( @seq, $seqLen, $mw, $aa );
    
    @seq = split //, uc($$seqRef);
    $seqLen = 0;
    $mw = 0;
    foreach $aa ( @seq ) {
	if ( ! defined $aa2mw{$aa} ) {
	    print STDERR "MW for aa $aa not found, skip..\n";
	    next;
	}
	$seqLen++;
	$mw += $aa2mw{$aa};
    }
				# substract the peptide bond water
    $mw = $mw - 18.015 * ( $seqLen - 1 );
    #$mw = $mw/1000;		# use kDa as unit
    return $mw;
}
	
sub getIdList {
    my $sbr = "getIdList";
    my ( $fileList ) = @_;
    my ( $fhList,$id,@idList );

    return () if ( ! -f $fileList );
    @idList = ();
    $fhList = "LIST_$sbr";
    open ( $fhList, $fileList) or die "cannot open $fileList:$!";
    while (<$fhList>) {
	next if ( $_ !~ /\w+/ );
        next if ( /^\#/ );
	chomp($id=$_);
	$id =~ s/^\s+//g;
        $id =~ s/\s+.*//g;
	$id =~ s/\..*//g;
	push @idList, $id if ( $id );
    }
    close $fhList;
    return [@idList];
}

sub getSeq {
    my $sbr = "getSeq";
    my ( $fileSeq ) = @_;
    my ($seq,$fhSeq);
   
    return "" if ( ! -f $fileSeq );
    $seq = "";
    $fhSeq = "SEQ_$sbr";
    open ($fhSeq,$fileSeq) or die "cannot open $fileSeq:$!";
    while (<$fhSeq>) {
	next if ( /^\s*\>/ );
	s/\W+//g;
	$seq .= $_;
    }
    close $fhSeq;
    return $seq;
}

sub pep2hash {
    my $sbr = "pep2hash";
    my ($filePep,$listId,$listField) = @_;
    my (%data,$id,%id2list,$field,%field2list,$fhPep);
    my ($toRead,$value);


    return undef if ( ! -f $filePep );
    
    undef %data;
    if ( $listId ne 'ALL' ) {
	foreach $id ( @$listId ) {
	    $id2list{$id} = 1;
	}
    }

    if ( $listField ne 'ALL' ) {
	foreach $field ( @$listField ) {
	    $field2list{$field} = 1;
	}
    }

    $fhPep = "PEP_$sbr";
    open ($fhPep,$filePep) or die "cannot open $filePep:$!";
    $toRead = 0;
    while (<$fhPep>) {
	chomp;
	if ( /^\>/ ) {
	    $id = $_;
	    $id =~ s/^\>//;
	    $id =~ s/\s+.*//g;
	    $toRead = ( $listId eq 'ALL' or $id2list{$id} );
	    next;
	}
	if ( /^\/\// ) {
	    $toRead = 0;
	    next;
	}
	    
	next if ( ! $toRead );
	($field,$value) = split /\t+/,$_,2;
	next if ( $listField ne 'ALL' and ! $field2list{$field} );
	if ( $field eq 'SEQ' ) {
	    $value = <$fhPep>;
	    $value =~ s/\W+//g;
	}
	#print "xx id=$id,field=$field\n";
	$data{$id}{$field} = $value;
    }
    close $fhPep;

    return {%data};
}


sub getPepEntry {
    my $sbr = "getPepEntry";
    my ( $org,$id,$type ) = @_;
    my ($dirGenome,$dirOrg,$dirSrs,$fileSrs,$fhSrs,$entry);

    $dirGenome = '/data/genome/';
    $dirOrg = $dirGenome.$org.'/';
    $dirSrs = $dirOrg.'srs/'.substr($id,-1,1).'/';
    $fileSrs = $dirSrs.$id.'/'.$id.".$type";
#    print "xx fileSrs=$fileSrs\n";
    if ( ! -f $fileSrs ) {
	return undef;
    }

    $entry = "";
    $fhSrs = "SRS_$sbr";
    open ($fhSrs,$fileSrs) or die "cannot open $fileSrs:$!";
    while (<$fhSrs>) {
	$entry .= $_;
    }
    close $fhSrs;
    $entry =~ s/\n+$//g;
    return $entry;
}

    
sub regionOverlap {
				# check how much of reg2 is covered by reg1
    my ( $beg1,$end1,$beg2,$end2) = @_;
    my ( $len1,$len2,$i,@seq,$ctOverlap,$overlap1,$overlap2,$min,$max );

    $len2 = $end2-$beg2+1;
    $len1 = $end1-$beg1+1;

    return undef if ( $len2 < 2 or $len1 < 2 );

    if ( $beg1 < $beg2 ) {
	$min = $beg1;
    } else {
	$min = $beg2;
    }
    if ( $end1 > $end2 ) {
	$max = $end1;
    } else {
	$max = $end2;
    }


    for $i ( $beg1..$end1 ) {
	$seq[$i]++;
    }
    for $i ( $beg2..$end2 ) {
	$seq[$i]++;
    }
    
    $ctOverlap = 0;
    for $i ( $min..$max ) {
	$ctOverlap++ if ( $seq[$i] && $seq[$i] == 2 );
    }
    $overlap1 = $ctOverlap/$len1;
    $overlap2 = $ctOverlap/$len2;

    #print "xx $beg1,$end1,$beg2,$end2,$overlap1,$overlap2\n";
    return ($overlap1,$overlap2);
}


sub getOverlap {
    my ( $reg1,$reg2 ) = @_;
    my ( @array,$beg1,$beg2,$beg,$end1,$end2,$end );
    ($beg1,$end1) = split /-/,$reg1;
    ($beg2,$end2) = split /-/,$reg2;
    if ( $beg1 > $beg2 ) {
	$beg = $beg1;
    } else {
	$beg = $beg2;
    }

    if ( $end1 > $end2 ) {
	$end = $end2;
    } else {
	$end = $end1;
    }
    
    if ( $end - $beg > 0 ) {
	return "$beg-$end";
    } else {
	return "";
    }
}


1;









