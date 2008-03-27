#!/usr/freeware/bin/perl
##!/usr/local/bin/perl 

###############################################################################
# func_pred
###############################################################################
#
# D. Devos, December 2000q
# open maxhom, get id, lenght ali and seq
# get info from swp
# derive probability
#
# when changing swp version, execute getid.prl first, please
#
# USAGE: ./fctpred.pl maxhom_file
#
################################################################################
$limid=25;
$limdom=.5;
$swpfile="/data/swissprot/sprot39.dat";

use Fcntl;
use GDBM_File;

tie (%SWPH,'GDBM_File',"Swisshash/IDpositions",O_RDONLY, 0444) || die "searchByIndex: cannot tie to index file:$!\n\n\n";


die "USAGE: ./fctpred.pl maxhom_file\ncan find $ARGV[0]\n" unless (-e $ARGV[0]);

#probab
###################
# definición de la %DEhash
$DEhash{5}="20";
$DEhash{15}="75.76";
$DEhash{25}="96.14";
$DEhash{35}="98.16";
$DEhash{45}="99.32";
$DEhash{55}="96.77";
$DEhash{65}="99.06";
$DEhash{75}="94.92";
$DEhash{85}="100";
$DEhash{95}="97.46";

# definición de la %EChash
$EChash{15}="46.29";
$EChash{25}="83.86";
$EChash{35}="89.81";
$EChash{45}="88.87";
$EChash{55}="96.3";
$EChash{65}="98.16";
$EChash{75}="98.19";
$EChash{85}="100";
$EChash{95}="100";

# definición de la %KWhash
$KWhash{5}="32.91";
$KWhash{15}="56.68";
$KWhash{25}="75.71";
$KWhash{35}="80.88";
$KWhash{45}="85.15";
$KWhash{55}="90.34";
$KWhash{65}="90.16";
$KWhash{75}="92.4";
$KWhash{85}="94.19";
$KWhash{95}="97.63";

#true proof that this man didn't understood!!!
# definición de la %p0 de EC
$p0{15}=11.11;
$p0{25}=2.26;
$p0{35}=1.23;
$p0{45}=0.51;
$p0{55}=0;
$p0{65}=0.26;
$p0{75}=0;
$p0{85}=0;
$p0{95}=0;

# definición de la %p1 de EC
$p1{15}=29.62;
$p1{25}=10.56;
$p1{35}=1.36;
$p1{45}=0.25;
$p1{55}=0;
$p1{65}=0;
$p1{75}=0;
$p1{85}=0;
$p1{95}=0;

# definición de la %p2 de EC
$p2{15}=11.11;
$p2{25}=0.75;
$p2{35}=1.23;
$p2{45}=2.04;
$p2{55}=0;
$p2{65}=0;
$p2{75}=0;
$p2{85}=0;
$p2{95}=0;

# definición de la %p3 de EC
$p3{15}=29.62;
$p3{25}=22.26;
$p3{35}=29.17;
$p3{45}=33.5;
$p3{55}=14.76;
$p3{65}=6.28;
$p3{75}=7.21;
$p3{85}=0;
$p3{95}=0;

# definición de la %p4 de EC
$p4{15}=18.51;
$p4{25}=64.15;
$p4{35}=66.98;
$p4{45}=63.68;
$p4{55}=85.23;
$p4{65}=93.45;
$p4{75}=92.78;
$p4{85}=100;
$p4{95}=100;
##############
# filter only fct informative keywords
# define in %kw

open (KW,"keylist-filt.txt");
while (<KW>) {
	$kw{$1}++ if (/^([^\>].+)$/);
}
###

open(SWP,$swpfile);
open (ALI,$ARGV[0]);
while (<ALI>) {
	$rat=0;
	if (/^(\S+_\S+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+\d+\s+(\d+)\s/) {
		$ok++;
		$swc=$1;
		$id=$2;
		$lal=$3;
		$lst=$4;
		$lsq=$4 if ($id==100);
		$cid=(int$id/10)*10+5;
		$swc=~tr/a-z/A-Z/;
		$rat=$lal/$lst;
		$hom{$swc}="$id\t$lal\t$lst";
		$war{$swc}=int$rat*100 if $rat <=$limdom;
		$id{$swc}=$id;
# @ord just to keep the order
		push (@ord,$swc);
	}
}
foreach $h (@ord) {
	print "$h\t$hom{$h}\t";
	if ($id{$h}<$limid) {
		print "ID-$id{$h}%-\t";
	} else {print "ID-ok-\t";}
	if (defined $war{$h}) {
		print "DOMAINS-$war{$h}-\t";
	} else {print "DOMAINS-ok-\t";}
	extr_info ($h);
	@de=@sde;
	@kw=@nkw;
	$de=join" ",@de;
	$kw=join" ",@kw;
	$de=~s/\n/ /;
	$ec=$1 if ($de=~/E.*C.*(\d\.\d+\.\d+\.\d+)/);
	$pde=$DEhash{$cid};
	$pec=$EChash{$cid};
	$pkw=$KWhash{$cid};
	$p4ec=$p4{$cid};
	$p3ec=$p4ec+$p3{$cid};
	$p2ec=$p3ec+$p2{$cid};
	$p1ec=$p2ec+$p1{$cid};
	print "description\t$de\t$pde\t";
	print "keywords\t$kw\t$pkw";
	if (defined $ec) {
		print "\t","EC_mean	$ec	$pec	";
		@ec=split(/\./,$ec);
		print "EC_1\t$ec[0].-.-.-\t$p1ec";
		print "\t","EC_2\t$ec[0].$ec[1].-.-\t$p2ec" unless ($ec[1] eq "-");
		print "\t","EC_3\t$ec[0].$ec[1].$ec[2].-\t$p3ec" unless ($ec[2] eq "-");
		print "\t","EC_4\t$ec[0].$ec[1].$ec[2].$ec[3]\t$p4ec" unless ($ec[3] eq "-");
	}
	print "\n\/\/\n";
}
print "sure $ARGV[0] is a maxhom file?\n" unless (defined $ok);

sub extr_info {
undef @sde;
undef @skw;
undef @nkw;
$src=@_[0];

seek (SWP,$SWPH{$src},0);
while (<SWP>) {
	push(@sde,$1) if (/^DE\s+(.+)/);
	push(@skw,$1) if (/^KW\s+(.+)/);
	last if (/^\/\/$/);
}
$skw=join /;/,@skw;
@skw=split (/;/,$skw);
foreach $k (@skw) {
	$k=~s/^\s//;
	$k=~tr/[a-z]/[A-Z]/;
	push (@nkw,$k) if (defined $kw{$k});
}
	
}

sub by_id {
	$hom{$a}[0]<=>$hom{$b}[0];
}
