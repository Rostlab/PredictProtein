#!/usr/bin/perl
##!/usr/local/bin/perl
##!/usr/local/bin/perl -w

# Copyright (c) 1997-1999 Nigel P. Brown. \$Id: mview,v 1.41 1999/03/18 19:27:04 nbrown Exp $

require 5.004;

$^W=1;

#use lib '/home/liu/src/mview-1.41.8/lib';
#use lib '/home/$ENV{USER}/server/pub/mview/lib'; # HARD_CODED
use lib "/nfs/data5/users/$ENV{USER}/server/pub/mview/lib"; # HARD_CODED
use Getopt;
use Bio::MView::Manager;
use strict;

###########################################################################
my $PROG    = Universal::basename($0);
my $INVOKE  = "$PROG @ARGV";
my $SERVER  = 'http://mathbio.nimr.mrc.ac.uk';
my $DOCTYPE = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">';
my $SCRATCH = "/usr/tmp/mview_$$";

my %KNOWN_FORMAT =
    (
     #search formats
     'blast'     => 1,
     'fasta'     => 1,

     #flatfile formats
     'plain'     => 1,
     'clustal'   => 1,
     'msf'       => 1,
     'pearson'   => 1,
     'pir'       => 1,
     'hssp'      => 1,
     'multas'    => 1,
     'mips'      => 1,
    );

my ($HTML_NULL, $HTML_DATA, $HTML_CSS, $HTML_BODY, $HTML_HTML, $HTML_MIME) =
    (0,1,2,4,8,16);
my ($VERB_NULL, $VERB_FILE, $VERB_ARGV, $VERB_FORM) = (0,1,2,4);
my ($stm, $com, $opt, $par) = (\*STDOUT);


###########################################################################
$SIG{'INT'} = sub { warn "$PROG: exiting on interrupt\n"; cleanup(); exit 1 };

$com = new Getopt($PROG, \*DATA)->getoptions(\@ARGV);
$opt = $com->get_option_hash;
$par = $com->get_parameter_hash;

rationalise_parameters($opt, $par);

usage($com, $opt, $par, 1)             if $opt->{'help'};
list_colormaps($com, $opt, $par, 1)    if $opt->{'listcolors'};
list_groupmaps($com, $opt, $par, 1)    if $opt->{'listgroups'};

html_head($opt, $par, $stm);

#echo command line?
if ($opt->{'verbose'} & $VERB_ARGV) {
    my $s = $com->argv_string;
    $s =~ s/\-+v[a-z]*[=\s]+\S+\s*//g;
    if ($opt->{'html'}) {
	print $stm "<H4>command line:</H4>\n<CODE>";
	print $stm "$PROG $s";
	print $stm "</CODE>\n<H4>produced:</H4>\n";
    } else {
	print $stm "command line:\n";
	print $stm "$PROG $s\n";
	print $stm "produced:\n\n";
    }
}

#leading copyright?
if ($opt->{'out'} eq 'rdb') {
    copyright($opt, $stm);
}

#read from stdin?
if (@ARGV < 1) {
    open(TMP, ">$SCRATCH") or die "$PROG: can't open temp file '$SCRATCH'\n";
    while (<>) { print TMP }
    close TMP;
    push @ARGV, $SCRATCH;
}
	
mview($opt, $par, $stm, @ARGV);

#trailing copyright?
if ($opt->{'html'} != $HTML_DATA and $opt->{'out'} =~ /^(?:new|old)/) {
    copyright($opt, $stm);
}

html_foot($opt, $par, $stm);

#Universal::vmstat("FINISHED.");

cleanup();


###########################################################################
sub mview {
    my ($opt, $par, $stm) = (shift, shift, shift);
    my ($mgr, $file);

    #Universal::vmstat("Manager constructor");

    $mgr = new Bio::MView::Manager(%$par);

    foreach $file (@_) {
	unless (-f $file) {
	    warn "$PROG: can't open file '$file'\n";
	    next;
	}
        warn "$PROG: processing '$file'\n"
	    if $opt->{'verbose'} & $VERB_FILE;

        warn "$PROG: format is probably '@{[check_format($file)]}'\n"
	    if !defined $opt->{'in'} and $opt->{'verbose'} & $VERB_FORM;

	print $stm "<PRE>\n"    if $opt->{'pre'};

 	if (defined $opt->{'in'}) {
	    $mgr->parse($file, $opt->{'in'});
	} else {
	    $mgr->parse($file, check_format($file));
	}

	print $stm "</PRE>\n"   if $opt->{'pre'};
    }
    #Universal::vmstat("Manager constructor done");

    #save printing until end?
    if ($par->{'register'} and
	($opt->{'out'} eq 'new' or $opt->{'out'} eq 'old')) {
	$mgr->print;
	#Universal::vmstat("print done (mview)");
    }
}

