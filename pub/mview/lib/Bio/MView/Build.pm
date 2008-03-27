# Copyright (c) 1997-1999  Nigel P. Brown. \$Id: Build.pm,v 1.3 1999/04/28 18:21:06 nbrown Exp $

######################################################################
package Bio::MView::Build;

use Universal;
use Regexps;
use Parse::Stream;
use Bio::MView::Align;
use Bio::MView::Display;
use strict;

use vars qw();

my %Template = 
    (
     'entry'       => undef,   #parse tree ref
     'status'      => undef,   #parse status (undef=stop; otherwise=go)
     'align'       => undef,   #current alignment
     'index2row'   => undef,   #list of aligned rows, from zero
     'uid2row'     => undef,   #hash of aligned rows, by Row->uid
     'ref_row'     => undef,   #reference row ref
     'topn'        => undef,   #show at most top N items
     'show'        => undef,   #actual number of rows to show
     'maxident'    => undef,   #show items with at most maxident %identity 
     'mode'        => undef,   #display format mode
     'ref_id'      => undef,   #reference id for %identity

     'disclist'    => undef,   #discard rows by {num,id,regex}
     'keeplist'    => undef,   #keep rows by {num,id,regex}
     'nopslist'    => undef,   #no-process rows by {num,id,regex}

     'keep_uid'    => undef,   #hashed version of 'keeplist' by Row->uid
     'nops_uid'    => undef,   #hashed version of 'nopslist'  by Row->uid
     'hide_uid'    => undef,   #hashed merge of 'disc/keep/nops/' by Row->uid

     'range'       => undef,   #display lower/upper bounds (sequence numbering)
     'gap'         => undef,   #output sequence gap character
    );

my %Known_Parameter = 
    (
     #name        => [ format,     default ]
     'topn'       => [ '\d+',      0       ],
     'maxident'   => [ $RX_Ureal,  100     ],
     'mode'       => [ '\S+',      'new'   ],
     'ref_id'     => [ '\S+',      0       ],
     'disclist'   => [ [],         []      ],
     'keeplist'   => [ [],         []      ],
     'nopslist'   => [ [],         []      ],
     'range'      => [ [],         []      ],
     'gap'        => [ '\S',       '+'     ],
    );

my %Known_Display_Mode =
    (
     #name
     'new'        => 1,
     'old'        => 1,
     'rdb'        => 1,
     'pearson'    => 1,
     'pir'        => 1,
     'msf'        => 1,
    );

my %Known_HSP_Tiling =
    (
     'all'       => 1,
     'ranked'    => 1,
     'discrete'  => 1,
    );

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    if (@_ < 1) {
	die "${type}::new() missing argument\n";
    }
    my $self = { %Template };

    $self->{'entry'} = shift;

    bless $self, $type;
    $self->initialise_parameters;
    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub print {
    my $self = shift;
    local $_;
    foreach (sort keys %$self) {
	printf "%15s => %s\n", $_, $self->{$_};
    }
    print "\n";
    $self;
}

sub check_display_mode {
    if (defined $_[0]) {
	if (exists $Known_Display_Mode{$_[0]}) {
	    return lc $_[0];
	}
    }
    return map { lc $_ } sort keys %Known_Display_Mode;
}

sub check_hsp_tiling {
    if (defined $_[0]) {
	if (exists $Known_HSP_Tiling{$_[0]}) {
	    return lc $_[0];
	}
    }
    return map { lc $_ } sort keys %Known_HSP_Tiling;
}

sub initialise_parameters {
    my $self = shift;
    my ($p) = (@_, \%Known_Parameter);
    local $_;
    foreach (keys %$p) {
	#warn "initialise_parameters() $_\n";
	if (ref $p->{$_}->[0] eq 'ARRAY') {
	    $self->{$_} = [];
	    next;
	}
	if (ref $p->{$_}->[0] eq 'HASH') {
	    $self->{$_} = {};
	    next;
	}
	$self->{$_} = $p->{$_}->[1];
    }

    #reset how many rows to display
    $self->{'show'}     = $self->{'topn'};

    #generic alignment scheduler
    $self->{'status'}   = 1;

    $self;
}

