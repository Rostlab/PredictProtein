#!/usr/bin/perl -w

# format: end of one record field with 'language'
# note: put 'VHS' to indicate non-DVD
# 

$[=1 ;				# count from one

if ($#ARGV < 1){
    print "--- prefilters files from AduDVD, must run video-amazon.pl next\n";
    print "--- options: <dbg|incl=file>\n";
    print "---          include file: only titles of things to take\n";
    exit;
}
$fhin="FHIN";
$fhout="FHOUT";
#$sep=  "\t";

$Ldebug=1;
$Ldebug=0;
$fileIncl=0;

$#tmp=0;
foreach $arg(@ARGV){
    if    ($arg=~/^dbg/)       { $Ldebug=  1;}
    elsif ($arg=~/^incl=(.*)$/){ $fileIncl=$1;}
    else {
	push(@tmp,$arg);
    }}
@fileIn=@tmp;

$fileOut="00outin-mov.txt";

  				# check whether we have file with titles to include
$#titleIncl=0;

if ($fileIncl){
    open($fhin,$fileIncl)|| die "problem to open fileincl=$fileIncl\n";    
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^\s*|\s*$//g;
	next if (length($_)<3);
	push(@titleIncl,$_);
    }
    close($fhin);
}

&iniGenre();

$ctrec=0;
$#wrt=0;
$#incl=0;

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN no fileIn=$fileIn\n";
		      next;}
    print "--- working on fileIn=$fileIn!\n";
    open($fhin,$fileIn)|| warn "problem to open $fileIn\n";    
    $#tmprd=0;
    $#tmp=0;
    while (<$fhin>) {
				# all until field 'language' into one
	if    ($_=~/^\s*language/i){
	    push(@tmprd,join("\n",@tmp));
	    $#tmp=0;
	}
				# stuff to ignore
	elsif (
	       $_=~/^\s*$/ ||
	       $_=~/^\s*category/i ||
	       $_=~/^\s*our price/i ||
	       $_=~/^\s*rated/i ||
	       $_=~/^\s*item code/i ||
	       $_=~/^\s*availability/i ||
	       $_=~/^\s*click to enlarge/i ||
	       $_=~/\(Ships/i
	       ){
	    next;
	}
	else {
	    $_=~s/\n//g;
	    $_=~s/^\s*|\s*$//g;
#	    print "xx now push ($_)\n";
	    push(@tmp,$_);
	}
    }
    close($fhin);
    				# handle last
    if ($#tmp){
	push(@tmprd,(join("\n",@tmp)));
	$#tmp=0;
    }

    $numxx=$#tmprd;
    if (0){
	print "xx before processing\n";
	foreach $it (1..$numxx){
	    $tmp=$tmprd[$it];
	    $tmp=~s/\n/ ___ /g;
	    print "xx rec=$it val=",$tmp,"\n";
	    die;
	}die;
    }
    
    				# now process stuff
    foreach $tmprd (@tmprd){
	@tmp=split(/\n/,$tmprd);
	undef %tmp;
	foreach $kwd (
		      "title",
		      "director",
		      "year_done",
		      "date_released",
		      "cast",
		      "time",
		      "genre",
		      "studio"
		      ){
	    $tmp{$kwd}=0;
	}
	$tmp{"type"}="DVD";

	$tmp{"title"}=$tmp[1];
	$numarray=$#tmp;
	++$ctrec;
	foreach $it (2..$numarray){
	    if    ($tmp[$it]=~/^\s*studio[\s\t]+(\S.*)$/i){
		if ($tmp{"studio"}){
		    $tmp{"studio"}.=", ".$1;}
		else {
		    $tmp{"studio"}=$1;}}
	    elsif ($tmp[$it]=~/^\s*genre[\s\t]+(\S.*)$/i){
		$tmpgenre=$1;
		$tmpgenre2="";
		@tmp2=split(/,/,$tmpgenre);
		foreach $tmp2 (@tmp2){
		    $tmp2=~s/^\s*|\s*$//g;
#		    next if ($tmp2=~/straight/i);
		    if (defined $genre{$tmp2}){
			$tmpgenre2.=$genre{$tmp2}.", ";}
		    elsif (
			   $tmp2=~/^Amateur|Interactive|BBW|Compilation|Gay|Beach/ ||
			   $tmp2=~/^Latin|Foreign/
			   ){
			next;}
		    else {
			print "xx missing genre '$tmp2'\n";
			next;
#			die;
		    }
		}
		$tmpgenre2=~s/[,\s]*$//g;
		$tmp{"genre"}=$tmpgenre2;
	    }
	    elsif ($tmp[$it]=~/^\s*runtime[\s\t]+(\S.*)$/i){
		$tmptime=$1;
		$tmp{"time"}=&time_min2hour($tmptime);
	    }
	    elsif ($tmp[$it]=~/^\s*production year[\s\t]+(\S.*)$/i){
		$tmp{"year_done"}=$1;}
	    elsif ($tmp[$it]=~/^\s*release date[\s\t]+(\S.*)$/i){
		$tmpdate=$1;
		if ($tmpdate=~/(\d+)\/(\d+)\/(\d+)/){
		    $tmpdate=$3."_".$1."_".$2;}
		$tmp{"date"}=$tmpdate;}
	    elsif ($tmp[$it]=~/^\s*director[\s\t]+(\S.*)$/i){
		$tmp{"director"}=$1;
		$tmp{"director"}=~s/\.//g;}
	    elsif ($tmp[$it]=~/^\s*producer[\s\t]+(\S.*)$/i){
		if ($tmp{"studio"}){
		    $tmp{"studio"}.=", ".$1;}
		else {
		    $tmp{"studio"}=$1;}}
	    elsif ($tmp[$it]=~/^\s*casts[\s\t]+(\S.*)$/i){
		$tmp{"cast"}=$1;}
	    elsif ($tmp[$it]=~/^\s*VHS/i){
		$tmp{"type"}="VHS";}
	    			# empty stuff
	    elsif ($tmp[$it]=~/^\s*studio$/i         ||
		   $tmp[$it]=~/^\s*genre/i           ||
		   $tmp[$it]=~/^\s*runtime/i         ||
		   $tmp[$it]=~/^\s*production year/i ||
		   $tmp[$it]=~/^\s*release date/i    ||
		   $tmp[$it]=~/^\s*director/i        ||
		   $tmp[$it]=~/^\s*casts/i           
#		   $tmp[$it]=~/^\s*/i ||
		   ){
		next;}
	    else {
		print "--- recnum=$ctrec, title=",$tmp{"title"},", unknown field:\n";
		print "$tmp[$it]\n";
		die;}
	}
				# prepare for output

				# year appended to title in first line
	if (! $tmp{"year_done"}){
	    $tmp{"year_done"}="0000";
	}
	$wrt="";
	$wrt= $tmp{"title"}." (".$tmp{"year_done"}.")\n";
#	$wrt= "xxtitle ".$tmp{"title"}." (".$tmp{"year_done"}.")\n";
				# cast: separated
	if ($tmp{"cast"}){
	    @tmp=split(/,/,$tmp{"cast"});
	    $tmpcast="Cast List\n";
	    foreach $tmp (@tmp){
		$tmp=~s/^\s*|\s*$//g;
		next if (length($tmp)<2);
		$tmpcast.=$tmp."\n";
	    }
	    $tmpcast=~s/\n$//g;
	    $tmp{"cast"}=$tmpcast;
	}
	foreach $kwd (
		      "director",
		      "cast",
		      "date",
		      "studio",
		      "type",
		      "time",
		      "genre",
		      ){
	    next if (length($kwd)<1);
	    next if (! $tmp{$kwd});
	    $kwdwrt=$kwd.":";
	    if    ($kwd=~/genre/) {$kwdwrt="kwd ";}
	    elsif ($kwd=~/studio/){$kwdwrt="publ ";}
	    elsif ($kwd=~/time/)  {$kwdwrt="Runtime: ";}
	    elsif ($kwd=~/date/)  {$kwdwrt="Date released: ";}

	    if ($kwd=~/type|cast/){
		$wrt.=$tmp{$kwd}."\n";}
	    else {
		$wrt.=sprintf("%-15s %-s\n",$kwdwrt,$tmp{$kwd});
	    }
	}
	$wrt[$ctrec]=$wrt;

	if ($#titleIncl){
	    $Lincl=0;
	    foreach $tmp (@titleIncl){
		if ($tmp{"title"}=~/$tmp/i){
		    $Lincl=1;
		    last;
		}
	    }
	    $incl[$ctrec]=$Lincl;
	}
	else {
	    $incl[$ctrec]=1;
	}

	if ($tmp{"title"}=~/xyz/){
	    print "xx wrt=$wrt\n";die;
	}
    }
}

if ($Ldebug){
    $ct=0;
    foreach $wrt (@wrt){
	++$ct;
	print " \n";
	if ($incl[$ct]){
	    print "--- INclude rec $ct\n";}
	else {
	    print "--- EXclude rec $ct\n";}
	print $wrt;
    }
}
open($fhout,">".$fileOut);
$ct=$ctincl=0;
foreach $wrt(@wrt){
    ++$ct;
    next if (! $incl[$ct]);
    ++$ctincl;
    print $fhout "\n";
    print $fhout $wrt;
}
close($fhout);

$fileOutExcl=$fileOut;
  $fileOutExcl=~s/(\..*)$/Xclude$1/;

open($fhout,">".$fileOutExcl);
$ct=$ctexcl=0;
foreach $wrt(@wrt){
    ++$ct;
    next if ($incl[$ct]);
    ++$ctexcl;
    print $fhout "\n";
    print $fhout $wrt;
}
close($fhout);

print "--- nrec(included)=",$ctincl," in $fileOut\n";
print "--- nrec(excluded)=",$ctexcl," in $fileOutExcl\n" if ($#titleIncl);

sub name {
    local($in)=@_;
    $in=~s/^\s*|\s*$//g;
    @tmp=split(/\s+/,$in);
    $name=$tmp[$#tmp].", ";
    foreach $it (1..($#tmp-1)){
	$tmp[$it]=~s/\.//g;
	$name.= $tmp[$it]." ";
    }
    $name=~s/\s*$//g;
#    $name=~s/\b([A-Z])\./$1/g;
    $name=~s/\s*\,*$//g;
    return($name);
}
	       

sub iniGenre {
    $genre{"All Girl"}=   "les";
    $genre{"Anal"}=       "ana";
    $genre{"Asian"}=      "asi";
    $genre{"Big Clits"}=  "clit";
    $genre{"Bisexual"}=   "fck";
    $genre{"Black"}=      "blk";
    $genre{"Body Builders"}="dom, muscle";
    $genre{"Bondage"}=    "bon";
    $genre{"Busty"}=      "boo";
    $genre{"Classic"}=    "class";
    $genre{"Cumshots"}=   "cum";
    $genre{"Domination"}= "dom";
    $genre{"Foot/Shoe"}=  "foot";
    $genre{"Gangbang"}=   "gang";
    $genre{"Interracial"}="big, ";
    $genre{"Lactation"}=  "odd, boo, biz";
    $genre{"Oddities"}=   "odd";
    $genre{"Older Women"}="old";
    $genre{"Oral"}=       "ora";
    $genre{"She-Male"}=   "trs";
    $genre{"S/M"}=        "dom, biz, bon";
    $genre{"Squirting"}=  "squirt";
    $genre{"Straight"}=   "act";

    $genre{"big"}="big";

    $genre{""}="";
    $genre{""}="";
    $genre{""}="";
}

sub time_min2hour {
    local($in)=@_;
    $intmp=$in;
    $in=~s/minute.*$//g;
    $in=~s/\s//g;
    if ($in=~/\D/){
	print "xx problem with converting minutes '$intmp'\n";
	die;}
    $hour=int($in/60);
    $min= $in-int($in/60)*60;
    $min= "0".$min if (length($min)<2);
    $out=$hour.":".$min;
    return($out);
}