sub cleanup { unlink "$SCRATCH"    if -f "$SCRATCH" }

sub rationalise_parameters {
    my ($o, $p) = @_;

    #ignore HTML if RDB output
    ($o->{'html'}, $p->{'html'}) = (0, 0)
	if $o->{'out'} eq 'rdb';

    #switch off preformatted flag if HTML is off
    $o->{'pre'} = 0
	unless $o->{'html'};

    #ignore style sheets if HTML off
    ($o->{'css'}, $p->{'css1'})  = ('off', 0)
	if $o->{'html'} == 0;

    #ignore style sheets in HTML if css is unset
    $o->{'html'} &= ($HTML_MIME|$HTML_HTML|$HTML_BODY|$HTML_DATA)
	if $o->{'css'} eq 'off';
}

sub html_head {
    my ($o, $p, $s) = (@_, *STDOUT);

    #warn "HTML=$o->{'html'}\n";

    return    unless $o->{'html'};
    return    if $o->{'html'} == $HTML_DATA;

    #special case: dump CSS only
    if ($o->{'html'} == $HTML_CSS) {
	#http://www.w3.org/TR/REC-CSS1#containment-in-html
	print $s Bio::MView::Align::print_css1_colormaps
	    ('alncolor' => $p->{'alncolor'},
	     'symcolor' => $p->{'symcolor'},
	     'gapcolor' => $p->{'gapcolor'},
	    );
	cleanup();
	exit(0);
    }

    #want MIME type?
    if ($o->{'html'} & $HTML_MIME) {
	print $s "Content-Type: text/html\n\n";
    }

    #want HTML HEAD?
    if ($o->{'html'} & $HTML_HTML) {

	print $s "$DOCTYPE\n<HTML>\n<HEAD>\n";

	#want STYLE?
	if ($o->{'html'} & $HTML_CSS) {
	    
	    #link styles
	    print $s "<STYLE TYPE=\"text/css\">\n<!--\n";
	    print $s "A:link{background:transparent;color:$o->{'linkcolor'}}\n";
	    print $s "A:active{background:transparent;color:$o->{'alinkcolor'}}\n";
	    print $s "A:visited{background:transparent;color:$o->{'vlinkcolor'}}\n";
	    print $s "-->\n</STYLE>\n";
	    
	    #alignment styles
	    if ($o->{'css'} =~ /^(?:file|http):/i) {
		#link to style sheet
	        print $s "<LINK REL=STYLESHEET HREF=\"$o->{'css'}\">\n";
	    } else {
		#style sheet in situ
		print $s "<STYLE TYPE=\"text/css\">\n<!--\n";
		print $s Bio::MView::Align::print_css1_colormaps
		    ('alncolor' => $p->{'alncolor'},
		     'symcolor' => $p->{'symcolor'},
		     'gapcolor' => $p->{'gapcolor'},
		    );
		print $s "-->\n</STYLE>\n";
	    }
	}

	#want TITLE? (in titlebar)
	if (defined $o->{'title'}) {
	    print $s "<TITLE>$o->{'title'}</TITLE>\n";
	}

	print $s "</HEAD>\n";
    }

    #want BODY?
    if ($o->{'html'} & $HTML_BODY) {
	print $s "<BODY BGCOLOR='$o->{'pagecolor'}' TEXT='$o->{'textcolor'}' LINK='$o->{'linkcolor'}' ALINK='$o->{'alinkcolor'}' VLINK='$o->{'vlinkcolor'}'>\n";
    }

    #want TITLE? (in document)
    if (defined $o->{'title'}) {
	print $s "<H1>$o->{'title'}</H1>\n";
    }
}

sub html_foot {
    my ($o, $p, $s) = (@_, *STDOUT);
    return    unless $o->{'html'};
    return    if $o->{'html'} == $HTML_DATA;
    print $s "</BODY>\n"    if $o->{'html'} & $HTML_BODY;
    print $s "</HTML>\n"    if $o->{'html'} & $HTML_HTML;
}

