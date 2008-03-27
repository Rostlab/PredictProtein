#!/usr/sbin/perl
#
# hotlist_to_html.pl
# Convert a mosaic hotlist to a reasonable home page.
# Copyright (C) 1994 by John Heidemann <johnh@ficus.cs.ucla.edu>
#
# $Id: hotlist_to_html.pl,v 1.2 1994/06/08 17:25:15 johnh Exp $
#
# This program is placed under the Gnu Public License, version two.
#
# Usage: expects hotlist on stdin, produces a page HTML on stdout (suitable
# for your home page).
#

($username, $realname) = &determine_user;

print <<END;
<TITLE>Mosaic Hotlist ($username)</TITLE>
<H1>Mosaic Hotlist ($username)</H1>

Welcome to a html version of ${realname}'s hotlist.
This version was converted on `date`.<P>

<UL>
END

@hotlist = &read_hotlist;
&output_html_list (@hotlist);

print "</UL>\n";

exit 0;


sub determine_user {
    local (@pwent);
    @pwent = getpwuid($>);
    if ($#pwent < 0) {
    	return ("unknown") x 2;
    } else {
    	return @pwent[0,6];
    };
}

sub read_hotlist {
    open (HL, "<-") || die("Cannot open $hotlist");
    local (@hotlist) = <HL>;
    chop (@hotlist);
    close (HL);
    die ("Bad hotlist magic number")
	if ($hotlist[0] != "ncsa-xmosaic-hotlist-format-1");
    shift @hotlist;
    shift @hotlist;
    return @hotlist;
}

sub output_html_list {
    local (@hotlist) = @_;
    @url = ();
    @title = ();
    while ($#hotlist > 0) {
	$url = shift @hotlist;
	$url =~ s/ .*$//;   # strip off trailing date
	$title = shift @hotlist;
	push (@url, $url);
	push (@title, $title);
    };
    foreach $i (0..$#url) {
	print "<LI> <A HREF=\"$url[$i]\"> $title[$i] </A>\n";
    };
}
