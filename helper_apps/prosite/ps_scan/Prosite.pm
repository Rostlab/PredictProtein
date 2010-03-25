package Prosite;

# Prosite.pm - a PROSITE scanning module
#
# Copyright (C) 2001 Alexandre Gattiker, the Swiss Institute of Bioinformatics
# E-mail: gattiker@isb-sib.ch
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA  02111-1307, USA.

# This requires perl 5.005.
use 5.005_03;

use Exporter;
use IO::File;
use Carp qw(confess cluck);
use vars qw(@ISA @EXPORT $VERSION $errpos $errstr);
use strict;

BEGIN {
	$VERSION = '$Revision: 1.9 $';
	$VERSION =~ tr/0-9.//cd;
	@ISA = qw(Exporter);
	@EXPORT = qw(scanPattern scanRule scanProfiles checkPatternSyntax parseProsite prositeToRegexp);
}

#scan a sequence with a perl pattern
sub scanPattern {
	my ($pattern, $sequence, $behavior, $max_x) = @_;
	$behavior ||= 0;
	my $allowOverlap    = !($behavior & 1);
	my $allowInclude    =   $behavior & 2 ;
	$max_x = 1 unless defined $max_x;
	my @hits;
	my $pos=0;
	my @comb = $pattern =~ /\((.*?)\)/g;
	if ($pattern) {
		my $prevstop=-1;
		my @tok;
		while (@tok = (substr($sequence, $pos) =~ /^(.*?)($pattern)/)) {
			my $prematch = shift @tok;
			my $subseq = shift @tok;
			my $length = length $subseq;

			my $number_x=0;
			if (@tok == @comb and @tok) {
				$subseq="";
				for (my $i=0; $i<@tok; $i++) {
					if ($comb[$i] =~ /\./) {
						$tok[$i] =~ tr/A-Z/a-z/;
					}
					#don't count X's that match pattern elements which exclude certain AA's
					elsif ($comb[$i] =~ /^\[\^/) {
					}
					#count number of X's matching a non-x position in the pattern
					elsif (my $x_count = $tok[$i] =~ tr/Xx/Xx/) {
						$number_x+=$x_count;
					}
					my $tok = $comb[$i] =~ /\./ ? lc($tok[$i]) : $tok[$i];
					$subseq .= $tok;
					if (my @numbers = $comb[$i] =~ /(\d+)/g) { #insertion
						my $biggest = pop @numbers;
						$subseq .= "." x ($biggest - length $tok);
					}
				}
			}
			elsif (@tok != @comb) {
				cluck "Internal error with regular expression $pattern\n";
			}

			my $shift = ($length || 1) - 1;
			my $stop = $pos + $length + length $prematch;
			$pos = $stop;
			$pos -= $shift if $allowOverlap;
			last if $pos > length $sequence; #may happen if empty pattern match
			if ($length) {
				if ($allowInclude or $stop > $prevstop) {
					if ($number_x <= $max_x or $max_x<0) {
						push @hits, [$subseq, $stop - $length + 1, $stop];
						$prevstop = $stop;
					}
				}
			}
			else {
				$pos++; #empty pattern match
			}
		}
	}
	return \@hits;
}

sub scanRule {
	my ($pattern, $sequence, $ac) = @_;
	sub safesubstr {
		my ($str, $from, $len) = @_;
		if ($from<0) {$len+=$from; $from = 0;}
		return substr($str, $from, $len);
	}
	# hardcode the 3 additional rules for PS00013 (PROKAR_LIPOPROTEIN):
	# (1) The sequence must start with Met.
	# (2) The cysteine must be between positions 15 and 35 of
	#     the sequence in consideration.
	# (3) There must be at least one charged residue (Lys or
	#     Arg) in the first seven residues of the sequence.
	if ($ac eq "PS00013") {
		return [] unless substr($sequence, 0, 7)=~ /^M.*[KR]/;
		my $pos = scanPattern($pattern, $sequence);
		return $pos unless @$pos;
		my @newpos;
		my @newseq;
		for my $hit (@$pos) {
			my ($subseq, $startpos, $endpos) = @$hit;
			if ($endpos >= 15 && $endpos <= 35) {
				push @newpos, [$subseq, $startpos, $endpos];
			}
		}
		return \@newpos;
	}
	#additional rule for PS00002 (GLYCOSAMINOGLYCAN):
	# (1) There must be at least two acidic amino acids (Glu or Asp) from -2 to
	#     -4 relative to the start position.
	elsif ($ac eq "PS00002") {
		my $pos = scanPattern($pattern, $sequence, undef, 0);
		return $pos unless @$pos;
		my @newpos;
		my @newseq;
		for my $hit (@$pos) {
			my ($subseq, $startpos, $endpos) = @$hit;
			if (2 <= map{$_} safesubstr($sequence, $startpos-5, 3) =~ /[DE]/g) {
				push @newpos, [$subseq, $startpos, $endpos];
			}
		}
		return \@newpos;
	}
	elsif ($ac eq "PS00003") {
		#PS00003 SULFATION : The pattern ("Y") is not indicated in the entry.
		#additional rules :
		#(1) Glu or Asp within two residues of the tyrosine (typically at -1).
		#(2) At least three acidic residues from -5 to +5.
		#(3) No more than 1 basic residue and 3 hydrophobic from -5 to +5
		#(4) At least one Pro or Gly from -7 to -2 and from +1 to +7 or at least
		#    two or three Asp, Ser or Asn from -7 to +7.
		#(5) Absence of disulfide-bonded cysteine residues from -7 to +7.
		#(6) Absence of N-linked glycans near the tyrosine.
		my $pos = scanPattern("(.......)(Y)(.......)", $sequence, undef, 0);
		return $pos unless @$pos;
		my @newpos;
		my @newseq;
		for my $hit (@$pos) {
			my ($subseq, $startpos, $endpos) = @$hit;
			my $tyrpos = $startpos+7;
			next unless substr($sequence, $tyrpos-3, 5) =~ /[DE]/; #rule (1)
			next unless 3 <= map{$_} substr($sequence, $tyrpos-6, 11) =~ /[DE]/g; #rule (2)
			next unless 1 >= map{$_} substr($sequence, $tyrpos-6, 11) =~ /[KRH]/g; #rule (3a)
			next unless 3 >= map{$_} substr($sequence, $tyrpos-6, 11) =~ /[CILMFWV]/g; #rule (3b)
			next unless
				substr($sequence, $tyrpos-8, 10) =~ /[PG]/g and
				substr($sequence, $tyrpos, 7) =~ /[PG]/g or
				2 <= map{$_} substr($sequence, $tyrpos-8, 15) =~ /[DSN]/g; #rule (4)
				push @newpos, [$subseq, $startpos, $endpos];
		}
		return \@newpos;
	}
	elsif ($ac eq "PS00015") {
		#PS00015 NUCLEAR rules:
		#(1) Two adjacent basic amino acids (Arg or Lys).
		#(2) A spacer region of any 10 residues.
		#(3) At least three basic residues (Arg or Lys) in the five positions
		#    after the spacer region.
		my $pos = scanPattern("([KR][KR])(...............)", $sequence, undef, 0);
		return $pos unless @$pos;
		my @newpos;
		my @newseq;
		for my $hit (@$pos) {
			my ($subseq, $startpos, $endpos) = @$hit;
			next unless 3 <= map{$_} substr($sequence, $startpos+11, 5) =~ /[KR]/g;
			push @newpos, [$subseq, $startpos, $endpos];
		}
		return \@newpos;
	}
	else {
		cluck "unknown rule $ac";
		return [];
	}
}

sub scanProfiles {
	my ($file, $level_min) = @_;
	$level_min = -99 unless defined $level_min;
	my %prosite;
	local $/ = "\n";
	my $must_open_file = !UNIVERSAL::isa($file, "GLOB");
	my $pfscan_h;
	if ($must_open_file) {
		$pfscan_h = new IO::File $file or confess "Could not open $file : $!";
	}
	else {
		$pfscan_h = $file;
	}
	my $lastac="";
	my $last_entry;
	while (defined (local $_=<$pfscan_h>)) {
		if (my ($id1, $level, $levelna, $nscore, $rawscore, $from, $to, $pffrom, $pfto, $repregion, $repnumber, $ac, $de) = m/
			(
				>\S*
			)?            #ID of the profile, if option -x or -s
			(?<!L=\d)     #These three lines are to fix a bug in the output of pfscan if >99 matches are found: the id and the level are then pasted together with an intervening "1" (e.g. Q9LGZ9 vs. preprofile PS50079). FIXME: This still doesn't work with pfsearch -xlr
			(?<!L=[-\d]\d)
			(?<!L=[-\d]\d\d)
			\s*
			(?:L=(\S+)|(NA))?  #level, if option -l
			\s*
			(?:(\S+)\s+)? #normalized score, unless option -r
			(\S+)         #raw score
			\s+
			pos\.
			\s*
			(\d+)         #seq from
			\s*-\s*
			(\d+)         #seq to
			\s*
			(?:
				\[\s*
				(\d+)     #profile from
				,\s*
				(-\d+)    #profile to
				\]
				\s*
			)?            #if option -z
			(REGION\d+\s)?        #repeat region, if option -m
			(\d+REP\d+\s)?        #repeat number, if option -m
			(\S+)                 #profile or sequence AC and-or ID
			(?:\s*(.+))?  #sequence description when running pfsearch, may be absent
			/x) {
			$nscore = "999.999" if $nscore eq "*******"; #fix bug in pfsearch/pfscan which report "******" if nscore>999.999
			$level = $level_min if !defined($level) and defined $levelna;
			#            0   1      2    3    4        5      6          7        8       9      10
			my $entry = ["", $from, $to, $ac, $pffrom, $pfto, $rawscore, $nscore, $level, undef, $de, []];
			if ($repnumber) { push @{$prosite{$lastac}->[-1]->[11]}, $entry }
			else { push @{$prosite{$ac}}, $entry }
			$lastac = $ac;
			$last_entry = $entry;
		}
		else {
			#sequence
			next unless $last_entry;
			$last_entry->[0] .= $_;
		}
	}
	if ($must_open_file) {
		close $pfscan_h or confess "Error $? closing $file";
	}
	return \%prosite;
}

=cut
#TODO
sub parseXPSA {
	my ($filehandle) = @_;
	local $/ = "\n";
	my $lastac;
	while (<$filehandle>) {
		if (/^>(\S+)\/(\d+)-(\d+)( .*)?/) {
			$lastac = $1;
		}
		elsif (/^>(\S*)/) {
			$lastac = $1;
		}
		else {
			#sequence
			next unless $prosite{$lastac};
			$prosite{$lastac}->[-1]->[0] .= $_;
		}
	}
}
=cut

sub prositeToRegexp_old {
	local $_ = shift;
	my $notGreedy = shift;
	my $ungreed = $notGreedy ? "?" : "";
	s/\.$//; #possible end dot from parsing
	s/-//g;
	1 while s/\{([^\}^\^]*)([^\^^\}][^\}]*\})/\{^$1$2/; #insert ^
	s/\}/]/g;
	s/\{/[/g;
	s/\(/{/g;
	s/\)/}$ungreed/g;
	s/x/./ig;
	s/B/[ND]/g;
	s/Z/[QE]/g;

	#PS00539 is P-R-L-[G>] which would be converted to PRL[G$], but
	#"$" is not valid in a character range, we have to convert this to (?:[G]|$)
	s/\[([^\[\]]*)([<>])([^\[\]]*)\]/(?:[$1$3]|$2)/g;

	#do this after the previous step, so as not to mix ^ for excluding character classes
	#with ^ to indicate anchoring
	s/</^/g; #anchors
	s/>/\$/g;

	#insert () around match states and insertions
	s/ (\[[^\]]*\]|[\w.]) ( \{ \d+(,\d+)? \} )/)($1$2)(/xg;

	return "($_)";
}