sub set_parameters {
    my $self = shift;
    my $p = ref $_[0] ? shift : \%Known_Parameter;
    my ($key, $val);
    while ($key = shift) {
	$val = shift;
	if (exists $p->{$key}) {
	    #warn "set_parameters() $key, @{[defined $val ? $val : 'undef']}\n";
	    if (ref $p->{$key}->[0] eq 'ARRAY' and ref $val eq 'ARRAY') {
		$self->{$key} = $val;
		next;
	    }
	    if (ref $p->{$key}->[0] eq 'HASH' and ref $val eq 'HASH') {
		$self->{$key} = $val;
		next;
	    }
	    if (! defined $val) {
		#set default
		$self->{$key} = $p->{$key}->[1];
		next;
	    }
	    if ($val =~ /^$p->{$key}->[0]$/) {
		#matches expected format
		$self->{$key} = $val;
		next;
	    }
	    warn "${self}::set_parameters() bad value for '$key', got '$val', wanted '$p->{$key}->[0]'\n";
	}
	#ignore unrecognised parameters which may be recognised by subclass
	#set_parameters() methods.
    }

    #always reset when new parameters are given
    $self->{'status'} = 1;

    $self;
}

sub use_row { die "$_[0] use_row() virtual method called\n" }

#map an identifier supplied as {0..N|query|M.N} to a list of row objects in
#$self->{'index2row'}
sub map_id {
    my ($self, $ref) = @_;
    my ($i, @rowref) = ();

    #warn "map_id($ref)\n";

    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	
	#major row number = query
	if ($ref =~ /^0$/) {
	    if ($self->{'index2row'}->[$i]->num eq '' or
		$self->{'index2row'}->[$i]->num eq $ref) {
		push @rowref, $self->{'index2row'}->[$i];
	    }
	    next;
	}
	
	#major row number
	if ($ref =~ /^\d+$/) {
	    #exact match
	    if ($self->{'index2row'}->[$i]->num eq $ref) {
		push @rowref, $self->{'index2row'}->[$i];
		next;
	    }
	    #match to major.minor prefix
	    if ($self->{'index2row'}->[$i]->num =~ /^$ref\./) {
		push @rowref, $self->{'index2row'}->[$i];
		next;
	    }
	    next;
	}
	
	#major.minor row number
	if ($ref =~ /^\d+\.\d+$/) {
	    if ($self->{'index2row'}->[$i]->num eq $ref) {
		push @rowref, $self->{'index2row'}->[$i];
	    }
	    next;
	}
	
	#string identifier
	if ($ref eq $self->{'index2row'}->[$i]->rid or 
	    $ref eq $self->{'index2row'}->[$i]->cid) {
	    push @rowref, $self->{'index2row'}->[$i];
	    next;
	}
	
	#regex inside // pair, applied case-insensitive
	if ($ref =~ /^\/.*\/$/) {
	    my $r = $ref;
	    $r =~ s/^\///; $r =~ s/\/$//;
	    if ($self->{'index2row'}->[$i]->cid =~ /$r/i) {
		#warn "map_id: [$i] /$r/ @{[$self->{'index2row'}->[$i]->cid]}\n";
		push @rowref, $self->{'index2row'}->[$i];
	    }
	    next;
	}
    }
    #warn "${self}::map_id (@rowref)\n";
    return @rowref;
}

sub get_entry { $_[0]->{'entry'} }

sub get_row_id {
    my ($self, $id) = @_;
    if (defined $id) {
	my @id = $self->map_id($id);
	return undef    unless @id;
	return $id[0]->uid    unless wantarray;
	return map { $_->uid } @id;
    }
    return undef;
}

#construct a header string describing this alignment
sub header {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    if (defined $self->{'ref_row'}) {
	$s .= "Identities computed with respect to: ";
	if ($self->{'ref_row'}->num !~ /^\s*$/) {
	    $s .= "(" . $self->{'ref_row'}->num . ") ";
	} else {
	    $s .= "(query) ";
	}
	$s .= $self->{'ref_row'}->cid . "\n";
    }
    if ($self->{'maxident'} < 100) {
	$s .= "Maximum pairwise identity: $self->{'maxident'}%\n";
    }
    if ($self->{'topn'}) {
	$s .= "Maximum sequences to show: $self->{'topn'}\n";
    }
    Bio::MView::Display::displaytext($s);
}