sub check_format {
    return map { lc $_ } sort keys %KNOWN_FORMAT    unless @_;

    my @s = (Universal::basename($_[0]));

    if ($s[0] =~ /(.*)\.(.+)/) {
	#get basename and filename extension
	@s = ($2, $1); 
    }

    #try extension (if any), then basename
    foreach (@s) {

	#search formats
	return 'BLAST'    if $_ =~ /^.?bl/i;
	return 'FASTA'    if $_ =~ /^.?fa/i;
	
	#flatfile formats
	return 'Plain'    if $_ =~ /^pl/i;
	return 'CLUSTAL'  if $_ =~ /^cl/i;
	return 'MSF'      if $_ =~ /^ms/i;
	return 'Pearson'  if $_ =~ /^pe/i;
	return 'PIR'      if $_ =~ /^pi/i;
	return 'HSSP'     if $_ =~ /^hs/i;
	return 'MULTAS'   if $_ =~ /^mu/i;
	return 'MIPS'     if $_ =~ /^mi/i;
    }
	
    #unknown format
    warn "$PROG: can't determine format of '$_[0]'\n";
    cleanup();
    exit 1;
}

sub usage {
    my ($com, $opt, $par, $exit, $stm) = (@_, *STDOUT);
    $opt->{'title'} = 'MView command line options';
    html_head($opt, $par, $stm);
    print $stm "<HR><PRE>\n"       if $opt->{'html'};
    $com->usage($stm);
    print $stm "</PRE><HR>\n"      if $opt->{'html'};
    copyright($opt, $stm);
    html_foot($opt, $par, $stm);
    exit $exit    if $exit;
}

sub list_colormaps {
    my ($com, $opt, $par, $exit, $stm) = (@_, *STDOUT);
    $opt->{'title'} = 'MView colormap listing';
    html_head($opt, $par, $stm);
    print $stm "<HR><PRE>\n"       if $opt->{'html'};
    print $stm Bio::MView::Manager::list_colormaps($opt->{'html'});
    print $stm "</PRE><HR>\n"      if $opt->{'html'};
    copyright($opt, $stm)          if $opt->{'html'};
    html_foot($opt, $par, $stm);
    exit $exit    if $exit;
}

sub list_groupmaps {
    my ($com, $opt, $par, $exit, $stm) = (@_, *STDOUT);
    $opt->{'title'} = 'MView consensus group listing';
    html_head($opt, $par, $stm);
    print $stm "<HR><PRE>\n"       if $opt->{'html'};
    print $stm Bio::MView::Manager::list_groupmaps($opt->{'html'});
    print $stm "</PRE><HR>\n"      if $opt->{'html'};
    copyright($opt, $stm)          if $opt->{'html'};
    html_foot($opt, $par, $stm);
    exit $exit    if $exit;
}

sub copyright {
    my ($opt, $stm) = @_;
    my $s;
    no strict;

    BEGIN {
        $_version = '$RCSfile: mview,v $ $Revision: 1.41 $';#';
        $_version =~ s/(RCSfile: |Revision: |,v)//g;
        $_version =~ s/\$//g;
        $_version =~ s/\s+/ /g;
        ($_prog, $_version) = split(/ +/, $_version);
        $_prog =~ s/^mv/MV/;
    }

    if ($opt->{'out'} eq 'rdb') {
        $s  = "# $_prog $_version, Copyright (C) Nigel P. Brown, 1997-1999.\n";
	$s .= "# $INVOKE\n";
	print $stm $s;
	return;
    }

    if ($opt->{'html'}) {
        $s  = "<P><SMALL><A HREF=\"$SERVER/~nbrown/mview/\">$_prog</A> ";
        $s .= "$_version, Copyright \&copy; ";
        $s .= "<A HREF=\"$SERVER/~nbrown/\">Nigel P. Brown</A>, 1997-1999.";
        $s .= "</SMALL><BR>\n";
	print $stm $s;
	return;
    }

    $s  = "\n$_prog $_version, Copyright (C) Nigel P. Brown, 1997-1999.\n\n";
    print $stm $s;
}


###########################################################################
__DATA__

text:     "usage: __PROG [options] [file...]\n\n
Some of these options take multiple arguments which must be supplied\n
as a comma separated list. Integral subranges therein are allowed, eg.,\n
'1,2,5..10,20'. The list must be quoted if it contains whitespace or a\n
wildcard that might be expanded by the shell. Optional parameter values are\n
given between braces {}; defaults are given in square brackets [].\n"


###########################################################################
#silent options because no 'usage:' field.
[SILENT]

#force @ARGV to be examined for '-help' first.
OPTION:   help
default:  0
action:   sub { __ARGS; __OPTION{__ON} = 1    if __OV }

#force @ARGV to be examined for '-listcolors' first.
OPTION:   listcolors
default:  0
action:   sub { __ARGS; __OPTION{__ON} = 1    if __OV }

