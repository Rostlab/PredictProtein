#!/usr/bin/env perl

# ps_scan - a PROSITE scanning program
#
# Copyright (C) 2001, 2003 Alexandre Gattiker, Swiss Institute of Bioinformatics
# E-mail: gattiker@isb-sib.ch
# With contributions from Lorenza Bordoli
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

#!/usr/bin/env perl

# ps_scan - a PROSITE scanning program
#
# Copyright (C) 2001, 2003 Alexandre Gattiker, Swiss Institute of Bioinformatics
# E-mail: gattiker@isb-sib.ch
# With contributions from Lorenza Bordoli
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


use vars qw($VERSION);
BEGIN {
	$VERSION = '$Revision: 1.20 $';
	$VERSION =~ s/\$Revision: //;
	$VERSION =~ s/ \$$//;
}

#Can we use the IPC::Open2 module to communicate with
#pfscan via pipes (instead of temp files) ?
eval {require IPC::Open2};
my $SAFE_PIPE=$? || $^O eq "MSWin32" ? 1 : 0;

#change this to the absolute path to the programs,
#unless they are located in a directory in your PATH
#or use option --pfscan and/or --psa2msa to give the full path.
my $PFSCAN  = $ENV{PP_PROSITE}.'/ps_scan/pfscan';
my $PSA2MSA = $ENV{PP_PROSITE}.'/ps_scan/psa2msa';

my $errcode = 0;

my $PROSITE_ENTRY = 'PS\d{5}';
$|=1;

use Getopt::Long;
use IO::File;

my @formats = qw(scan fasta psa msa gff pff epff sequence matchlist);
my $formats_string = join " | ", @formats;
sub usage {
	my $progname = $0;
	$progname =~ s/.*[\\\/]//;
	print <<EOF;
$progname [options] sequence-file(s)
ps_scan version $VERSION options:
-h : this help screen
Input/Output:
  -e : specify the ID or AC of an entry in sequence-file
  -o : specify an output format : $formats_string
  -d : specify a prosite.dat file
  -p : specify a pattern or the ID or AC of a prosite pattern
Selection:
  -r : do not scan profiles
  -s : skip frequently matching (unspecific) patterns and profiles
  -l : cut-off level for profiles (default : 0)
Pattern match mode:
  -x : specify maximum number of accepted matches of X's in sequence
       (default=1)
  -g : Turn greediness off
  -v : Turn overlaps off
  -i : Allow included matches

The sequence-file may be in Swiss-Prot or FASTA format.
If no PROSITE file is submitted, it will be searched in the paths
\$PROSITE/prosite.dat and \$SPROT/prosite/prosite.dat.
There may be several -d, -p and -e arguments.

Pfsearch options:
  -w pfsearch : Compares a query profile against a protein sequence library.
  A profile file must be specified with option -d.

   $progname -w pfsearch [-C cutoff] [-R] -d profile-file seq-library-file(s)

 -R: use raw scores rather than normalized scores for match selection
 -C=# : Cut-off value. Reports only match score higher than the specified parameter.
An integer argument is interpreted as a raw score value,
a decimal argument as a normalized score value. An integer value forces option -R.
EOF
	exit 1;
}

my $opt_noprofiles;
my $opt_skip;
my $opt_help;
my $opt_format;
my $opt_max_x;
my $opt_nongreedy;
my $opt_nooverlaps;
my $opt_includes;
my $opt_level = 0;

my $opt_allprofiles;
my $opt_pfsearch;
my $opt_cutoff;
my $opt_raw;
my $opt_minhits;
my $opt_maxhits;
my $opt_filterheader;
my $opt_reverse;
my $opt_shuffle;

my @prosite_files;
my @patterns;
my @entries;

my $SLASH = $^O eq "MSWin32" ? "\\" : "\/";
my $TMPDIR = ".";
for my $dir ($ENV{TMPDIR}, $ENV{SP_TEMP}, $ENV{TMP}, $ENV{TEMP}, "/tmp", "c:\\temp", "c:\\tmp" ) {
	if (defined($dir) and -d $dir) {
		$TMPDIR=$dir; last;
	}
}
my $TMP_COUNTER = substr(abs($$), -6);
my $PROFILE_TMP = tmpnam();

my $opened_profile_tmp;
my $scan_profiles;

Getopt::Long::Configure ("bundling", "no_ignorecase");
GetOptions (
	"r" => \$opt_noprofiles,
	"s" => \$opt_skip,
	"h" => \$opt_help,
	"v" => \$opt_nooverlaps,
	"i" => \$opt_includes,
	"g" => \$opt_nongreedy,
	"x=i" => \$opt_max_x,
	"l=i" => \$opt_level,
	"o=s" => \$opt_format,
	"d=s" => \@prosite_files,
	"p=s" => \@patterns,
	"e=s" => \@entries,

	"a" => \$opt_allprofiles,
	"w=s" => \$opt_pfsearch,
	"C=f" => \$opt_cutoff,
	"R" => \$opt_raw,

	"pfscan=s"  => \$PFSCAN,
	"psa2msa=s" => \$PSA2MSA,
	"minhits=i" => \$opt_minhits,
	"maxhits=i" => \$opt_maxhits,
	"filterheader=s" => \$opt_filterheader,
	"reverse" => \$opt_reverse,
	"shuffle=i" => \$opt_shuffle,
) or &usage;
&usage if $opt_help;
&usage if !@ARGV && -t STDIN;
if ($opt_pfsearch) {
	&usage unless @prosite_files;
	$opt_raw = $1 if defined($opt_cutoff) and $opt_cutoff=~ /^(\d+)$/mg; #integer cutoff forces raw scores
}