sub subheader {''}

#generic one-pass scheduler for parsers. subclasses can override with more
#sophisticated parsers allowing reentry of their parse() method to extract
#different alignment subsets.
sub schedule {
    if (defined $_[0]->{'status'}) {
	$_[0]->{'status'} = undef;
	return 1;
    }
    $_[0]->{'status'};
}

#return the next alignment, or undef if no more work, or zero if the 
#alignment is empty.
sub next {
    my $self = shift;

    #drop old data structures: GC *before* next assignment!
    $self->{'align'} = $self->{'index2row'} = undef;
    
    #extract an array of aligned row objects
    $self->{'index2row'} = $self->parse;
    #Universal::vmstat("Build->next(parse) done");

    #finished?  note: "$self->{'align'}->free" is not needed
    return undef  unless defined $self->{'index2row'};

#   my $i; for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
#	warn "[$i]  ", $self->{'index2row'}->[$i]->num, " ",
#	$self->{'index2row'}->[$i]->cid, "\n";
#   }

    #maybe more data but this alignment empty? (disc/keep+subclass filtered)
    return 0  unless @{$self->{'index2row'}};

    $self->{'align'} = $self->build_alignment;
    #Universal::vmstat("Build->next(build_alignment) done");

    #maybe more data but this alignment empty? (identity filtered)
    return 0  unless defined $self->{'align'};

    return $self->{'align'};
}

sub build_alignment {
    my $self = shift;

    $self->build_indices;
    $self->build_rows;

    my $ali = $self->build_base_alignment;

    return undef  unless $ali->rows;

SWITCH: {

	if ($self->{'mode'} eq 'new') {
	    $ali = $self->build_new_alignment($ali);
	    last;
	}
    
	if ($self->{'mode'} eq 'old') {
	    if (defined $self->{'ref_row'}) {
		$ali = $self->build_old_alignment($ali)
	    } else {
		#there won't be any identity rows!
		$ali = $self->build_new_alignment($ali);
	    }
	    last;
	}
	
	last    if $self->{'mode'} eq 'none';
	last    if $self->{'mode'} eq 'rdb';
	last    if $self->{'mode'} eq 'pearson';
	last    if $self->{'mode'} eq 'pir';
	last    if $self->{'mode'} eq 'msf';
    
	die "${self}::alignment() unknown mode '$self->{'mode'}'\n";
    }

    $ali;
}

sub build_indices {
    my $self = shift;
    my ($i, $r, @id);

    $self->{'uid2row'}  = {};
    $self->{'keep_uid'} = {};
    $self->{'hide_uid'} = {};
    $self->{'nops_uid'} = {};

    #index the row objects by unique 'uid' for fast lookup.
    foreach $i (@{$self->{'index2row'}}) {
	$self->{'uid2row'}->{$i->uid} = $i;
    }
    
    #get the reference row handle, if any
    if (@id = $self->map_id($self->{'ref_id'})) {
	$self->{'ref_row'} = $id[0];
    }

    #make all disclist rows invisible; this has to be done because some
    #may not really have been discarded at all, eg., reference row.
    foreach $i (@{$self->{'disclist'}}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'hide_uid'}->{$r->uid} = 1;           #invisible
	}
    }

    #hash the keeplist and make all keeplist rows visible again
    foreach $i (@{$self->{'keeplist'}}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'keep_uid'}->{$r->uid} = 1;
	    delete $self->{'hide_uid'}->{$r->uid}  if
		exists $self->{'hide_uid'}->{$r->uid};    #visible
	}
    }

    #hash the reference row on the keeplist. don't override
    #any previous invisibility set by discard list.
    $self->{'keep_uid'}->{$self->{'ref_row'}->uid} = 1
	if defined $self->{'ref_row'};
    
    #hash the nopslist: the 'uid' key is used so that the
    #underlying Align class can recognise rows. don't override any previous
    #visibility set by discard list.
    foreach $i (@{$self->{'nopslist'}}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'nops_uid'}->{$r->uid}  = 1;
	}
    }
    #warn "ref:  ",$self->{'ref_row'}->uid, "\n" if defined $self->{'ref_row'};
    #warn "keep: [", join(",", sort keys %{$self->{'keep_uid'}}), "]\n";
    #warn "nops: [", join(",", sort keys %{$self->{'nops_uid'}}), "]\n";
    #warn "hide: [", join(",", sort keys %{$self->{'hide_uid'}}), "]\n";

    $self;
}

