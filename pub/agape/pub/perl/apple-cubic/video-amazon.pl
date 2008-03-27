#!/usr/bin/perl -w

$[ =1 ;				# count from one

if ($#ARGV<1){
    print "input: file with stuff, format\n";
    print "       title MUST have (yyyy)                      NOTE: if year unknown '(0000)'\n";
    print "       director MUST have (dir:|director[s]|directed by )      NOTE: many: separate with \;\n";
    print "       'kwd KEYWORD1\; KEYWORD2' for keywords\n";
    print "       'publ Disney' for distributor, publisher\n";
    print "       \n";
    print "       cast begins with line 'cast|starring|actors'\n";
    print "       \n";
    print "       - one movie ends where next begins\n";
    print "       - can handle '\# name - (bio)' kind of things\n";
    print "       - default = DVD (unless line with VHS)\n";
    print "       \n";
    print "       switch 00\n";
    exit;
}




$fhin="FHIN";
$fhout="FHOUT";
$fhout2="FHOUT2";
$sep=  " ";
$pretitle="00 ";
$Ldebug=1;
$Ldebug=0;

$L00=0;

$fileSpecial="/Volumes/user/br/mis/priv/lists/vid-us00-special.unix";
$fileSpecial="/Volumes/user/shuttle/vid-us00-special.unix";

$#fileIn=0;

foreach $arg (@ARGV){
    if    ($arg=~/^00$/){ 
	$L00=1;}
    elsif ($arg=~/^dbg$/){
	$Ldebug=1;}
    elsif (-e $arg){
	push(@fileIn,$arg);
    }
    else {
	print "ERROR argument '$arg' not understood!\n";
	exit;
    }
}

   				# read special
if ($L00){
    open($fhin,$fileSpecial)||warn "fileSpecial=$fileSpecial, not found\n";
    $#special=0; undef %special;
    while (<$fhin>) {
	next if ($_=~/^\s*$/);
	next if ($_=~/^\s*\#/);
	$_=~s/\n//g;
	$_=~s/^\s*|\s*$//g;
	if (! defined $special{$_}){
	    push(@special,$_);
	    $special{$_}=1;
	}
    }
    close($fhin);
}

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN no fileIn=$fileIn\n";
		      next;}
    print "--- working on fileIn=$fileIn!\n";
    open($fhin,$fileIn)|| warn "problem to open $fileIn\n";  
    $ct=0;
    undef %res;
    while (<$fhin>) {
	next if ($_=~/^\s*$/);
	$_=~s/\n//g;
				# new movie (either 'title: ' or 'xxxx (yyyy)'
	if    ($_=~/^\s*(\S.*)\s*\((\d\d\d\d)\)\s*$/){
	    $title=$1; 
	    $year= $2;
	    $title=~s/^[\s\t]*|[\s\t]*$//g;
	    ++$ct;
	    $res{"title",$ct}=$title;
	    $res{"year",$ct}= $year;
	    $res{"type",$ct}= "DVD"; # default
	    $Lcast=0;
	    foreach $kwd ("kwd","dir","cast"){
		undef $res{$kwd,$ct};
	    }
	}
	                        #  stuff to ignore
	elsif ($_=~/language|more/i){
	    next;
	}
	    
				# director
	elsif ($_=~/^.*(dir:|directors?:?|directed by)[\s\t]\s*(\S.*)$/i){
	    $dir=$2;
	    @tmpdir=split(/\;/,$dir);
	    $name="";
	    foreach $tmpdir (@tmpdir){
		$name.="\t".&name($tmpdir);
	    }
	    $name=~s/^[\s\t]*//g;
	    $res{"dir",$ct}=$name;
#	    print "xx director $name\n";
	}
				# keywords
	elsif ($_=~/^\s*kwd[\s\t\:]+(\S.*)$/i){
	    $kwd=$1;
	    $res{"kwd",$ct}=$kwd;
	}
				# publisher, distributor
	elsif ($_=~/^\s*publ[\s\t\:]+(\S.*)$/i){
	    $tmp=$1;
	    $res{"publ",$ct}=$tmp;
	}
				# tags recognised
	elsif ($_=~/^\s*VHS\s*$/i){
	    $res{"type",$ct}="VHS";
	}
				# time
	elsif ($_=~/^\s*runtime\s*[:\s]\s*([\d\:]+)\b/i){
	    $res{"time",$ct}=$1;
	}
				# country
	elsif ($_=~/^\s*country\s*[\s\:]\s*(\S.*)$/i){
	    $tmp=$1;
	    $tmp=~s/\s\s+/ /g;
	    $tmp=~s/[,\/\;]/,/g;
	    $res{"country",$ct}=$tmp;
	}

				# begin cast
	elsif ($_=~/cast|actor|starring/i){
	    $Lcast=1;
	}
	elsif ($_=~/^\s*\#?\s*\S+.*\.\./ ||
	       $_=~/^\s*\#?\s*\S+/) {
	    $_=~s/\s*\.\.+.*$//g;
	    $_=~s/^\s*|\s*$//g;
	    $name=&name($_);
	    $res{"cast",$ct}.="\t".$name;
	    $Lcast=1;
	}
	else {
	    print "xxx not understood '$_'\n";
	}
    }				# 
    close($fhin);



# endnote format
#%0 Film or Broadcast
#%A author
#%A director
#%D film_year
#%T film_title
#%B film_seriesTitle
#%C film_country
#%I film_distributor
#%Y film_producer
#%8 film_dateReleased
#%9 film_medium
#%! film_shortTitle
#%@ film_isbn
#%L film_callNumber
#%M film_accessionNumber
#%F film_label
#%K film_keywords
#%X film_synopsis
#%Z film_notes



    $fileOut=$fileIn;
    $fileOut=~s/^.*\///g;
    $fileOut.="_out";
    $fileOut2=$fileOut."mac.txt";
    open($fhout,">".$fileOut);
    open($fhout2,">".$fileOut2);
    foreach $it (1..$ct){
	$year=$dir=$kwd=$publ=$time=$country="";
	$year=   $res{"year",$it}      if (defined $res{"year",$it} && $res{"year",$it} ne "0000");
	$dir=    $res{"dir",$it}       if (defined $res{"dir",$it});
	$kwd=    $res{"kwd",$it}       if (defined $res{"kwd",$it});
	$publ=   $res{"publ",$it}      if (defined $res{"publ",$it});
	$time=   $res{"time",$it}      if (defined $res{"time",$it});
	$country=$res{"country",$it}   if (defined $res{"country",$it});
	$res{"cast",$it}=~s/^\t*|\t*$//g;
	$#tmpcast=0;
	@tmpcast=split(/\t/,$res{"cast",$it}) 
	    if (defined $res{"cast",$it});
	$#tmpwrt=0;
	$#tmpwrt_special=0;
        # type of EndNote record
	push(@tmpwrt,"\%0".$sep."Film or Broadcast");
	push(@tmpwrt,"\%D".$sep.$year);
	push(@tmpwrt,"\%T".$sep.$pretitle.$res{"title",$it});
	# director
	@tmpdir=split(/\t/,$dir);
	foreach $dir (@tmpdir){
	    next if (! defined $dir || $dir=~/^\s*$/);
	    push(@tmpwrt,"\%E".$sep.$dir);
	}

	push(@tmpwrt,"\%9".$sep.$res{"type",$it});
	push(@tmpwrt,"\%Y".$sep.$publ)
	    if (length($publ))>0;

 	foreach $tmpcast (@tmpcast){
	    next if ($tmpcast=~/^\s*$/);
	    $tmpcast=~s/^\s*|\s*$//g;
	    if ($tmpcast eq $tmpcast[1]){
		push(@tmpwrt,"\%?".$sep.$tmpcast);
	    }
	    else {
		push(@tmpwrt,"\%?".$sep.$tmpcast);
	    }
				# check out specials
	    push(@tmpwrt_special,"\%A".$sep.$tmpcast) if ($L00 && $#special && defined $special{$tmpcast});
	}
				# check out specials
	push(@tmpwrt,@tmpwrt_special)
	    if ($L00 && $#special && $#tmpwrt_special);

	                        # runtime into notes
	if (length($time)>0){
	    $time=~s/min//;
	    $time=~s/\s//g;
	                        # convert hours
	    if ($time=~/:/){
		($tmp1,$tmp2)=split(/:/,$time);
		$time=60*$tmp1+$tmp2;
	    }
	    push(@tmpwrt,"\%P".$sep.$time);
	}
	push(@tmpwrt,"\%C".$sep.$country) 
	    if (length($country)>0);

	push(@tmpwrt,"\%K".$sep.$kwd);
	print join("\n",@tmpwrt,"\n") if ($Ldebug);
	print $fhout  join("\n",@tmpwrt,"\n");
	print $fhout2 join("\r",@tmpwrt,"\r");

    }
    close($fhout);
    close($fhout2);
    print "--- output in $fileOut ($fileOut2)\n";
}


sub name {
    local($in)=@_;
    $in=~s/^\s*|\s*$//g;
    $app=$pre="";
    $in=~s/sir //gi;

				# remove '- (bio)' stuff
    $in=~s/\s*\-?\s*\(bio.*$//g;

				# remove additional characters
    $in=~s/^[\s\#\t\,\.]*//g;

    				# no nothing if already ','
    return($in)               
	if ($in=~/, /);
    				# name (jr)
    if    ($in=~/(\s\(.*\))\s*$/){
	$tmploc=$1;
	$in=~s/\(.*//g;
	$in=~s/^\s*|\s*$//g;
	$tmploc=~s/\s//g;
	$app=$tmploc;
	$app=" ".$app;}
    				# name Jr|Sr
    elsif ($in=~/\s([sj]r\.|[sj]\b)\s*/i){
	$tmploc=$1;
	$in=~s/\s([sj]r\.|[sj]r\b)\s*//gi;
	$in=~s/^\s*|\s*$//g;
	$tmploc=~s/\s|\.*//g;
	$app=$tmploc;
	$app=" (".$app.")";}
    				# 'Di |Van |Von '
    elsif ($in=~/\s(l[ae]|D[ei]|V[ao]n|v[oa]n der|v[ao]n dem)\b\s*/i){
	$tmploc=$1;
	$in=~s/(\s)(l[ae]|D[ei]|V[ao]n|v[ao]n der|v[ao]n dem)\b\s*/$1/ig;
	$in=~s/^\s*|\s*$//g;
	$tmploc=~s/^\s*|\s*$//g;
	$pre=$tmploc." ";
#	print "xx pre='$pre', in after=$in.\n";
    }

    @tmploc=split(/\s+/,$in);
    $nameloc=$tmploc[$#tmploc];
    $nameloc.=$app       if (length($app)>0);
    $nameloc= $pre.$nameloc if (length($pre)>0);
    $nameloc.=", ";
    foreach $it (1..($#tmploc-1)){
	$tmploc[$it]=~s/\.//g;
	$nameloc.= $tmploc[$it]." ";
    }
    $nameloc=~s/\s*$//g;
#    $nameloc=~s/\b([A-Z])\./$1/g;
    return($nameloc);
}