my $scan_behavior;
$scan_behavior |= 1 if $opt_nooverlaps;
$scan_behavior |= 2 if $opt_includes;

$opt_format = "scan" unless defined $opt_format;
$opt_format =~ tr/A-Z/a-z/;
die "ERROR:Output format must be one of $formats_string\n" unless grep  {$_ eq $opt_format} @formats;
my $opt_psa_or_msa = $opt_format eq "msa" || $opt_format eq "psa";

#find default prosite.dat file
unless(@prosite_files) {
	if (defined $ENV{PP_PROSITE_DATA} and -e "$ENV{PP_PROSITE_DATA}/prosite.dat") {
		@prosite_files = "$ENV{PP_PROSITE_DATA}/prosite.dat";
	}
	elsif (-e "prosite.dat") {
		@prosite_files = "prosite.dat";
	}
	elsif (@patterns and not grep {/^$PROSITE_ENTRY$/} @patterns) {
		#user-supplied patterns only => no need for prosite.dat
	}
	else {
		die "prosite.dat file not found, please use the -d option";
	}
}

my %SkipFlag;
my %KnownFalsePos;

#if patterns are input in PSxxxx format, translate them from the prosite files
if (grep {/^$PROSITE_ENTRY$/} @patterns) {
	for my $psfile (@prosite_files) {
		open PSFILE, $psfile or die "Cannot open $psfile : $!";
		my $ps_entry = "";
		PROSITE: while (<PSFILE>) {
			$ps_entry .= $_;
			if (/^\/\//) {
				if ($ps_entry =~ /^AC   (\w+)/m) {
					my $ac = $1;
					for (my $i=0; $i<@patterns; $i++) {
						next unless $patterns[$i] =~ /^$PROSITE_ENTRY$/;

						my ($ac, $id, $type, $de, $pa, $rule, $pdoc, $skip, $tax, $rep, $sites, $cutoffs) = parseProsite($ps_entry);
						next unless $patterns[$i] eq $ac;

						$SkipFlag{$ac} = 1 if $skip;
						$skip &&= $opt_skip;

						if ($ps_entry =~ /^DR.*, T;/m) {
							my $nbfp=0;
							for my $line ($ps_entry =~ /^DR(.*)/mg) {
								$nbfp += $line =~ s/, F;//g;
							}
							$KnownFalsePos{$ac} = $nbfp;
						}

						if ($type eq "PATTERN" || $type eq "RULE") {
							splice @patterns, $i, 1, [$ac, $id, $type, $de, prositeToRegexpWrapper($pa, $opt_nongreedy), $skip];
						}
						elsif ($type eq "MATRIX") {
							next if $opt_noprofiles;
							splice @patterns, $i, 1, [$ac, $id, $type, $de, undef, $skip, $cutoffs];
							unless ($opened_profile_tmp++) {
								open PROFILE_TMP, ">$PROFILE_TMP" or die "Cannot open $PROFILE_TMP : $!";
							}
							print PROFILE_TMP $ps_entry;
						}
						else {
							warn "Unknown prosite entry type $type";
							next PROSITE;
						}
					}
				}
				$ps_entry = "";
			}
		}
		close PSFILE;
	}
}


#if no list of patterns is supplied on the command line, read all patterns from prosite.dat file.
if (!@patterns) {
	for my $psfile (@prosite_files) {
		open PSFILE1, $psfile or die "Cannot open $psfile : $!";
		my $ps_entry = "";
		PROSITE: while (<PSFILE1>) {
			$ps_entry .= $_;
			if (/^\/\//) {
				if ($ps_entry =~ /^AC   (\w+)/m) {
					my ($ac, $id, $type, $de, $pa, $rule, $pdoc, $skip, $tax, $rep, $sites, $cutoffs) = parseProsite($ps_entry);

					$SkipFlag{$ac} = 1 if $skip;
					$skip &&= $opt_skip;

					if ($ps_entry =~ /^DR.*, T;/m) {
						my $nbfp=0;
						for my $line ($ps_entry =~ /^DR(.*)/mg) {
							$nbfp += $line =~ s/, F;//g;
						}
						$KnownFalsePos{$ac} = $nbfp;
					}

					if ($type eq "PATTERN" || $type eq "RULE") {
						push @patterns, [$ac, $id, $type, $de, prositeToRegexpWrapper($pa, $opt_nongreedy), $skip];
					}
					elsif ($type eq "MATRIX") {
						push @patterns, [$ac, $id, $type, $de, undef, $skip, $cutoffs];
					}
					else {
						warn "Unknown prosite entry type $type";
						next PROSITE;
					}
				}
				$ps_entry = "";
			}
		}
		close PSFILE1;
	}
	$scan_profiles=1 unless $opt_noprofiles;
}