#force @ARGV to be examined for '-listgroups' first.
OPTION:   listgroups
default:  0
action:   sub { __ARGS; __OPTION{__ON} = 1    if __OV }

#force @ARGV to be examined for '-colorfile' first.
OPTION:   colorfile
type:     s
action:   sub { __ARGS;
              local *TMP;
              if (defined __OV) {
                  open(TMP, "< __OV") or CORE::die "__PROG: can't open colormap file '__OV'\n";
                  Bio::MView::Manager::load_colormaps(\*TMP);
                  close TMP;
              }
          }

#force @ARGV to be examined for '-groupfile' first.
OPTION:   groupfile
type:     s
action:   sub { __ARGS;
              local *TMP;
              if (defined __OV) {
                  open(TMP, "< __OV") or CORE::die "__PROG: can't open consensus group file '__OV'\n";
                  Bio::MView::Manager::load_groupmaps(\*TMP);
                  close TMP;
              }
          }

#verbosity level, normally 0 to keep quiet
OPTION:   verbose
type:     i
default:  0

#obsolete options: report fact to user
OPTION:   body
action:   sub { __ARGS; __WARN("obsolete option '-__ON' replaced by '-html', see '-help'.") if defined __OV; }

OPTION:   quiet
action:   sub { __ARGS; __WARN("obsolete hidden option '-__ON' replaced by '-verbose'.") if defined __OV; }

OPTION:   contrast
action:   sub { __ARGS; __WARN("obsolete option '-__ON' replaced by '-alncolor/-symcolor/-gapcolor'.") if defined __OV; }


###########################################################################
[FORMATS]

text:     "Input/output formats:"

OPTION:   in
usage:    "Input format __CHOOSE(main::check_format)"
type:     s
action:   sub { __ARGS;
		return __OPTION{__ON} = main::check_format(__OV)
		    if defined __OV;
		return;
	  }

OPTION:   out
usage:    "Output format __CHOOSE(Bio::MView::Manager::check_display_mode)"
type:     s
default:  new
param:    mode
convert:  sub { __ARGS;
		__OPTION{'pre'} = 1;
		if (__OV =~ /^o/i) {
		    __PV = 'old'; __OPTION{'pre'} = 0;
		} elsif (__OV =~ /^n/i) {
		    __PV = 'new'; __OPTION{'pre'} = 0;
		} elsif (__OV =~ /^r/i) {
		    __PV = 'rdb'; __OPTION{'pre'} = 0;
		} elsif (__OV =~ /^pe/i) {
		    __PV = 'pearson';
		} elsif (__OV =~ /^pi/i) {
		    __PV = 'pir';
		} elsif (__OV =~ /^ms/i) {
		    __PV = 'msf';
		} else {
		    __WARN("unknown output format '-__ON=__OV'.");
		}   
		__PV;
	  }


###########################################################################
[CONTENT]

text:     "Main formatting options:"

OPTION:   ruler
usage:    "Show ruler"
type:     b
default:  off
param:

OPTION:   alignment
usage:    "Show alignment"
type:     b
default:  on
param:

OPTION:   consensus
usage:    "Show consensus"
type:     b
default:  off
param:

OPTION:   dna
usage:    "Use DNA/RNA colormaps and/or consensus groups"
default:  0
action:   sub { __ARGS;
	    __OV = Bio::MView::Manager::check_molecule_type(__OV ? 'na':'aa');
	    (__PARAM{'def_aln_colormap'}, __PARAM{'def_con_colormap'}) =
		Bio::MView::Manager::get_default_colormaps(__OV);
	    __PARAM{'def_aln_groupmap'} = __PARAM{'def_con_groupmap'} =
		Bio::MView::Manager::get_default_groupmap(__OV);
          }


###########################################################################
[ALN]

text:     "Alignment options:"

OPTION:   coloring
usage:    "Basic style of coloring __CHOOSE(Bio::MView::Manager::check_alignment_color_scheme)"
type:     s
default:  none
param:    aln_coloring
convert:  sub { __ARGS;
		if (__OV =~ /^n/i) {
		   __PV = 'none';
	       } elsif (__OV =~ /^a/i) {
		   __PV = 'any';
	       } elsif (__OV =~ /^i/i) {
		   __PV = 'identity';
	       } elsif (__OV =~ /^c/i) {
		   __PV = 'consensus';
	       } elsif (__OV =~ /^g/i) {
		   __PV = 'group';
               }
               unless (defined __PV and defined
		       Bio::MView::Manager::check_alignment_color_scheme(__PV)) {
		   __WARN("unknown coloring scheme '-__ON=__OV'.");
		   __WARN("known color schemes are: ", join(",",
		   Bio::MView::Manager::check_alignment_color_scheme), "\n");
	       }
               __PV;
          }