sub build_rows {
    my $self = shift;
    my ($lo, $hi, $i);

    #first, compute alignment length from query sequence in row[0]
    ($lo, $hi) = $self->set_range($self->{'index2row'}->[0]);

    #warn "range ($lo, $hi)\n";
       
    #assemble sparse sequence strings for all rows
    for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
	$self->{'index2row'}->[$i]->assemble($lo, $hi, $self->{'gap'});
    }
    $self;
}

sub set_range {
    my ($self, $row) = @_;

    my ($lo, $hi) = $row->range;

    if (@{$self->{'range'}} and @{$self->{'range'}} % 2 < 1) {
	if ($self->{'range'}->[0] < $self->{'range'}->[1]) {
	    ($lo, $hi) = ($self->{'range'}->[0], $self->{'range'}->[1]);
	} else {
	    ($lo, $hi) = ($self->{'range'}->[1], $self->{'range'}->[0]);
	}
    }
    ($lo, $hi);
}

sub build_base_alignment {
    my $self = shift;
    my ($i, $row, $ali, @list) = ();
	
    for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
	$row = $self->{'index2row'}->[$i];
	$row = new Bio::MView::Align::String($row->uid, $row->sob);
	push @list, $row;
    }

    $ali = new Bio::MView::Align(\@list);
    $ali->set_parameters('nopshash' => $self->{'nops_uid'},
			 'hidehash' => $self->{'hide_uid'});

    #filter alignment based on pairwise %identity, if requested
    if ($self->{'maxident'} < 100) {
	$ali = $ali->prune_all_identities_gt($self->{'maxident'},
					     $self->{'show'},
					     keys %{$self->{'keep_uid'}});
    }
    
    $ali;
}

sub build_new_alignment {
    my ($self, $ali) = @_;
    my ($i, $mrow, $arow);

    $ali->set_identity($self->{'ref_row'}->uid)  if defined $self->{'ref_row'};

    for ($i=0; $i < @{$self->{'index2row'}}; $i++) {

	$mrow = $self->{'index2row'}->[$i];

	if ($arow = $ali->item($mrow->uid)) {

	    next  if exists $self->{'hide_uid'}->{$mrow->uid};

	    if (exists $self->{'nops_uid'}->{$mrow->uid}) {
		$arow->set_display('label0' => '',
				   'label1' => $mrow->cid,
				   'label2' => $mrow->text,
				   'label3' => '',
				   'label4' => '',
				   'url'    => $mrow->url,
				  );
	    } else {
		$arow->set_display('label0' => $mrow->num,
				   'label1' => $mrow->cid,
				   'label2' => $mrow->text,
				   'label3' => $mrow->data,
				   'url'    => $mrow->url,
				  );
	    }
	}
    }

    $ali;
}

