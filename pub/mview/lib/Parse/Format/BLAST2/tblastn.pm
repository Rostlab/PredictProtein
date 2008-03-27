# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: tblastn.pm,v 1.1 1999/01/26 23:39:04 nbrown Exp $

###########################################################################
package Parse::Format::BLAST2::tblastn;

use Parse::Format::BLAST2::blastx;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx);


###########################################################################
package Parse::Format::BLAST2::tblastn::HEADER;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::HEADER);


###########################################################################
package Parse::Format::BLAST2::tblastn::SEARCH;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::SEARCH);


###########################################################################
package Parse::Format::BLAST2::tblastn::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::SEARCH::RANK);


###########################################################################
package Parse::Format::BLAST2::tblastn::SEARCH::HIT;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::SEARCH::HIT);


###########################################################################
package Parse::Format::BLAST2::tblastn::SEARCH::HIT::SUM;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::SEARCH::HIT::SUM);


###########################################################################
package Parse::Format::BLAST2::tblastn::SEARCH::HIT::ALN;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::SEARCH::HIT::ALN);


###########################################################################
package Parse::Format::BLAST2::tblastn::WARNING;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::WARNING);


###########################################################################
package Parse::Format::BLAST2::tblastn::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Parse::Format::BLAST2::blastx::PARAMETERS);


###########################################################################
1;