OPTION:   colormap
usage:    "Name of colormap to use"
type:     s
param:    aln_colormap
convert:  sub { __ARGS;
              if (defined __OV) {
                  __PV = __OV;
              } else {
                  __PV = __PARAM{'def_aln_colormap'};
              }
              __PV = Bio::MView::Manager::check_colormap(__PV);
              unless (defined __PV) {
                  __WARN("unknown colormap '-__ON=__OV'.");
		  __WARN("known maps are: ", join(",",
			 Bio::MView::Manager::check_colormap), "\n");
              }
	      __DELETE_PARAM('def_aln_colormap');
              __PV;
          }

OPTION:   groupmap
usage:    "Name of groupmap to use if coloring by consensus"
type:     s
param:    aln_groupmap
convert:  sub { __ARGS;
              if (defined __OV) {
                  __PV = __OV;
              } else {
                  __PV = __PARAM{'def_aln_groupmap'};
              }
              __PV = Bio::MView::Manager::check_groupmap(__PV);
              unless (defined __PV) {
                  __WARN("unknown groupmap '-__ON=__OV'.");
		  __WARN("known maps are: ", join(",",
			 Bio::MView::Manager::check_groupmap), "\n");
              }
              __DELETE_PARAM('def_aln_groupmap');
              __PV;
          }

OPTION:   threshold
usage:    "Threshold percentage for consensus coloring"
type:     f
default:  70
param:    aln_threshold
convert:  sub { __ARGS;
              if (__OV < 50 or __OV > 100) {
                  __WARN("bad value for '-__ON=__OV' must be in range 50..100.");
              }
              [ __OV ];
          }

OPTION:   ignore
usage:    "Ignore singleton or class groups __CHOOSE(Bio::MView::Manager::check_ignore_class)"
type:     s
default:  none
param:    aln_ignore
convert:  sub { __ARGS;
            __PV = Bio::MView::Manager::check_ignore_class(__OV);
            if (!defined __PV) {
              __WARN("unknown alignment ignore mode '-__ON=__OV'.");
              __WARN("known ignore classes are: ", join(",",
                     Bio::MView::Manager::check_ignore_class), "\n");
            }
            __PV;
          }


###########################################################################
[CON]

text:     "Consensus options:"

OPTION:   con_coloring
usage:    "Basic style of coloring __CHOOSE(Bio::MView::Manager::check_consensus_color_scheme)"
type:     s
default:  none
param:    con_coloring
convert:  sub { __ARGS;
	       if (__OV =~ /^n/i) {
		   __PV = 'none';
	       } elsif (__OV =~ /^a/i) {
		   __PV = 'any';
	       } elsif (__OV =~ /^i/i) {
		   __PV = 'identity';
	       } elsif (__OV =~ /^c/i) {
		   __PV = 'consensus';
	       } elsif (__OV =~ /^g/i) {
		   __PV = 'group';
               }
               unless (defined __PV and defined
		       Bio::MView::Manager::check_consensus_color_scheme(__PV)) {
		  __WARN("unknown coloring scheme '-__ON=__OV'.");
		  __WARN("known color schemes are: ", join(",",
			 Bio::MView::Manager::check_consensus_color_scheme), "\n");
	       }
               __PV;
          }

OPTION:   con_colormap
usage:    "Name of colormap to use"
type:     s
param:    con_colormap
convert:  sub { __ARGS;
              if (defined __OV) {
                  __PV = __OV;
              } else {
                  __PV = __PARAM{'def_con_colormap'};
              }
              __PV = __PARAM{'def_con_colormap'} unless defined __OV;
              __PV = Bio::MView::Manager::check_colormap(__PV);
              unless (defined __PV) {
                  __WARN("unknown colormap '-__ON=__OV'.");
		  __WARN("known maps are: ", join(",",
			 Bio::MView::Manager::check_colormap), "\n");
              }
              __DELETE_PARAM('def_con_colormap');
              __PV;
          }

OPTION:   con_groupmap
usage:    "Name of groupmap to use if coloring by consensus"
type:     s
param:    con_groupmap
convert:  sub { __ARGS;
              if (defined __OV) {
                  __PV = __OV;
              } else {
                  __PV = __PARAM{'def_con_groupmap'};
              }
              __PV = Bio::MView::Manager::check_groupmap(__PV);
              unless (defined __PV) {
                  __WARN("unknown groupmap '-__ON=__OV'.");
		  __WARN("known maps are: ", join(",",
			 Bio::MView::Manager::check_groupmap), "\n");
              }
              __DELETE_PARAM('def_con_groupmap');
              __PV;
          }

