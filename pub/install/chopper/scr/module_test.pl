#!/usr/bin/perl -w


BEGIN {
    use lib 'DIRLIB';
    my(@system, @local, $mod, $ok);
    
    $ok = 1;
    @system = qw(Getopt::Long Storable File::Copy XML::DOM);
    @local  = qw(libBlast libChopper libGenome libHmmer libHssp libList libPHD);

    @rpms = qw(perl-Digest-MD5 perl-Storable perl-URI perl-XML-Dumper
	       perl-XML-Encoding  perl-XML-Grove perl-XML-Parser
	       perl-XML-Twig perl-libwww-perl perl-libxml-enno
	       perl-libxml-perl
	       );


    for $mod (@system) {
        next if (eval "require $mod");
	push @err_system,$mod;
    }
    for $mod ( @local ) {
	next if (eval "require $mod");
	push @err_local,$mod;
    }	

    if ( @err_system ) {
	print
	    "*** ERROR: the following required system module(s) can't be loaded: ",join(' ',@err_system),"\n",
	    "please get them from CPAN and install.\n",
	    "RedHat Linux users may want to install the following RPMs:\n",
	    join("\n",@rpms),"\n";

	$ok = 0;
    }
    
    if ( @err_local ) {
	print
	    "*** ERROR: the following required local module(s) can't be loaded: ",join(' ',@err_local),"\n",
	    "Something went wrong with the Chopper installation, please try reinstall.\n";
	$ok = 0;
    }
    if ( $ok ) {
	print 
	    "All required perl modules loaded ok\n",
	    "Installation process completed, please see README for instructions.\n";
    } else {
	"Installation failed\n";
    }
    
    
}