sub build_old_alignment {
    my ($self, $ali) = @_;
    my ($i, $mrow, $irow, $arow);

    #third arg=1 => order rows by identity then sequence
    $ali = $ali->add_identity_rows($self->{'ref_row'}->uid, 1)
	if defined $self->{'ref_row'};

    $ali->reset;

    while ($irow = $ali->next) {

	#initialise the query row as number 1
	if ($irow->id eq $self->{'index2row'}->[0]->uid) {

	    $mrow = $self->{'uid2row'}->{$irow->id};

	    if (exists $self->{'nops_uid'}->{$irow->id}) {
		$irow->set_display('label0' => '',
				   'label1' => $mrow->cid,
				   'label2' => $mrow->text,
				   'label3' => '',
				   'label4' => 'Query:',
				   'url'    => $mrow->url,
				  );
	    } else {
		$irow->set_display('label0' => 1,
				   'label1' => $mrow->cid,
				   'label2' => $mrow->text,
				   'label3' => '',
				   'label4' => 'Query:',
				   'url'    => $mrow->url,
				  );
	    }
	    next;
	}

	#nops rows get simpler labelling
	if (exists $self->{'nops_uid'}->{$irow->id}) {

	    $mrow = $self->{'uid2row'}->{$irow->id};

	    $irow->set_display('label0' => '',
			       'label1' => $mrow->cid,
			       'label2' => $mrow->text,
			       'label3' => '',
			       'label4' => '',
			       'url'    => $mrow->url,
			      );    
	    next;
	}

	#remove the identity row for the query
	if ($irow->get_parentid eq $self->{'index2row'}->[0]->uid) {
	    $ali->delete($irow->id);
	    next;
	}

	#all remaining rows: {identity,sequence} processed in pairs
	$arow = $ali->next;

	if (exists $self->{'uid2row'}->{$arow->id}) {
	    
	    $mrow = $self->{'uid2row'}->{$arow->id};
	    
	    $i = $mrow->num;
	    $i++    if ref($self) =~ /search/i;
	    
	    $irow->set_display('label0' => $i,
			       'label1' => '',
			       'label2' => '',
			       'label3' => '',
			      );


	    $arow->set_display('label0' => $i,
			       'label1' => $mrow->cid,
			       'label2' => $mrow->text,
			       'label3' => $mrow->data,
			       'url'    => $mrow->url,
			      );
	    next;
	}

	die "${self}::build_old_alignment() mixed up row problem\n";
    }

    $ali;
}

#remove query and hit columns at gaps in the query sequence and downcase
#the bounding hit symbols in the hit sequence thus affected.
sub strip_query_gaps {
    my ($self, $query, $sbjct) = @_;
    my $i;

    #warn "sqg(in  q)=[$$query]\n";
    #warn "sqg(in  h)=[$$sbjct]\n";

    #no gaps in query
    return    if index($$query, '-') < 0;
    
    #iterate over query frag symbols
    while ( ($i = index($$query, '-')) >= 0 ) {
	
	#downcase preceding symbol in hit
	if (defined substr($$query, $i-1, 1)) {
	    substr($$sbjct, $i-1, 1) = lc substr($$sbjct, $i-1, 1);
	}
	
	#consume gap symbols in query and hit
	while (substr($$query, $i, 1) eq '-') {
	    substr($$query, $i, 1) = "";
	    substr($$sbjct, $i, 1) = "";
	}
	
	#downcase succeding symbol in hit
	if (defined substr($$query, $i, 1)) {
	    substr($$sbjct, $i, 1) = lc substr($$sbjct, $i, 1);
	}
	
	#warn "sqg(out q)=[$$query]\n";
	#warn "sqg(out h)=[$$sbjct]\n";
    }
    $self;
}

#given a ref to a list of parse() hits, remove any that have no positional
#data, finally removing the query itself if that's all that's left.
sub discard_empty_ranges {
    my ($self, $hit, $i) = @_;
    for ($i=1; $i<@$hit; $i++) {

#	warn "hit[$i]= $hit->[$i]->{'cid'} [", scalar @{$hit->[$i]->{'frag'}},"]\n";

	if (@{$hit->[$i]->{'frag'}} < 1) {
	    splice(@$hit, $i--, 1);
	}
    }
    pop @$hit    unless @$hit > 1;
    $self;
}

#return alignment in RDB table format
sub rdb {
    my $self = shift;
    my ($s, $a, $r);

    $s  = $self->{'index2row'}->[0]->rdb('attr') . "\n";
    $s .= $self->{'index2row'}->[0]->rdb('form') . "\n";

    foreach $a (@_) {
	foreach $r ($a->visible) {
	    #warn "$a  |$r|\n";
	    $self->{'uid2row'}->{$r}->set_pad('-');
	    $self->{'uid2row'}->{$r}->set_gap('-');
	    $s .= $self->{'uid2row'}->{$r}->rdb . "\n";
	}
    }
    $s;
}