if ($opened_profile_tmp) {
	close PROFILE_TMP;
	$scan_profiles=1;
}

#@patterns should be an array of arrays of [AC or undef, type, pattern or undef, skip]
my $user_ctr=1;
for (@patterns) {
	next if ref $_;
	die "Prosite entry $_ not found in specified prosite file(s)\n" if /^$PROSITE_ENTRY$/;
	my $i = "0" x (3-length($user_ctr)) . $user_ctr++;
	$_ = ["USER$i", undef, "USER", undef, prositeToRegexpWrapper($_, $opt_nongreedy), 0];
}

if ($opt_format eq "matchlist") {
	searchSeq();
}
else {
	unshift(@ARGV, '-') unless @ARGV;
	while (my $seqfile = shift @ARGV) {
		#ignore -w option if no matrix supplied
		if ($opt_pfsearch and grep {$_->[2] eq "MATRIX"} @patterns) {
			scanSeq_pfsearch($seqfile);
		}
		else {
			scanSprot($seqfile);
		}

	}
}

if ($opened_profile_tmp) {
	unlink $PROFILE_TMP;
}

exit $errcode;



### SUBROUTINES ###


sub scanFastaEntry {
	my $entry = shift;
	return unless $entry =~ s/^>((\S*).*)\n//;
	my ($fasta_header, $primary_id) = ($1, $2);
	return if defined($opt_filterheader) and $fasta_header !~ /$opt_filterheader/o;
	if (not (@entries) or grep {$_ eq $primary_id} @entries) {
		$entry =~ tr/A-Z//cd;
		scanSeq($primary_id, [], $fasta_header, $entry);
	}
}

sub scanSprot {
	my ($seqfile) = @_;
	my $entry="";
	my $opt_fasta;

	my $seqfile_h = new IO::File $seqfile or die "Cannot open $seqfile: $!";
	while (<$seqfile_h>) {
		if (/^>(.*)/) {
			scanFastaEntry($entry);
			$opt_fasta = 1;
			$entry = "";
		}
		$entry .= $_;
		if (/^\/\//) {
			$opt_fasta = 0;
			my @id = $entry =~ /^\s*ID\s+(\w+)/mg;
			my $ac_lines;
			$ac_lines .= $1 while $entry =~ /^\s*AC\s+(.*)/mg;
			my @ac;
			while($ac_lines =~ /(\w+)/g) {push @ac, $1}
			if (@id) {
				if (not (@entries) or grep {my $ent=$_; grep{$_ eq $ent} @id,@ac} @entries) {
					my $id = $id[0];

					my @de = $entry =~ /^\s*DE\s+(.+)/mg;
					my $de=@ac ? "($ac[0]) " : "";
					my $add_space=0;
					for (@de) {
						$de .=  " " if $add_space;
						$de .= $_;
						$add_space = !/-$/;
					}
					if ($entry =~ /^\s*SQ\s+SEQUENCE\b.*\n((.+\n)+)/m) {
						my $sq = $1;
						$sq =~ tr/A-Z//cd;
						$de = "$id $de" if $id and $de;
						scanSeq($id, \@ac, $de || $id, $sq);
					}
					else {
						warn "No sequence found in entry $id";
					}
				}
			}
			elsif ($entry =~ /^\s*id /m) { #ignore entries which have "id" in lowercase
			}
			elsif ($entry =~ /(.*\S.*)/) {
				warn "Bad sequence found in file, first line: $1\n";
				$errcode = 1;

			}
			$entry = "";
		}
	}
	close $seqfile_h;
	if ($entry =~ /^>/) {scanFastaEntry($entry); }
	elsif ($entry =~ /(.*\S.*)/) {warn "Bad sequence found in file, first line : $1\n"; $errcode = 1}
}

