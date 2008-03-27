# Here's an example of a little chat2 client I wrote for my perl
# networking class, which, I believe, is some of the only docs 
# on chat2 extant today. :-( 

require 'chat2.pl';

sub waitfor {
    &chat'expect(30, "@_") || die "expected @_";
} 

&chat'open_proc("telnet localhost")
    || die "can't open proc: $!";

&waitfor("login:");
&chat'print("sync\n");
&waitfor("sync");

do {
    &chat'expect(30,

	'^Last Login: (.*)\r?\n', q{
	    print "It's been awhile since $1\n";
	}, 

	'Connection closed by foreign host', q{
	    print "conn closed\n";
	    $done = 10;
	},

	'(.+)\r?\n', q{
	    print $&;
	}, 

	'^\r?\n$', q{
	    print "blank line\n";
	    $done++;
	}, 

	TIMEOUT, q{ 
	    print "Oops, timeout, done at $done\n";
	    $done += 2;
	}, 

	EOF,     q{ 
	    print "EOF!\n";
	    $done =  10;
	}, 
    )
} until $done > 9;

&chat'close || die "can't close: $!";

print "all done $done\n";