#return alignment in Pearson/FASTA format
sub pearson {
    my $self = shift;
    my ($s, $a, $r);

    $s = '';

    foreach $a (@_) {
	foreach $r ($a->visible) {
	    #warn "$a  |$r|\n";
	    $self->{'uid2row'}->{$r}->set_pad('-');
	    $self->{'uid2row'}->{$r}->set_gap('-');
	    $s .= $self->{'uid2row'}->{$r}->pearson;
	}
    }
    $s;
}

#return alignment in PIR format
sub pir {
    my $self = shift;
    my ($s, $a, $r);

    $s = '';

    foreach $a (@_) {
	foreach $r ($a->visible) {
	    #warn "$a  |$r|\n";
	    $self->{'uid2row'}->{$r}->set_pad('-');
	    $self->{'uid2row'}->{$r}->set_gap('-');
	    $s .= $self->{'uid2row'}->{$r}->pir;
	}
    }
    $s;
}

#return alignment in MSF format
sub msf {
    my $self = shift;
    my ($s, $a, $r, $w, $tmp, $from, $ruler, $lo, $hi, %seq, $insert);

    $s = ''; $tmp = `date '+%Y-%m-%d  %H:%M'`; chomp $tmp;

    foreach $a (@_) {

	$s .= "MView generated MSF file\n\n";
	$s .= sprintf("   MSF: %5d  Type: %s  $tmp  Check: %4d  ..\n\n", 
		      $a->length, 'P', 0);

	$w=0; foreach $r ($a->visible) {
	    $w = length($self->{'uid2row'}->{$r}->rid) if 
		length($self->{'uid2row'}->{$r}->rid) > $w;		
	}
	    
	foreach $r ($a->visible) {
	    $s .= sprintf(" Name: %-${w}s Len: %5d  Check: %4d  Weight:  %4.2f\n",
			  $self->{'uid2row'}->{$r}->rid, $a->length, 
			  _msf_checksum(\$self->{'uid2row'}->{$r}->seq), 1.0);
	}
	$s .= "\n//\n\n";

	%seq = (); foreach $r ($a->visible) {
	    $self->{'uid2row'}->{$r}->set_pad('.');
	    $self->{'uid2row'}->{$r}->set_gap('.');
	    $seq{$r} = $a->item($r)->string;
	}
	
    LOOP:
	{
	    for ($from = 0; ;$from += 50) {
		$ruler = 1;
		foreach $r ($a->visible) {
		    last LOOP    if $from >= length($seq{$r});
		    $tmp = substr($seq{$r}, $from, 50);
		    if ($ruler) {
			$lo=$from+1; $hi=$from+length($tmp);
			$ruler = length($tmp)-length("$lo")-length("$hi");
			if ($ruler < 1) {
			    $ruler = 1;
			}
			$insert = int(length($tmp) / 10);
			$insert -= 1    if length($tmp) % 10 == 0;
			$insert += $ruler;
			$insert = sprintf("%d%s%d", $lo, ' ' x $insert, $hi);
			$s .= sprintf("%-${w}s $insert\n", '');
			$ruler = 0;
		    }
		    $s .= sprintf("%-${w}s ", $self->{'uid2row'}->{$r}->rid);
		    for ($lo=0; $lo<length($tmp); $lo+=10) {
			$s .= substr($tmp, $lo, 10);
			$s .= ' '    if $lo < 40;
		    }
		    $s .= "\n";
		}
		$s .= "\n";
	    }
	}
    }
    $s;
}

my $MSF_CHECKSUM = '--------------------------------------&---*---.-----------------@ABCDEFGHIJKLMNOPQRSTUVWXYZ------ABCDEFGHIJKLMNOPQRSTUVWXYZ---~---------------------------------------------------------------------------------------------------------------------------------';

sub _msf_checksum {
    my $s = shift;
    my ($sum, $ch) = (0, 0);
    my $len = length($$s);
    while ($len--) {
	$ch = ord substr($$s,$len,1);
	$ch = substr($MSF_CHECKSUM,$ch,1);
	$sum += (($len % 57) + 1) * ord $ch    if $ch ne '-';
    }
    $sum % 10000;
}


###########################################################################
1;