sub scanSeq {
	my ($id, $aclist, $de, $sq) = @_;
	my $pfhits;

	if ($opt_reverse) {
		$sq = reverse $sq;
	}
	if ($opt_shuffle) {
		srand 0;
		my @seq = grep {$_ ne "\n"} split(//,$sq);
		$sq = "";
		for (my $start_win=0; $start_win<@seq; $start_win+=$opt_shuffle) {
			my $stop_win=$start_win+$opt_shuffle-1;
			$stop_win=@seq-1 if $stop_win>=@seq;
			my @residues = @seq[$start_win..$stop_win];
			while (@residues) {
				$sq.=splice(@residues, int(rand(scalar @residues)) ,1);
			}
		}
	}

	if ($scan_profiles) {
		if ($opened_profile_tmp) {
			$pfhits = do_pfscan($PROFILE_TMP, undef, $sq);
		}
		else {
			die "Cannot scan several prosite files for profiles" if @prosite_files>1;
			$pfhits = do_pfscan($prosite_files[0], undef, $sq);
		}
	}
	if (@patterns) { #scan with some patterns or profiles
		for (@patterns) {
			my ($psac, $psid, $type, $psde, $pat, $skip) = @$_;
			next if $skip;
			my $hits;
			if ($type eq "MATRIX") {
				$hits = $pfhits->{$psac};
				unless ($hits) {
					while (my ($psac_, $hits_) = each %$pfhits) {
						$hits = $hits_ if $psac_ =~ /^\Q$psac\E\|/;
					}
				}
				next unless $hits and @$hits;
			}
			elsif ($type eq "RULE") {
				$hits = scanRuleWrapper([$pat, $sq, $psac], $psid);
				next unless @$hits;
			}
			else {
				warn("Empty pattern for $psac\n"), next unless $pat;
				$hits = scanPatternWrapper([$pat, $sq, $scan_behavior, $opt_max_x], $psid);
				next unless @$hits;
			}
			dispHits(undef, $sq, $hits, $id, $de, $aclist, $psac, $psid, $psde);
		}
	}
	else { #scan with all prosite
		#FIXME: is this ever executed ?
		for my $psfile (@prosite_files) {
			open PSFILE2, $psfile or die "Cannot open $psfile : $!";
			my $ps_entry = "";
			PROSITE: while (defined (local $_=<PSFILE2>)) {
				$ps_entry .= $_;
				if (/^\/\//) {
					if ($ps_entry = /^AC   (\w+)/m) {
						my ($psac, $psid, $type, $psde, $pat, $rule, $pdoc, $skip, $tax) = parseProsite($ps_entry);
						my $hits;
						if ($type eq "MATRIX") {
							$hits = $pfhits->{$psac};
							next unless $hits and @$hits;
						}
						elsif ($type eq "RULE") {
							$hits = scanRuleWrapper([$pat, $sq, $psac], $psid);
							next unless @$hits;
						}
						else {
							warn("Empty pattern for $psac\n"), next unless $pat;
							$hits = scanPatternWrapper([prositeToRegexpWrapper($pat, $opt_nongreedy) , $sq, $scan_behavior, $opt_max_x], $psid);
							next unless @$hits;
						}
						my $header = ">$id : $psac $psid $psde\n";
						dispHits($header, $sq, $hits, $id, $de, $aclist, $psac, $psid, $psde);
					}
					$ps_entry = "";
				}
			}
			close PSFILE2;
		}
	}
}

sub searchSeq {
	for my $pattern (@patterns) {
		my ($psac, $psid, $type, $psde, $pat, $skip) = @$pattern;
		next if $type eq "MATRIX"; #not available for profiles
		my $n_hits = 0;
		my $n_match = 0;
		print "$psid\n";
		for my $sprotfile (@ARGV) {
			open SPROTFILE, $sprotfile or die "Cannot open $sprotfile : $!";
			my $entry="";
			while (<SPROTFILE>) {
				$entry .= $_;
				if (/^\/\//) {
					if ($entry =~ /^\s*ID\s+(\w+)/m) {
						my $id = $1;
						if ($entry =~ /^\s*AC\s+(\w+)/m) {
							my $ac = $1;
							my @de = /^\s*DE\s+(.+)/mg;
							my $de;
							my $add_space=0;
							for (@de) {
								$de .=  " " if $add_space;
								$de .= $_;
								$add_space = !/-$/;
							}
							if ($entry =~ /^\s*SQ\s+SEQUENCE\b.*\n((.+\n)+)/m) {
								my $sq = $1;
								$sq =~ tr/A-Z//cd;
								$de = "$id $de" if $id and $de;
								my $hits;
								if ($type eq "RULE") {
									$hits = scanRuleWrapper([$pat, $sq, $psac], $psid);
								}
								else {
									$hits = scanPatternWrapper([$pat, $sq, $scan_behavior, $opt_max_x], $psid);
								}
								if ($hits and @$hits) {
									print pf($ac, 6), ", ", pf($id, 10), ", T;       ", scalar(@$hits), "\n";
									$n_hits+=@$hits;
									$n_match++;
								}
							}
							else {
								warn "No sequence found in entry $id";
							}
						}
					}
					$entry = "";
				}
			}
		}
		print " ", pf($n_match, 13), " ", $n_hits, "\n";
	}
}

#format a field with a certain width
sub pf {return $_[0] . (" " x ($_[1] - length $_[0]))}

my $HIT_COUNT=0; #static var
sub dispHits {
	my ($header, $sq, $hits, $seqid, $de, $aclist, $psac, $psid, $psde) = @_;
	unroll_hits($hits);
	if (defined $opt_maxhits) {
		splice(@$hits, $opt_maxhits-$HIT_COUNT);
		exit 0 if $HIT_COUNT>=$opt_maxhits ;
	}
	my $hit_count = @$hits;
	$HIT_COUNT+=$hit_count;
	return unless $hit_count;
	return if defined ($opt_minhits) and $opt_minhits > $hit_count;
	print $header if defined($header);

	$psac = $patterns[0]->[0] if !defined($psac);

	if ($opt_format eq "fasta" or $opt_psa_or_msa) {
		for my $hit (@$hits) {
			my ($subseq, $from, $to, $pfid, $pffrom, $pfto, $rawscore, $nscore, $leveln, $levelt, $seqde) = @$hit;
			my $print_level = defined($levelt) ? "L=$levelt " : defined($leveln) ? "L=$leveln " : "";
			if ($opt_pfsearch) {
				$opt_psa_or_msa=1;
				print ">$seqid/$from-$to : $hits->[0]->[10] $print_level\n";
			}
			else {
				print ">$seqid/$from-$to : $psac $psid $print_level\n";
			}
			if ($subseq and $opt_psa_or_msa) { #pfscan output
				$subseq =~ s/\n?$/\n/; #add \n to scanPattern output
				print $subseq;
			}
			else {
				$subseq = substr($sq, $from-1, $to-$from+1);
				while ($subseq =~ /(.{1,60})/g) {
					print "$1\n";
				}
				print "\n" if $subseq eq "";
			}
		}
	}
	elsif ($opt_format eq "pff" || $opt_format eq "epff") {
		for my $hit (@$hits) {
			my @pff = @$hit;
#			$pff[8]=$pff[9] if defined $pff[9]; #move LevelTag into Level
			pop @pff while @pff>9; #remove fields beyond numeric level
			my $subseq = shift @pff;  #remove subseq
			$pff[2] = $psac || $pff[2];
			if ($opt_format eq "epff") {
				push @pff, "" while @pff < 8;
				$subseq =~ s/\s//g;
				push @pff, $subseq;
			}
			print $seqid, "\t", join("\t", @pff), "\n";
		}
	}
	elsif ($opt_format eq "gff") {
		for my $hit (@$hits) {
			my ($subseq, $from, $to, $pfid, $pffrom, $pfto, $rawscore, $nscore, $leveln, $levelt, $seqde) = @$hit;
			print join ("\t", $seqid, "ps_scan|v$VERSION", $psac, $from, $to, $nscore || ".", ".", ".");
			my @attr;
			if (defined $pfid) {
				$pfid =~ s/.*\|//;
				push @attr, "Name \"$pfid\"" if defined $pfid;
			}
			push @attr, "AccessionNumbers " . join(" ", map {"\"$_\""} @$aclist) if defined $aclist and @$aclist;
			push @attr, "Level $leveln" if defined $leveln;
			push @attr, "LevelTag \"$levelt\"" if defined $levelt;
			push @attr, "RawScore $rawscore" if defined $rawscore;
			push @attr, "FeatureFrom $pffrom" if defined $pffrom;
			push @attr, "FeatureTo $pfto" if defined $pfto;
			$subseq =~ s/\s//g;
			push @attr, "Sequence \"$subseq\"" if defined $subseq;

			push @attr, "SkipFlag 1" if $SkipFlag{$psac};
			push @attr, "KnownFalsePos $KnownFalsePos{$psac}" if exists $KnownFalsePos{$psac};
			print "\t", join " ; ", @attr if @attr;
			print "\n";
		}
	}
	elsif ($opt_format eq "sequence") {
		print ">$de\n", map {"$_\n"} $sq =~ /(.{1,60})/g if @$hits;
	}
	else {
		if ($opt_pfsearch) {
			print ">$seqid : $hits->[0]->[10]\n";
		}
		else {
			print ">$seqid : $psac $psid $psde\n";
		}
		for my $hit (@$hits) {
			my ($subseq, $from, $to, $pfid, $pffrom, $pfto, $rawscore, $nscore, $leveln, $levelt, $seqde) = @$hit;
			my $print_level = defined($levelt) ? " L=$levelt" : defined($leveln) ? " L=$leveln" : "";
			my $fromto = "$from - $to";
			print " " x (13-length $fromto), $fromto;
			if ($subseq) { #pfscan output
				$subseq =~ s/\n?$/\n/; #add \n to scanPattern output
				$subseq =~ s/^(?<!\A)(.*)/               $1/mg;
				$subseq =~ s/^(.*)/$1 . (" " x (60-length $1)) . $print_level/e if $print_level;
				print "  ", $subseq;
			}
			else {
				$subseq = substr($sq, $from-1, $to-$from+1);
				my $notfirst;
				while ($subseq =~ /(.{1,60})/g) {
					print " " x 13 if $notfirst++;
					print "  $1\n";
				}
				print "\n" if $subseq eq "";
			}
		}
	}
}

#replace hits on a repeat region by individual repeat elements (with pfsearch/pfscan 2.3)
sub unroll_hits {
	my ($hits) = @_;
	for (my $i=0; $i<@$hits; $i++) {
		my ($subseq, $from, $to, $pfid, $pffrom, $pfto, $rawscore, $nscore, $leveln, $levelt, $seqde, $subhits) = @{$hits->[$i]};
		next unless $subhits and @$subhits;
		map {$_->[8]=$leveln; $_->[9]=$levelt; $_->[10]=$seqde} @$subhits;
		splice @$hits, $i--, 1, @$subhits;
	}

}

#sequence can be specified either as a filename or a string
sub do_pfscan {
	my ($PROSITE, $seqfile_to_scan, $sequence) = @_;

	return {} unless grep {$_->[2] eq "MATRIX"} @patterns;

	my %prosite;
	my $PFSCAN_TMP = tmpnam();
	my $level_arg = defined($opt_level) ? "$opt_level" : "0";

	#get the Level=0 and Level=-1 normalized/raw scores of the profile
	my $level_0;
	my $level_1;
	my $level_min=0;
	for my $cutoff (@{$patterns[0]->[6]}) {
		if ($cutoff->{LEVEL} eq 0) {
			if ($opt_raw) {$level_0=$cutoff->{SCORE};}
			else {$level_0 = $cutoff->{N_SCORE};}
		}
		if ($cutoff->{LEVEL} eq -1) {
			if ($opt_raw) {$level_1=$cutoff->{SCORE};}
			else {$level_1 = $cutoff->{N_SCORE};}
		}
		$level_min = $cutoff->{LEVEL} if $cutoff->{LEVEL}<$level_min;
	}

	#if option pfsearch is selected, get the user specified C=?? parameter
	my $cutoff = defined($opt_cutoff) ? "$opt_cutoff" : "$level_1";
	#(unless other is specified) for the detection of the repeats,
	#pfsearch is run as default at L=-1

	my(@pre_command, @post_command);
	if ($opt_pfsearch) {
		#detect format
		open DETECT, $seqfile_to_scan or die "Cannot open $seqfile_to_scan: $!";
		my $fasta="";
		while (<DETECT>) {
			next unless /\S/;
			$fasta = /^\s*>/ ? "-f" : "";
			last;
		}
		close DETECT;
		@pre_command = "$opt_pfsearch $fasta -lxz -v $PROSITE";
		@post_command = "C=$cutoff";
	}

	else {
		#if the user select a Level L higher than L=0 for match detection
		#the methods for the detection of repeats are not applied
		#otherwise pfscan is run as default at L<=-1
		if ($level_arg eq 0) {$level_arg=-1;}
		@pre_command = "$PFSCAN -flxz -v";
		@post_command = "$PROSITE L=$level_arg";
	}

	my $out;
	if ($SAFE_PIPE || defined $seqfile_to_scan) {
		my $seqfile;
		unless (defined $seqfile_to_scan) {
			$seqfile = tmpnam();
			open SEQ_TMP, ">$seqfile" or die "Cannot create $seqfile : $!";
			print SEQ_TMP ">seq for pfscan\n";
			print SEQ_TMP "$1\n" while $sequence =~ /(.{1,60})/g;
			close SEQ_TMP;
		}
		else {
			$seqfile = $seqfile_to_scan;
		}
		my $cmd = "@pre_command $seqfile @post_command > $PFSCAN_TMP";
		warn $cmd;
		system $cmd and die "Could not execute $cmd";
		unlink $seqfile unless defined $seqfile_to_scan;
		my $pfscan_fh = new IO::File($PFSCAN_TMP) or die "Cannot open $PFSCAN_TMP: $!";
		$out = scanProfiles($pfscan_fh, $level_min-1);
		close $pfscan_fh or die "Error $? with $PFSCAN_TMP";

	}
	else {
		#directly feed data to pfscan via pipe,
		#do not use any temporary files
		require IPC::Open2;
		my ($reader, $writer);
		my $cmd = "@pre_command - @post_command";
		warn $cmd;
		my $pid =
		eval {
			IPC::Open2::open2($reader, $writer, $cmd) or die "Could not fork pipe to $cmd: $!";
		};
		if ($@) {
			die "$@\n" . '>' x 62 . "\nERROR: 'pfscan' execution failed. Check pfscan is in your PATH\n" . '>' x 62 . "\n";
		}
		local $/ = \32767; #buffer size
		print $writer ">seq for pfscan\n";
		print $writer "$1\n" while $sequence =~ /(.{1,60})/g;
		close $writer;
		$out = scanProfiles($reader, $level_min-1);
		close $reader or die "Error $? with $cmd";
		waitpid $pid, 0; #avoid defunct kid processes
	}

	if ($opt_pfsearch) {
		#the use of the C=?? option deactivates the method of repeats detection
		unless(defined ($opt_cutoff)) {
			$out=sortRepeats2($out, $level_0, $level_1);
		}
	}
	else {
		#if the user select a Level L higher than L=0 for match detection
		#the methods for the detection of repeats are not applied
		#WARNINGS: there is a bug in pfscan, if the user specify a level L
		#for score match selection higher than the highest Level described
		#in the profile, pfscan report all the matches from the lowest to
		# the highest
		unless($opt_level>0) {
			$out=sortRepeats($out);
		}
	}

	#remove matches with level < opt_level
	for my $k (keys %$out) {
		my $v = $out->{$k};
		for (my $i=0; $i<@$v; $i++) {
			next unless defined $v->[$i]->[8] and $v->[$i]->[8] < $opt_level;
			splice @$v, $i--, 1;
		}
		delete $out->{$k} unless @$v;
	}



	unlink $PFSCAN_TMP;
	if ($opt_format eq "msa") {
		for my $ac (keys %$out) {
			open PFSCANTMP, ">$PFSCAN_TMP" or die "Cannot create $PFSCAN_TMP : $!";
			for (my $i=0; $i<@{$out->{$ac}}; $i++) {
				my $hit = $out->{$ac}->[$i];
				print PFSCANTMP ">$i\n$hit->[0]";
			}
			close PFSCANTMP;
			my $PSA2MSA_TMP = tmpnam();
			my $cmd = "$PSA2MSA $PFSCAN_TMP > $PSA2MSA_TMP";
			warn $cmd;
			system $cmd and die "Cannot execute $cmd";
			open MSATMP, $PSA2MSA_TMP or die "Cannot read $PSA2MSA_TMP : $!";
			my %msa;
			my $cur_pos;
			while(defined (local $_=<MSATMP>)) {
				if (/^>(\d+)/) {
					$cur_pos=$1;
				}
				elsif (defined $cur_pos) {
					$msa{$cur_pos}.=$_;
				}
			}
			close MSATMP;
			unlink $PSA2MSA_TMP;
			while (my ($number, $seq) = each %msa) {
				$out->{$ac}->[$number]->[0] = $seq;
			}
		}
	}
	return $out;
}

sub tmpnam {
	my $tmp;
	do {
		$tmp = $TMPDIR.$SLASH."ps".$TMP_COUNTER++.".tmp";
	} while (-e $tmp);
	return $tmp;
}

sub scanPatternWrapper {
	my ($args, $id) = @_;
	my $out = scanPattern(@$args);
	#in PSA format, remove the '.' character from inserts.
	#these can be reintroduced with the 'psa2msa' program.
	if ($opt_format eq "psa") {
		$_->[0] =~ s/\.//g for @$out;
	}
	if ($id) {
		$_->[3] = $id for @$out;
	}
	return $out;
}

sub scanRuleWrapper {
	my ($args, $id) = @_;
	my $out = scanRule(@$args);
	if ($id) {
		$_->[3] = $id for @$out;
	}
	return $out;
}

sub prositeToRegexpWrapper {
	my $out = prositeToRegexp(@_);
	unless (defined $out) {
		print STDERR "ps_scan.pl: Syntax error in pattern at position $Prosite::errpos\n";
		print STDERR "$_[0]\n";
		print STDERR " " x $Prosite::errpos, "^--- $Prosite::errstr\n";
		exit 1;
	}
	return $out;
}

sub promoteRepeats {
	my ($hits, $text) = @_;

	for my $hit (@$hits) {
		next unless $hit->[8] eq -1;
		$hit->[8] = 0;
		$hit->[9] = $text;
	}
}

sub sortRepeats {
	my ($out)=@_;
	my %sort;
	my %no_method_2;
	my $high;
	my $low;
	my $text;
	my $opt_level_value;

	#Create an hash named "sort", whose keys are the AC of profiles and whose values are arrays.
	#For each profile the array contains the sum of the L=0 cut-off and L=-1 cut-off values and
	#the L=0 associated text.
	for my $pat (@patterns) {
		my $sort_ac = $pat->[0];
		my $hits = $pat->[6];
		for my $hit (@$hits) {
			if ($hit->{LEVEL} eq 0) {
				$high = $hit->{N_SCORE};
				$text = $hit->{TEXT};
			}
			if ($hit->{LEVEL} eq -1) {
				$low = $hit->{N_SCORE};
				$no_method_2{$sort_ac}=1 if $hit->{TEXT} eq "'R?'";
			}
			$sort{$sort_ac}->[0]=($high+$low);
			$sort{$sort_ac}->[1]=$text;
			#the score value associated with the $opt_level is extracted as well
		}
	}

	#this array contain the highest cut-off level exceeded
	#by the match score in the output list as well
	for my $ac (keys %$out) {
		(my $sort_ac = $ac) =~ s/\|.*//;
		my $highest;
		for my $hit (@{$out->{$ac}}) {
			if (!defined($highest) or $hit->[8] > $highest) {
				$highest = $hit->[8];
			}
		}
		$sort{$sort_ac}->[2] = $highest;
	}

	#Two methods are applied to detect repeats matches:
	#NB: if the user select a Level L higher than 0 for match score detection
	#these two methods are not applied
	#1) Allow matches with score higher than L=-1 if the protein contains at least one match
	#with score higher than L=0.
	#In this case the output will be tagged with L='RR' (L='?RR' if option -a).
	#2) Allow matches with score higher than L=-1 if the sum of scores per protein is higher than
	#the sum of the value of cut-off at L=0 and of cut-off at L=1
	#In this case the output will be tagged with L='rr' (L='?rr' if option -a).

	for my $ac (keys %$out) {
		(my $sort_ac = $ac) =~ s/\|.*//;
		#if the the highest cut-off level exceeded is L=-1,
		#compute sum of scores per protein and apply method 2
		if ($sort{$sort_ac}->[2] eq -1 and !exists $no_method_2{$sort_ac}) {
			my $sum=0;
			for my $hit (@{$out->{$ac}}) {
				if ($hit->[8] eq -1) {
					$sum += $hit->[7];
				}
			}
			#discard hits if necessary
			if ($sum < $sort{$sort_ac}->[0]) {
				delete $out->{$ac} if $opt_level > -1;
			}
			#tag output with L='r' for repeats
			else {
				if ($sort{$sort_ac}->[1] eq '\'R\'') {
					&promoteRepeats($out->{$ac}, 'rr');
				}
				elsif ($sort{$sort_ac}->[1] eq '\'!\'') {
					#discard hits if necessary
					if (!($opt_allprofiles)) {
						delete $out->{$ac} if $opt_level > -1;
					}
					#tag output L='?r' if option -a
					else {
						&promoteRepeats($out->{$ac}, '?rr');
					}
				}
			}
		}

		#if the the highest cut-off level exceeded is L=0 or more, apply method 1
		elsif ($sort{$sort_ac}->[2] > -1) {
			# tag the output for repeats with 'R'
			if ($sort{$sort_ac}->[1] eq '\'R\'') {
				&promoteRepeats($out->{$ac}, 'RR');
			}
			# if option -a tag the output for profiles with L='?R'
			elsif ($sort{$sort_ac}->[1] eq '\'!\'') {
				if ($opt_allprofiles) {
					&promoteRepeats($out->{$ac}, '?RR');
				}
				#discard hits if necessary
				else {
					for (my $i=0; $i<@{$out->{$ac}};$i++) {
						if ($out->{$ac}->[$i]->[8] eq -1 and $opt_level>-1) {
							splice(@{$out->{$ac}}, $i--, 1);
						}
					}
				}
			}
		}
	}
	return $out;
}

sub sortRepeats2 {
	my ($out, $high, $low)=@_;

	my %sort;
	my $text;
	my $no_method_2;

	for my $cf (@{$patterns[0]->[6]}) {
		if ($cf->{LEVEL} eq 0) {
			$text=$cf->{TEXT};
		}
		elsif ($cf->{LEVEL} eq -1) {
			$no_method_2=1 if $cf->{TEXT} eq "'R?'";
		}
	}

	#Create a hash named "sort", whose keys are the AC of the sequences and the values
	#are the highest cut-off level exceeded by the match score in the output list
	for my $ac (keys %$out) {
		my $sort_ac = $ac;
		my $highest=$out->{$ac}->[0]->[8];
		for my $hit (@{$out->{$ac}}) {
			if ($hit->[8] > $highest) {$highest = $hit->[8] ;
			}
		}
		$sort{$sort_ac}=$highest;
	}

	#Two methods are applied to detect repeats matches:
	#1) Allow matches with score higher than L=-1 if the protein contains at least one match
	#with score higher than L=0.
	#In this case the output will be tagged with L='R' (L='?R' if option -a).
	#2) Allow matches with score higher than L=-1 if the sum of scores per protein is higher than
	#the sum of the value of cut-off at L=0 and of cut-off at L=1
	#In this case the output will be tagged with L='r' (L='?r' if option -a).

	for my $ac (keys %$out) {
		my $sort_ac = $ac;
		#if the the highest cut-off level exceeded is L=-1,
		#compute sum of scores per protein and apply method 2
		if ($sort{$sort_ac} eq -1 and !$no_method_2) {
			my $sum=0;
			for my $hit (@{$out->{$ac}}) {
				if ($hit->[8] eq -1) {
					if ($opt_raw) {$sum += $hit->[6];}
					else {$sum += $hit->[7];}
				}
			}
			#discard hits if necessary
			if ($sum<($high+$low)) {
				delete $out->{$ac} if $opt_level > -1;
			}
			#tag output with L='r' for repeats
			else {
				if ($text eq '\'R\'') {
					&promoteRepeats($out->{$ac}, 'rr');
				}
				elsif ($text eq '\'!\'') {
					if ($opt_allprofiles) {
						&promoteRepeats($out->{$ac}, '?rr');
					}
					else {
						delete $out->{$ac} if $opt_level > -1;
					}
				}
			}
		}
		#if the the highest cut-off level exceeded is L=0 or more, apply method 1
		elsif($sort{$sort_ac} > -1) {
			if ($text eq '\'R\'') {
				&promoteRepeats($out->{$ac}, 'RR');
			}
			# if option -a tag the output for profiles with L='?R'
			elsif($text eq '\'!\'') {
				if ($opt_allprofiles) {
					&promoteRepeats($out->{$ac}, '?RR');
				}
				#discard hits if necessary
				else {
					for(my $i=0; $i<@{$out->{$ac}};$i++) {
						if ($out->{$ac}->[$i]->[8] eq -1 and $opt_level>-1) {
							splice(@{$out->{$ac}}, $i--, 1);
						}
					}
				}
			}
		}
	}
	return $out;
}

sub scanSeq_pfsearch {
	my $pfhits;
	my $sq="";
	my $hits;
	my($seqfile)=@_;

	#if option -s has been selected
	if (@patterns) {
		die "FATAL: You are using option -w with a file containing more than one profile" if @patterns>1;
		for (@patterns) {
			my ($psac, $psid, $type, $psde, $pat, $skip) = @$_;
			if ($skip) {
				die "FATAL: You are using option -s with a profile with a skip-flag tag";
			}
			if ($type ne "MATRIX") {
				die "FATAL: You are using option -w with an entry not of type MATRIX";
			}
		}
	}

	if ($opened_profile_tmp) {
			$pfhits = do_pfscan($PROFILE_TMP, $seqfile);
	}

	else {
		die "Cannot scan several prosite files for profiles" if @prosite_files>1;
		$pfhits = do_pfscan($prosite_files[0], $seqfile);
	}


	for my $id (keys %$pfhits) {
		dispHits(undef, $sq, $pfhits->{$id}, $id);
	}
}