#same, using tokenizing parser
sub prositeToRegexp {
	my $string = shift;
	my $notGreedy = shift;
	my $ungreed = $notGreedy ? "?" : "";
	my $preventX = shift;

	$errstr = undef;
	$errpos = undef;
	my $pushback = "";
	my $ntok=0;
	my $regexp = "";
	my $get = sub {
		$ntok++;
		return ($pushback =~ s/(.)// ? $1 : ($string =~ s/(.)// ? $1 : undef));
	};

	while (defined (my $tok = &$get)) {
		my $state;
		my $not;
		if ($tok eq "-") {
			#ignore
		}
		elsif ($tok eq "[") { #--RANGE
			while(defined (my $tok = &$get)) {
				last if $tok eq "]";
				$state .= $tok;
			}
		}
		elsif ($tok eq "{") { #--negative RANGE
			$not = 1;
			while(defined(my $tok = &$get)) {
				last if $tok eq "}";
				$state .= $tok;
			}
		}
		elsif ($tok =~ /[A-Za-z]/) { #-- single char
			$state = $tok;
		}
		elsif ($tok eq "<") {
			$regexp .= "^";
		}
		elsif ($tok eq ">") {
			$regexp .= '$';
		}
		else {
			$errstr = "Parsing error";
			$errpos = $ntok-1;
			return undef;
		}
		if (defined $state) {
			#read range, e.g. "x(2,5)"
			my $range;
			my $range_char;
			if(defined(my $tok = &$get)) {
				if ($tok eq "(") {
					while(defined(my $tok = &$get)) {
						last if $tok eq ")";
						$range .= $tok;
					}
				}
				elsif ($tok eq "*") { #support e.g. "<{C}*>"
					$range_char = $tok;
				}
				else {
					$pushback .= $tok;
					$ntok--;
				}
			}

			if ($state =~ /x/i) {
				$state = ".";
			}
			else {
				#handle B/Z unsure amino acids both in pattern and sequence
				if ($not) {
					$state =~ s/B/NDB/g;
					$state =~ s/Z/QEZ/g;
				}
				else {
					$state =~ s/B/NDB/g or $state =~ s/([ND])/$1B/g;
					$state =~ s/Z/QEZ/g or  $state =~ s/([QE])/$1Z/g;
					$state .= "X" unless $preventX;
				}
			}
			my $mod = $1 if $state =~ s/([<>])//g;
			#"$" is not valid in a character range, we have to convert this to (?:[GH]|$)
			$regexp .= "(";
			$regexp .= "(?:" if $mod;
			$regexp .= "[" if length($state)>1 or $not;
			$regexp .= "^" if $not;
			$regexp .= $state;
			$regexp .= "]" if length($state)>1 or $not;
			$regexp .= "|" . ($mod eq "<" ? "^" : '$') . ")" if $mod;
			$regexp .= "{$range}$ungreed" if defined $range;
			$regexp .= "$range_char" if defined $range_char;
			$regexp .= ")";
		}
	}
	return $regexp;
}


# Checks that a user-entered pattern is parseable, returning an error message or undef
#TODO: <A-T-[<GE] should be an error
sub checkPatternSyntax {
	my $pattern=shift;
	my $c1 = 0;
	my $c2 = 0;
	my ($c_open_square, $c_open_curly, $c_open_paren) = (0, 0, 0);
	my ($c_close_square, $c_close_curly, $c_close_paren) = (0, 0, 0);
	if (
		$pattern =~ /(-){2,}/ ||
		$pattern =~ /([,\-\(\)\{\}\[\]\<\>]){2,}]/) {
		return "duplicate character \"$1\"";
	}
	if ($pattern !~ /[a-zA-Z]/) {
		return "pattern has no characters";
	}
	if ($pattern =~ /-\(/) {
		return "dash before (";
	}
	if ($pattern =~ /([JOU])/i) {
		return "pattern contains letter \"$1\" which is not an amino acid";
	}
	if (length($pattern) > 200) {
		return "pattern is longer than the limit of 200 characters";
	}
	elsif ($pattern =~ /^\[[a-z]+\]$/i) {
		return "pattern is too degenerate";
	}
	else {
		my $ambig;
		my $ambig_complement;
		my $range;
		my %count;
		my @ambig;
		foreach (split(//,$pattern)) {
			unless ($c1 == $c2 || $c1 == $c2 +1) { # always close parentheses
				# before opening a new one!
				return "nested parentheses are forbidden";
			}
			if (/[\[\{\(]/) {
				$c1++;
				if (/\[/) {
					$ambig = " ";
					$c_open_square++;
				}
				elsif (/\{/) {
					$ambig_complement = " ";
					$c_open_curly++;
				}
				elsif (/\(/) {
					$range = " ";
					$c_open_paren++;
				}
			}
			elsif (/[\]\}\)]/) {
				$c2++;
				if (/\]/) {
					%count = ();
					if (length($ambig) < 3) {
						return "no real ambiguity inside []";
					}
					else {
					@ambig = split(//, $ambig);
					for (@ambig) {
						$count{$_}++;
					}
					for (sort keys %count) {
						if ($count{$_} ne 1) {
						return "string inside square brackets \"$ambig\" contains duplicates";
						}
					}
					}
					$ambig = "";
					$c_close_square++;
				}
				elsif (/\}/) {
					$ambig_complement = "";
					$c_close_curly++;
				}
				elsif (/\)/) {
					$range =~ s/^\s+//;
					if ($range =~ /^(\d+),(\d+)$/) {
					if ($1 >= $2) {
						return "range \"$range\" is invalid (second term must be greater than first)";
					}
					}
					elsif ($range !~ /^\d+$/){
						return "range \"$range\" is invalid";
					}
					$range = "";
					$c_close_paren++;
				}
			}
			elsif ($range) {
				if (!/[\d,]/) {
					return "incorrect range \"$range\"";
				}
				$range .= $_;
			}
			elsif ($ambig) {
				if (!/[A-Z<>]/) { # [G>] is allowed, e.g. PS00267, PS00539
					return "wrong syntax for ambiguity : \"$ambig \"";
				}
				if (/([BZ])/) {
					return "ambiguous amino acid \"$1\" not allowed within ambiguity";
				}
			$ambig .= $_;
			}
			elsif ($ambig_complement) {
				if (!/[A-Z]/) {
					return "wrong syntax for ambiguity : \"$ambig_complement\"";
				}
			$ambig_complement .= $_;
			}
			else { #amino acid or anchor, or * quantifier
				if (/([^A-Zx\-<>*])/) {
					return "invalid character : \"$1\"";
				}
			}
		}
		if ($c1 != $c2) {
			return "unbalanced (), [] or {}";
		}
		elsif ($c_open_square != $c_close_square) {
			return "unbalanced []";
		}
		elsif ($c_open_curly != $c_close_curly) {
			return "unbalanced {}";
		}
		elsif ($c_open_paren != $c_close_paren) {
			return "unbalanced ()";
		}
	}
	return undef;
}

sub parseProsite {
	local $_ = shift;
	my $ac = $1 if /^AC   (\w+)/m;
	my ($id, $type) = ($1, $2) if /^ID   (\w+); (\w+)/m;
	my $de_line = join "\n", /^(DE.*\S)/mg;
	my $de = join " ", $de_line =~ /^DE   (.*\S)/mg;
	my $pa = join "", /^PA   (.*\S)/mg;
	$pa =~ s/\.$//;
	my $rule = join "\\\n", /^RU   (.*\S)/mg;
	my $skip = /^CC   \/SKIP-FLAG=TRUE/m;
	my $pdoc = $1 if /^DO   (\w+)/m;
	my $tax = $1 if /^CC   \/TAXO-RANGE=(.*?);/m;
	my $rep = $1 if /^CC.*\/MAX-REPEAT=(\d+)/m;
	my @sites = map {[$1, $2]} /\/SITE=(\d+),(.*?);/g;
	my @cutoffs = map {my %a=map {split /=/, $_, 2} split /; */, $_; \%a } /^MA   \/CUT_OFF: (.*)/mg;
	return ($ac, $id, $type, $de, $pa, $rule, $pdoc, $skip, $tax, $rep, \@sites, \@cutoffs);
};

1;

=head1 NAME

Prosite.pm -
functions to use and scan the PROSITE database on sequences

=head1 SYNOPSIS

 use Prosite;

 use Prosite 1.0; #specify a version number

 my $re = prositeToRegexp("D-[EFG]-{Q}");
 my $seq = "FDEGGDEDFGDEDGDEQEEDEDGEGEG";
 my $hits = scanPattern($re, $seq);
 for my $hit (@$hits){
   my ($subseq, $from, $to) = @$hit;
   print "$from - $to: $subseq\n";
 }

=head1 DESCRIPTION

This package supplies methods to scan amino acid sequences against the
PROSITE database of protein families and domains. PROSITE consists of
biologically significant sites, patterns and profiles that help to
reliably identify to which known protein family (if any) a new sequence
belongs.

PROSITE currently contains three classes of identification tools. These
are :

=over 4

=item Patterns

These are a subset of regular expressions. PROSITE defines the patterns
but not the way those patterns have to be matched. Therefore the
greediness of the match and the handling of overlapping matches is left
to the implementation. This module gives the user control over these
parameters.

=item Profiles

Scanning a sequence with generalized profiles is not trivial and
computationally intensive. Therefore, this module does not do the scan
itself, but calls the external program pfscan and parses the results.

=item Rules

A few number of PROSITE entries have a number of rules instead of, or
complementing, a pattern. These rules are directly hard-coded in this
module.

=back

=head1 METHODS

All methods are exported.

=over 4

=item scanPattern $pattern, $sequence[, $behavior[, $max_x]]

Scans a pattern (a regular expression, NOT a pattern in PROSITE format)
with a sequence. Returns a pointer to an array of arrays of [subsequence,
starting pos, ending pos] of matches. If each token of the pattern is
enclosed by parentheses, as is the case of the output of prositeToRegexp(),
the subsequence has residues corresponding to an "x" in the pattern are in
lowercase, and dashes are inserted in variable-length range matches so that
different subsequences obtained with a single pattern form a multiple
sequence alignment based on the pattern tokens.

$behavior controls whether the engine allows overlapping and including
matches. Allowed values are :

 not set, 0 or undef - allow overlapping, but not included matches

 1 - don't allow overlapping matches

 2 - allow overlapping and included matches

see PATTERN MATCHING for additional details.

$max_x is the maximum number of X residues in the sequence that can match
a non-X position in the pattern. The default value is 1.

=item scanRule $pattern, $sequence, $rule_ac

Scans a sequence with a PROSITE rule. Return type is the same as
scanPattern(). Known rules are PS00013, PS00002, PS00003 and PS00015.

=item scanProfiles $filename

Read an output file of the program pfscan from the pftools package. The pfscan
program should be run with the options -x, -z and -l so as to report the
matching sequence, the bounding positions on the profile, and the highest
matched cut-off level, respectively. The return value is an a hash for which
the keys are PROSITE accession numbers and the values are arrays of arrays; for
each hit, the array contains (matching sequence, start on sequence, end on
sequence, profile identifier, start on profile, end on profile, raw score,
normalized score, cut-off level, level-tag, description text, array of
submatches).  The sequence matching the profile is reported with insertions in
lowercase and deletions represented by dashes. Level-tag is not implemented.

The pftools package by Philipp Bucher is available at
ftp://ftp.ch.embnet.org/sib-isrec/pftools/


=item prositeToRegexp $pspattern[, $notGreedy[, $preventX]]

Transforms a PROSITE pattern to a perl regular expression. Note that
the syntax of the $pspattern is not checked, so that the result cannot
be guaranteed to be a valid regular expression. If $notGreedy is set
to 1, the matching will not be greedy (see PATTERN MATCHING).
If $preventX is set, no X characters in the sequence will be allowed to
match conserved positions in the pattern.

Returns a perl regular expression, or `undef' if the pattern could
not be parsed. In the latter case the position and the message of
the error are found in the variables $Prosite::errpos and $Prosite::errstr.

=item checkPatternSyntax $pspattern

Checks the syntax of a pattern for syntax errors and obvious mistakes
(such as unreal ambiguities and too degenerate patterns). Returns undef
if no errors have occurred, or a string containing a message describing
the first error which was found.

=item parseProsite $psentry

Parses a PROSITE entry (text starting with "ID" and ending with "//\n")
and returns the following values in an array : AC, ID, type,
description, pattern, rule, PDOC, skip-flag, taxon, max-repeat, sites
(sites is an array of arrays).

=back

=head1 PATTERN SYNTAX

=over 4

=item *

The standard IUPAC one-letter codes for the amino acids are used.

=item *

The symbol "x" is used for a position where any amino acid is accepted.

=item *

Ambiguities are indicated by listing the acceptable amino acids for a
given position, between square parentheses "[ ]". For example: [ALT]
stands for Ala or Leu or Thr.

=item *

Ambiguities are also indicated by listing between a pair of curly
brackets "{ }" the amino acids that are not accepted at a given
position. For example: {AM} stands for any amino acid except Ala and
Met.

=item *

Each element in a pattern is separated from its neighbor by a "-".

=item *

Repetition of an element of the pattern can be indicated by following
that element with a numerical value or a numerical range between
parenthesis. Examples: x(3) corresponds to x-x-x; x(2,4) corresponds to
x-x or x-x-x or x-x-x-x; A(3) corresponds to A-A-A.

=item *

When a pattern is restricted to either the N- or C-terminal of a
sequence, that pattern either starts with a "<" symbol or respectively
ends with a ">" symbol.

=item *

In some rare cases (e.g. PS00267 or PS00539), '>' can also occur inside
square brackets for the C-terminal element. 'F-[GSTV]-P-R-L-[G>]' means
that either 'F-[GSTV]-P-R-L-G' or 'F-[GSTV]-P-R-L>' are considered.

=item *

The character * may be used for to specify a range which can be "zero or
more". Thus, the pattern "<{C}*>" can be used to retrieve all sequences
which do not contain a Cysteine. [This is not used in PROSITE, but
supported in this module]

=back

=head1 PATTERN MATCHING

Three parameters allow to finely tune the behaviour of
the pattern-matching engine. These are :

=over 4

=item greed

extend at most variable-length pattern elements

=item overlap

allow partially overlapping matches

=item include

allow matches included within one another (implies overlap)

=back

The default behavior is greedy, allows overlaps but not included
matches. This means that two overlapping matches are rejected if one
is entirely contained within the other.

For example, consider the sequence "ABACADAEAFA" and the simple pattern
"A-x(1,3)-A". The six possible combinations of the switches produce the
following results:

=over 4

=item *

greed=1, overlap=1, include=0 (default) : 4 matches

  ABACADAEAFA
  ooooo......
  ..ooooo....
  ....ooooo..
  ......ooooo

=item *

greed=1, overlap=1, include=1 : 5 matches

  ABACADAEAFA
  ooooo......
  ..ooooo....
  ....ooooo..
  ......ooooo
  ........ooo

=item *

greed=1, overlap=0 : 2 matches

  ABACADAEAFA
  ooooo......
  ......ooooo

=item *

greed=0, overlap=1, include=0 or 1 : 5 matches

  ABACADAEAFA
  ooo........
  ..ooo......
  ....ooo....
  ......ooo..
  ........ooo

=item *

greed=0, overlap=0 : 3 matches

  ABACADAEAFA
  ooo........
  ....ooo....
  ........ooo

=back

=head1 ACKNOWLEDGEMENTS

Thanks go to Marco Pagni for providing me with the pattern matching
example.

=head1 AUTHORS

Alexandre Gattiker, gattiker@isb-sib.ch

Elisabeth Gasteiger, Elisabeth.Gasteiger@isb-sib.ch

=cut