OPTION:   con_threshold
usage:    "Consensus line thresholds"
type:     @f
default:  '100,90,80,70'
param:    con_threshold
convert:  sub { __ARGS;
              local $_;
              foreach (@{__PV}) {
                if ($_ < 50 or $_ > 100) {
                  __WARN("bad range for '-__ON=$_' must be in range 50..100.");
                }
              }
              __PV;
          }

OPTION:   con_ignore
usage:    "Ignore singleton or class groups __CHOOSE(Bio::MView::Manager::check_ignore_class)"
type:     s
default:  none
param:    con_ignore
convert:  sub { __ARGS;
            __PV = Bio::MView::Manager::check_ignore_class(__OV);
            if (!defined __PV) {
              __WARN("unknown consensus ignore mode '-__ON=__OV'.");
              __WARN("known ignore classes are: ", join(",",
                     Bio::MView::Manager::check_ignore_class), "\n");
            }
            __PV;
          }


###########################################################################
[HYBRID]

text:     "Hybrid alignment and consensus options:"

OPTION:   con_gaps
usage:    "Count gaps during consensus computations if set to 'on'"
type:     b
default:  on
param:


###########################################################################
[MAPS]

text:     "User defined colormap and consensus group definition:"

OPTION:   colorfile
usage:    "Load more colormaps from file"

OPTION:   groupfile
usage:    "Load more groupmaps from file"


###########################################################################
[FILTER]

text:     "General row/column filters:"

OPTION:   top
usage:    "Report top N hits"
type:     s
default:  all
param:    topn
convert:  sub { __ARGS;
            return 0    if __OV eq 'all';
	    return __TEST('i', __ON, __OV);
	  }

OPTION:   range
usage:    "Display column range M..N as numbered by ruler"
type:     s
default:  all
param:
convert:  sub { __ARGS;
            my @tmp = ();
            if (__OV ne 'all') {
		@tmp = split(/:/, __OV);
		if (@tmp != 2) {
		    __WARN("bad range setting '-__ON=__OV', want M:N.");
		} else {
		    __TEST('i', __ON, $tmp[0]);
		    __TEST('i', __ON, $tmp[1]);
		    #ignore range order, but check for negative values
		    if ($tmp[0] < 1 or $tmp[1] < 1) {
			__WARN("bad range setting '-__ON=__OV', want M..N.");
		    }
		}
            }
	    return [ @tmp ];
	  }

OPTION:   maxident
usage:    "Only report sequences with  percent identity <= N"
type:     f
default:  100
param:
convert:  sub { __ARGS; 
		if (__OV < 0 or __OV > 100) {
		    __WARN("bad setting '-__ON=__OV', want range 0..100.");
		}
		__OV;
	  }

OPTION:   ref
usage:    "Use row N or row identifier as %identity reference"
type:     s
default:  query
param:    ref_id

OPTION:   keep
usage:    "Keep rows 1..N or row identifiers"
type:     @s
param:    keeplist

OPTION:   disc
usage:    "Discard rows 1..N or row identifiers"
type:     @s
param:    disclist

OPTION:   nops
usage:    "Display rows 1..N or row identifiers unprocessed"
type:     @s
param:    nopslist


###########################################################################
[GENERALFORMAT]

text:     "General formatting options:"

OPTION:   width
usage:    "Paginate in N columns of alignment"
type:     s
default:  flat
param:    
convert:  sub { __ARGS;
            if (__OV eq 'flat') {
              return 0;
	    } else {
              return __TEST('i', __ON, __OV);
	    }
	  }

OPTION:   gap
usage:    "Use this gap character"
type:     s
default:  -
param:    

OPTION:   label0
usage:    "Switch off label {0= row number}"
default:  0
param:    
convert:  sub { __ARGS; (__OV ? 0 : 1) }

OPTION:   label1
usage:    "Switch off label {1= identifier}"
default:  0
param:    
convert:  sub { __ARGS; (__OV ? 0 : 1) }

OPTION:   label2
usage:    "Switch off label {2= description}"
default:  0
param:    
convert:  sub { __ARGS; (__OV ? 0 : 1) }

OPTION:   label3
usage:    "Switch off label {3= scores}"
default:  0
param:    
convert:  sub { __ARGS; (__OV ? 0 : 1) }

OPTION:   label4
usage:    "Switch off label {4= percent identity}"
default:  0
param:    
convert:  sub { __ARGS; (__OV ? 0 : 1) }

