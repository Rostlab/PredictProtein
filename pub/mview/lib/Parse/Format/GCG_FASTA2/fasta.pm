# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown. $Id: fasta.pm,v 1.1 1999/03/09 16:22:44 nbrown Exp $

###########################################################################
package Parse::Format::GCG_FASTA2::fasta;

use Parse::Format::GCG_FASTA2;
use strict;

use vars qw(@ISA);

@ISA = qw(Parse::Format::GCG_FASTA2);


###########################################################################
package Parse::Format::GCG_FASTA2::fasta::HEADER;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::GCG_FASTA2::HEADER);


###########################################################################
package Parse::Format::GCG_FASTA2::fasta::RANK;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::GCG_FASTA2::RANK);


###########################################################################
package Parse::Format::GCG_FASTA2::fasta::TRAILER;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::GCG_FASTA2::TRAILER);


###########################################################################
package Parse::Format::GCG_FASTA2::fasta::HIT;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::GCG_FASTA2::HIT);


###########################################################################
package Parse::Format::GCG_FASTA2::fasta::HIT::SUM;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::GCG_FASTA2::HIT::SUM);


###########################################################################
package Parse::Format::GCG_FASTA2::fasta::HIT::ALN;

use vars qw(@ISA);

@ISA   = qw(Parse::Format::GCG_FASTA2::HIT::ALN);


###########################################################################
1;
