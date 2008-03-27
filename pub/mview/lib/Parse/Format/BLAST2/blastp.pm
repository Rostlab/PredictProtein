# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: blastp.pm,v 1.2 1999/02/19 16:55:56 nbrown Exp $

###########################################################################
package Parse::Format::BLAST2::blastp;

use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2);


###########################################################################
package Parse::Format::BLAST2::blastp::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HEADER);


###########################################################################
package Parse::Format::BLAST2::blastp::SEARCH;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::SEARCH);


###########################################################################
package Parse::Format::BLAST2::blastp::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::SEARCH::RANK);


###########################################################################
package Parse::Format::BLAST2::blastp::SEARCH::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT);


###########################################################################
package Parse::Format::BLAST2::blastp::SEARCH::HIT::SUM;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT::SUM);


###########################################################################
package Parse::Format::BLAST2::blastp::SEARCH::HIT::ALN;

use vars qw(@ISA);
use Regexps;

@ISA = qw(Parse::Format::BLAST2::SEARCH::HIT::ALN);


###########################################################################
package Parse::Format::BLAST2::blastp::WARNING;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::WARNING);


###########################################################################
package Parse::Format::BLAST2::blastp::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