OPTION:   register
usage:    "Output multi-pass alignments with columns in register"
type:     b
default:  on
param:

###########################################################################
[HTML]

text:     "HTML markup options:"

OPTION:   html
usage:    "Controls amount of HTML markup {full,head,body,data,css,off}"
type:     s
default:  off
param:
convert:  sub { __ARGS;
		if (__OV =~ /^full/i) {
		    __OPTION{__ON} = (16|8|4|2|1);
		    return 1;
		}
		if (__OV =~ /^head/i) {
		    __OPTION{__ON} = (8|4|2|1);
		    return 1;
		}
		if (__OV =~ /^body/i) {
		    __OPTION{__ON} = (4|2|1);
		    return 1;
		}
		if (__OV =~ /^css/i) {
		    __OPTION{__ON} = (2);
		    return 0;
		}
		if (__OV =~ /^data/i) {
		    __OPTION{__ON} = (1);
		    return 1;
		}
		if (__OV =~ /^off/i) {
		    __OPTION{__ON} = 0;
		    return 0;
		}
		__WARN ("unknown setting '-__ON=__OV'");
	    }

OPTION:   title
usage:    "Page title string"
type:     s
default:  ""

OPTION:   pagecolor
usage:    "Page backgound color"
type:     s
default:  #FFFFFF

OPTION:   textcolor
usage:    "Page text color"
type:     s
default:  black

OPTION:   linkcolor
usage:    "Link color"
type:     s
default:  blue
param:

OPTION:   alinkcolor
usage:    "Active link color"
type:     s
default:  red
param:

OPTION:   vlinkcolor
usage:    "Visited link color"
type:     s
default:  purple
param:

OPTION:   alncolor
usage:    "Alignment background color"
type:     s
default:  #FFFFFF
param:

OPTION:   symcolor
usage:    "Alignment default text color"
type:     s
default:  #222222
param:

OPTION:   gapcolor
usage:    "Alignment gap color"
type:     s
default:  #666666
param:

OPTION:   css
usage:    "Use Cascading Style Sheets {off,on,URL}"
type:     s
default:  off
param:    css1
convert:  sub { __ARGS;
		#supplied style sheet URL
		return 1    if __OV =~ /^(?:file|http):/i;
		if (__OV ne 'on' and __OV ne 'off' and __OV ne '0' and __OV ne '1') {
		    __WARN("bad value for '__ON=__OV' want {on,off,URL} or {0,1,URL}");
		}
		return 1    if __OV eq 'on' or __OV eq '1';
		return 0;
          }

OPTION:   bold
usage:    "Use bold emphasis for coloring sequence symbols"
default:  0
param:
convert:  sub { __ARGS; __OV > 0 ? 1 : 0 }

OPTION:   srs
usage:    "Try to use SRS links {off,on,gq}"
type:     s
default:  off
action:   sub { __ARGS;
		if (__OV eq 'off') {
		    return $Bio::SRS::Type = 0;
		} elsif (__OV eq 'on') {
		    return $Bio::SRS::Type = 1;
		} elsif (__OV eq 'gq') {
		    return $Bio::SRS::Type = 2;
		} else {
		    __WARN("bad SRS setting,  want {off,on,gq}.");
		}
		return $Bio::SRS::Type = 1;    #default
	    }


###########################################################################
[GENERICBLAST]

OPTION:   hsp
type:     s
default:  ranked
param:    
convert:  sub { __ARGS;
		return 'all'      if __OV =~ /^a/;
		return 'discrete' if __OV =~ /^d/;
	        return 'ranked'   if __OV =~ /^r/;
		__WARN("bad setting '-__ON=__OV'.");
		__WARN("known hsp methods are: ", join(",",
		Bio::MView::Manager::check_hsp_tiling), "\n");
	      }

OPTION:   maxeval
type:     s
default:  unlimited
param:    
convert:  sub { __ARGS;
		return undef    if __OV eq 'unlimited';
		__TEST('f', __ON, __OV);
		__WARN("bad setting '-__ON=__OV', want > 0.") if __OV < 0;
		__OV;
	  }

OPTION:   minbits
type:     s
default:  unlimited
param:    
convert:  sub { __ARGS;
		return undef    if __OV eq 'unlimited';
		__TEST('i', __ON, __OV);
		__WARN("bad setting '-__ON=__OV', want > 0.") if __OV < 0;
		__OV;
	  }

