#!/bin/perl

$x=0;
$fileIn  = $ARGV[0];
$str ="<table border='0' cellpadding='10' cellspacing='4'>";
open (FI,$fileIn) || die "fileIn=$fielIn error\n";
while (<FI>){
    if (length($_) > 1){
	@l = split /\t/,$_;
	if ($x>1){
	    if ($l[0] eq 'y'){
		$bg = "#0000ff";
		$font = "white";
	    }else{
		$bg = "cccccc";
		$font = "black";
	    }
	    $str .="<tr>\n";	
	    for ($i=1; $i< scalar(@l); $i++){

		$str .="<td bgcolor='$bg' width='20%'>\n";
		$str .= "<font color='$font' <font face='Verdana, Arial, Helvetica, sans-serif'>\n";	
		$str .= "$l[$i]";
		$str .= "</font>\n";	
		$str .= "</td>\n";  

	    }

	    $str .= "</tr>\n";	

	}else{
	    $str .= "<tr>\n";
	    for ($i=1; $i< scalar(@l); $i++){
		$str .= "<th width='20%'><font face='Verdana, Arial, Helvetica, sans-serif'>$l[$i]</font></th>\n";
	    }			# 
	    $str .= "</tr>\n";	    			
	}			# 
#	print "$l[0]\n";	# 
    }			       
    $x++;
}
close FI;
$str .="</table>\n";
print $str;
