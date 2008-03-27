# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: blastx.pm,v 1.1 1999/01/26 23:39:04 nbrown Exp $

###########################################################################
package Parse::Format::BLAST2::blastx;

use Parse::Format::BLAST2::blastn;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2);


###########################################################################
package Parse::Format::BLAST2::blastx::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HEADER);


###########################################################################
package Parse::Format::BLAST2::blastx::SEARCH;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::SEARCH);


###########################################################################
package Parse::Format::BLAST2::blastx::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::SEARCH::RANK);


###########################################################################
package Parse::Format::BLAST2::blastx::SEARCH::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT);


###########################################################################
package Parse::Format::BLAST2::blastx::SEARCH::HIT::SUM;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::HIT::SUM);


###########################################################################
package Parse::Format::BLAST2::blastx::SEARCH::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastn::SEARCH::HIT::ALN);


###########################################################################
package Parse::Format::BLAST2::blastx::WARNING;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::WARNING);


###########################################################################
package Parse::Format::BLAST2::blastx::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
