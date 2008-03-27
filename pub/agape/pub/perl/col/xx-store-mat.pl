#==========================================================================================
sub wrtMergedHeader {
    local ($fhloc,$sep,$nFilesLoc,$naliWrt,@desIn) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtCasp2                       
#--------------------------------------------------------------------------------

				# ------------------------------
				# header
    print $fhloc "# Perl-RDB\n# \n";
    printf $fhloc "%5s$sep%5s","nProt","nHit";
    foreach $des(@desIn){$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
			 printf $fhloc "$sep$tmp",$des;}print $fhloc "\n";
				# format
    printf $fhloc "%5s$sep%5s","5N","5N";
    foreach $des(@desIn){$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
			 $tmpX=&form_perl2rdb($form{"$des"});
			 printf $fhloc "$sep$tmp",$tmpX;}print $fhloc "\n";
				# ------------------------------
				# body
    
    foreach $itFiles (1..$nFilesLoc){
	foreach $it (1..$naliWrt){
	    printf $fhloc "%5d$sep%5d",$itFiles,$it;
	    foreach $des(@desIn) {
		if (! defined $ali{"$itFiles","$it","$des"}){
		    $tmpX="xx";
		    print "*** not defined: itFiles=$itFiles, it=$it, des=$des,\n";}
		else {$tmpX=$ali{"$itFiles","$it","$des"};}
		$tmp="%".$form{"$des"};
		printf $fhloc "$sep$tmp",$tmpX;}print $fhloc "\n";
	}}
}				# end of wrtCasp2

