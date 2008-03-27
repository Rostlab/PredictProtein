#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="produces postscript letter plots from distributions\n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1997	       #
#       Miguel Andrade          andrade@embl-heidelberg.de      1997           #
#                                                                              #
#       minor changes by:                                                      #
#                                                                              #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	1999	       #
#------------------------------------------------------------------------------#
#
# original comments:
#
# reads rdb
#
# 1st column = char
# next columns = property values
# last column = legend (break into lines if they have ',')
#
# output: PostScript representation
#
# Miguel A. Andrade June 1997 (EMBL-Heidelberg)
#------------------------------------------------------------------------------#

$[ =1 ;				# count from one
#$[ =0 ;				# count from one

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName RDB file (1st col: char, 2nd: property values, last: legend (lines 'line1,line2')'\n";
    print  "opt:  \n";
    exit;}

				# ------------------------------
				# defaults

$fhin="FHIN";$fhout="FHOUT";

# predefined color assignation:
#$green=    '0 1 0';
$green2=   '0 1 0.5';
$red=      '1 0 0';
$blue=     '0 0 1';
#$magenta=  '1 0 1';
$black=    '0 0 0';

$color{'D'} = $red;
$color{'E'} = $red;

$color{'R'} = $blue;
$color{'K'} = $blue;

$color{'A'} = $black;
$color{'C'} = $black;
$color{'G'} = $black;
$color{'F'} = $black;
$color{'H'} = $black;
$color{'I'} = $black;
$color{'L'} = $black;
$color{'M'} = $black;
$color{'P'} = $black;
$color{'V'} = $black;
$color{'W'} = $black;
$color{'Y'} = $black;

$color{'N'} = $green2;
$color{'Q'} = $green2;
$color{'S'} = $green2;
$color{'T'} = $green2;


# PostScript parameters

# page position
$xpos = 50;
$ypos = 300;

# page dimensions
$xpage = 450;
$ypage = 300;

$xlabel = $ypage/50;
$ylabel = $xpage/8;

$col_step = ($xpage - $ylabel)/20;
$row_step = ($ypage - $xlabel)/3;

$max_heigth= 13;
$bar_value=  15;
$bar_ticks=   3;
$char_width=  1.5 * $col_step;
$bar_width=   $char_width;


$fileIn=$ARGV[1];
				# ------------------------------
				# open input file

open($fhin,$fileIn) || die "*** $scrName ERROR opening file $fileIn";

				# output = postscript
$fileOut=$fileIn; $fileOut=~s/^.*\/|\s//g;
$fileOut=~s/\..*$//;  $fileOut="out-letter" if (length($fileOut)<2); 
$fileOut.=".ps";

open($fhout,">".$fileOut) || die "*** $scrName ERROR opening file out=$fileOut\n";

# print PostScript prolog
print $fhout "%!PS-Adobe-1.0\n";
print $fhout "%%Creator: $scrName\n";
print $fhout "%%DocumentFonts: Courier\n";
print $fhout "%%DocumentFonts: Helvetica\n";
print $fhout "%%Pages: (atend)\n";
print $fhout "%%EndComments\n";
print $fhout "%%EndProlog\n";
print $fhout "%%Page: 1 1\n";

$data_counter= 0;
$counter=      0;
while(<$fhin>){

    next if ($_=~/^\#/);
    next if ($_=~/^[\t\s\n]*$/);
    $line=$_;

    if ($counter == 0) {

        # prepare fonts for ylabel
	print $fhout "/Helvetica findfont\n";
	print $fhout "10 scalefont\n";
	print $fhout "setfont\n";

	# get column names
	@col_id=  split(/\t/,$_);
	$num_col= scalar(@col_id);
	$counter++;

	# print  ylabels
	for ($i= 2; $i < $num_col; $i++) {
	    $x= $xpos;
	    $y= $ypos + $xlabel + $ypage - ($num_col  - $i)*$row_step;
	    print $fhout "$x $y moveto";
	    print $fhout "($col_id[$i]) show\n";
	}

        # print reference bars
	$bar_x=       $xpos + $xpage + $bar_width;
	$bar_heigth=  ($bar_value / $max_heigth) * $row_step;
	$tick_heigth= $bar_heigth/$bar_ticks;
	$tick_value=  $bar_value / $bar_ticks;
	$x=           $bar_x;

	print $fhout "/Helvetica-Bold findfont [$bar_width 0 0 $tick_heigth 0 0]  
makefont setfont\n";

	for ($i = 2; $i < $num_col; $i++) {
	    $bar_y = $ypos + $xlabel + $ypage - ($i *$row_step) -1;

	    for ($j = 0; $j < $bar_ticks; $j++) {
		$y = $bar_y + ($tick_heigth * $j * 0.7);
		$tick_text = ($j + 1) * $tick_value;
		# $tick_text .= '%';
		
		print $fhout "$x $y moveto\n";
		print $fhout "($tick_text) stringwidth pop -2 div 0 rmoveto\n";
		print $fhout "($tick_text) show\n";
	    }
	}
	

	# prepare fonts for xlabels
	$xlabel_string = "/Helvetica findfont\n";
	$xlabel_string .= "8 scalefont\n";
	$xlabel_string .= "setfont\n";

	next;
    }
    if ($counter == 1){
	$counter++;
	next;
    }

    @val=   split(/\t/,$line);
    $char=  $val[1];

    # annotate xlabel
    $label= $val[$num_col];
    chop($label);

    if ($label ne ''){

	# break label into lines
	@label_lines = split(/,\s?/, $label);

	$line_counter = 0;
	foreach $line(@label_lines) {

	    $x = $ylabel +$xpos + $col_step * ($data_counter + 0.5);
	    $y = $ypos - 10 * $line_counter;
	    $xlabel_string .= "$x $y moveto\n";
	    $xlabel_string .= "($line) stringwidth pop -2 div 0 rmoveto\n";
	    $xlabel_string .= "($line) show\n";
	    $line_counter++;
	}
    }

    for ($i= 2; $i < $num_col; $i++){

	$x=      $ylabel +$xpos + $col_step * ($data_counter + 0.5);
	$y=      $ypos + $xlabel + $ypage - ($num_col - $i)*$row_step;
	$heigth= ($val[$i] / $max_heigth) * $row_step;
	
	print $fhout "/Helvetica-Bold findfont [$char_width 0 0 $heigth 0 0]  
makefont setfont\n";
	print $fhout "$color{$char} setrgbcolor\n";
	print $fhout "$x $y moveto\n";
	print $fhout "($char) stringwidth pop -2 div 0 rmoveto\n";
	print $fhout "($char) show\n";
    }

    ++$data_counter;
}

print $fhout "0 0 0 setrgbcolor\n";

# print xlabels
print $fhout "$xlabel_string\n";


# PostScript end
print $fhout "showpage\n";
print $fhout "%%","Trailer\n";
print $fhout "%%","Pages: 1\n";

close($fhin);
close($fhout);

    print "--- ended fine, output=$fileOut\n";

# end