OPTION:   strand
type:     @s
default:  *
param:
convert:  sub { __ARGS;
              local $_; my @tmp=();
              foreach (@{__PV}) {
                if      ($_ eq 'p' or $_ eq 'P') {
		    push @tmp, '+';
		} elsif ($_ eq 'm' or $_ eq 'M') {
		    push @tmp, '-';
		} elsif ($_ eq '*') {
		    @tmp = ('*');
		    last;
		} else {
                  __WARN("bad value for '-__ON=$_' choose from '{p,m,*}'");
                }
              }
              \@tmp;
          }


###########################################################################
[BLAST1]

text:     "BLAST (series 1):"

#generic
OPTION:   hsp
usage:    "HSP tiling method __CHOOSE(Bio::MView::Manager::check_hsp_tiling)"
type:     s
default:  ranked

OPTION:   maxpval
usage:    "Ignore hits with p-value greater than N"
type:     s
default:  unlimited
param:    
convert:  sub { __ARGS;
		return undef    if __OV eq 'unlimited';
		__TEST('f', __ON, __OV);
		__WARN("bad setting '-__ON=__OV', want > 0.") if __OV < 0;
		__OV;
	  }

OPTION:   minscore
usage:    "Ignore hits with score less than N"
type:     s
default:  unlimited
param:    
convert:  sub { __ARGS;
		return undef    if __OV eq 'unlimited';
		__TEST('f', __ON, __OV);
		__WARN("bad setting '-__ON=__OV', want > 0.") if __OV < 0;
		__OV;
	  }

#generic
OPTION:   strand
usage:    "Report only these query strand orientations {p,m,*}"
type:     @s
default:  *


###########################################################################
[BLAST2]

text:     "BLAST (series 2):"

#generic
OPTION:   hsp
usage:    "HSP tiling method __CHOOSE(Bio::MView::Manager::check_hsp_tiling)"
type:     s
default:  ranked

#generic
OPTION:   maxeval
usage:    "Ignore hits with e-value greater than N"
type:     s
default:  unlimited

#generic
OPTION:   minbits
usage:    "Ignore hits with bits less than N"
type:     s
default:  unlimited

#generic
OPTION:   strand
usage:    "Report only these query strand orientations {p,m,*}"
type:     @s
default:  *


###########################################################################
[PSIBLAST]

text:     "PSI-BLAST:"

#generic
OPTION:   hsp
usage:    "HSP tiling method __CHOOSE(Bio::MView::Manager::check_hsp_tiling)"
type:     s
default:  ranked

#generic
OPTION:   maxeval
usage:    "Ignore hits with e-value greater than N"
type:     s
default:  unlimited

#generic
OPTION:   minbits
usage:    "Ignore hits with bits less than N"
type:     s
default:  unlimited

OPTION:   cycle
usage:    "Process the N'th cycle of a multipass search {1..N,last}"
type:     @s
default:  last
param:    
convert:  sub { __ARGS;
		 if (__OV eq 'last') {
		     #show last cycle
		     return [0];
		 } elsif (__OV eq '*') {
		     #show all cycles
		     return [];
		 }
		 return __PV;
	     }


###########################################################################
[FASTA]

text:     "FASTA:"

OPTION:   minopt
usage:    "Ignore hits with opt score less than N"
type:     s
default:  unlimited
param:    
convert:  sub { __ARGS;
		return undef    if __OV eq 'unlimited';
		__TEST('f', __ON, __OV);
		__WARN("bad setting '-__ON=__OV', want > 0.") if __OV < 0;
		__OV;
	  }

#generic
OPTION:   strand
usage:    "Report only these query strand orientations {p,m,*}"
type:     @s
default:  *


###########################################################################
[HSSP]

text:     "HSSP/Maxhom:"

OPTION:   chain
usage:    "Report only these chainnames/numbers {A,B,...,*}"
type:     @s
default:  *
param:    


###########################################################################
[MULTAL]

text:     "MULTAL/MULTAS:"

OPTION:   block
usage:    "Report only these blocks {1..N,first,*}"
type:     @s
default:  first
param:    
convert:  sub { __ARGS;
		 if (__OV eq 'first') {
		     #show first block
		     return [0];
		 } elsif (__OV eq '*') {
		     #show all blocks
		     return [];
		 } else {
		     return __TEST('@i', __ON, __OV);
		 }
		__WARN("bad setting '-__ON=__OV', want range {1..N,first,*}");
	     }


###########################################################################
[HELP]

text:     "More information and help:"

OPTION:   help
usage:    "This help"

OPTION:   listcolors
usage:    "Print listing of known colormaps"

OPTION:   listgroups
usage:    "Print listing of known consensus groups"


###########################################################################
