my($scr) = "nlprot.pl";

# find scr path
system("pwd > path.txt");
open(F, "path.txt");
$x = <F>; chomp($x); $x .= "/";
close F;

# find perl path
system("which perl > path.txt");
open(F, "path.txt");
$y = <F>; chomp($y); $y =~ s/\w+$//;
close F;

unlink("path.txt");

if (! -e $x.$scr) {
begin1:
	# ask program directory
	print "Input the directory where the $scr-script is located\n>";
	$x = <STDIN>;
	chomp($x);
	$x =~ s/([^\/])$/\1\//;
	if (! -e ($x . $scr)) {
		print "ERROR: $scr not found in $x!!\n";
		goto begin1;
	}
}

# correct nlprot.pl script
open(F, "<$x$scr") or die "Error that shouldn't pop up!\n";
open(G, ">$x${scr}2") or die "Error that shouldn't pop up either!\n";
# change perl
$line = <F>;
$line = "#!${y}perl\n";
print G $line;
# change $path_app
$line = <F>;
$line = "\$path_app = '$x';\n";
print G $line;
# rest of script remains the same
while ($line = <F>) {
	print G $line;
}
close G;
close F;

# overwrite old version with new version
unlink($x . $scr);
system("mv $x${scr}2 $x$scr");

# make tmp directory
system ("mkdir ${x}tmp/");

print "Installation was successful. Please add the path $x to your environment.\nWhenever you move NLProt to a different directory, please move all its sub-directories as well and simply run the install.pl script again.\n";
