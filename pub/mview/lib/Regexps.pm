# -*- perl -*-
# Copyright (c) 1996-1999  Nigel P. Brown, All rights reserved. $Id: Regexps.pm,v 1.1 1999/01/26 23:05:02 nbrown Exp $

###########################################################################
# regexps for string matching numerical types
###########################################################################
package Regexps;

use Exporter;

@ISA = qw(Exporter);

@EXPORT = 
    qw(
       $RX_Uint
       $RX_Sint
       $RX_Ureal 
       $RX_Sreal
      );


#unsigned integer
$RX_Uint   = '\+?\d+';

#signed integer
$RX_Sint   = '[+-]?\d+';

#unsigned real
$RX_Ureal = '\+?(?:\d+\.\d+|\d+\.|\d+|\.\d+)?(?:[eE][+-]?\d+)?';

#signed real
$RX_Sreal = '[+-]?(?:\d+\.\d+|\d+\.|\d+|\.\d+)?(?:[eE][+-]?\d+)?';


###########################################################################
1;
