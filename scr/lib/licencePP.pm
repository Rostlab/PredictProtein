##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#                                                                              #
#	Copyright				  Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#			    br  v 2.0   	  May,          1998           #
#			    br  v 2.1             Jan,          1999           #
#------------------------------------------------------------------------------#
# note: automatically adding lines by the cgi called from the WWW license submission
#       /home/$ENV{USER}/predictprotein/send_license.html
#       -> /home/$ENV{USER}/server/scr/www/licensePP.pl
#          (when changing that file do cp to /home/www/cgi/pp/license )
#       
#       

package licence;

 INIT: {
				# --------------------------------------------------
				# include phd_env package as define in $PPENV or default
     if ($ENV{'PPENV'}) {
	 $env_pack = $ENV{'PPENV'};}
     else {
	 $env_pack = "$ENV{HOME}/server/scr/envPP.pm"; } # HARD CODDED
     require "$env_pack"; 

     # get some global from env
     # ========================
     $File_key=           &envPP'getLocal("file_key");         #e.e'
     $File_licence=       &envPP'getLocal("file_licence");     #e.e'
     $File_com_pred=      &envPP'getLocal("file_comLog");    #e.e'
     $File_licenceComLog= &envPP'getLocal("file_licenceComLog"); #e.e'
     $File_licenceNotLog= &envPP'getLocal("file_licenceNotLog"); #e.e'
     $Default_password=   &envPP'getLocal("password_def"); #e.e'

    foreach $kwd (
		  "file_licenceGiven","file_licenceCount","file_licFlagCount",
		  ){
	next if (length($kwd)<1);
	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv::initPackLicence ERROR no def of kwd=$kwd, (envPP)";
	    $Lerr=1;}}

     # get the name of this file
     $This_file = $0;
     $This_file =~ s,.*/,,;
}

#==========================================================================
sub predict_not_allowed {
    local ($user_addr, $password) = @_ ;
    local ($ret_no_problem, $ret_ex_licence, $ret_ov_licence, $ret_no_licence);
    local ($date_beg, $date_end, $company, $pred_payed, $pred_done);
    local (@date, $today, $ret_ok);
    local ($message, $the_date);

#--------------------------------------------------------------------------------
#   checks whether or not has a valid licence associate with it password
#   if user is commercial
#
#   this sub return a string
#      - "" (FALSE)          if licence is OK
#      - "licence expired"   if licence has expired
#      - "licence exhausted" if licence exists but all autorized predicts are done
#      - "invalid password"  if password is invalid
#      - "no licence"        if no licence and commercial
#--------------------------------------------------------------------------------

#   ----------------------------------------------------------------------
#   define return status values and some default
#   ----------------------------------------------------------------------
    $ret_no_problem= 0;
    $ret_ex_licence= "licence expired  ";
    $ret_ov_licence= "licence exhausted";
    $ret_invalid_pw= "invalid password ";
    $ret_no_licence= "no licence       ";
    $ret_ok        = "OK               ";
    $pred_done     = 0;
    $licence_found = 0;

#   ----------------------------------------------------------------------
#   set password in upper case
#   ----------------------------------------------------------------------
    $password =~ tr/a-z/A-Z/;
    $Default_password =~ tr/a-z/A-Z/;

#   ----------------------------------------------------------------------
#   when are we ?
#   ----------------------------------------------------------------------
    @date=     localtime(time) ;
    $today=    $date[3] . "-" .  ++$date[4] . "-" . $date[5] ; 
    $the_date= `date`;
    chop ($the_date);
				# --------------------------------------------------
				# commercial or not?
				# --------------------------------------------------
    if ( &is_commercial($user_addr)) {
	$is_commercial= 1;}
    else {
	$is_commercial= 0;}

				# --------------------------------------------------
				# Default password (no password given)
				# --------------------------------------------------
    if ($password eq $Default_password) {
	if ($is_commercial) {
	    $message= sprintf ("%s\t%s\t%s\t%s" , 
			       $password,$user_addr,$ret_no_licence,$the_date);
	    system "echo $message >> $File_licenceComLog";
	    return $ret_no_licence; }
	else {
	    $message = sprintf ("%s\t%s\t%s\t%s" , 
				$password,$user_addr,$ret_ok,$the_date);
	    system "echo $message >> $File_licenceNotLog";
	    return $ret_no_problem;}}
				# some people give a password 
    elsif (! $is_commercial) {	#    without needing it!
	    $message = sprintf ("%s\t%s\t%s\t%s" , 
				$password,$user_addr,$ret_ok,$the_date);
	    system "echo $message >> $File_licenceNotLog";
	    return $ret_no_problem;}
	
				# --------------------------------------------------
				# read licence file 
				# --------------------------------------------------
    open(LICENCE, $File_licence) || 
	warn "$This_file: Cannot open file_licence=$File_licence: $!\n";

    while (<LICENCE>) {
	$_ =~ tr/a-z/A-Z/;
	next if ($_!~/^$password\t/);

	$licence_found= 1;
				# extract licence data
	($password,$pred_payed,$date_beg,$date_end,$company)= split(/\t/,$_);
	$date_end=~ s/\s//g;
	$pred_payed=~ s/\s//g;

				# does the licence expired
	if (&diff_date($date_end, $today) < 0) {
	    $message=sprintf("%s\t%s\t%s\t%s",
			     $password,$user_addr,$ret_ex_licence,$the_date);
	    system "echo $message >> $File_licenceComLog";
	    close(LICENCE);
	    return $ret_ex_licence;}
	last;}
    close(LICENCE);

				# --------------------------------------------------
				# Test if a licence was found
				# --------------------------------------------------
    if (!$licence_found){
	$message= sprintf ("%s\t%s\t%s\t%s",
			   $password,$user_addr, $ret_invalid_pw, $the_date);
	system "echo $message >> $File_licenceComLog";
	return $ret_invalid_pw;}
	    
				# --------------------------------------------------
				# read commercial prediction history file
				# --------------------------------------------------
    open(COMPRED, $File_com_pred) || 
	warn "$This_file: Can't open $File_com_pred: $!\n";
    while (<COMPRED>) {
	$_ =~ tr/a-z/A-Z/;
	if ($_=~/^$password\t/ ) {
	    ($password, $pred_done)= split(/\t/,$_);
	    $pred_done =~ s/\s//g;
	    last;}}
    close(COMPRED);
				# --------------------------------------------------
				# more prediction than allowed ?
				# --------------------------------------------------
    if ( ($pred_payed) <= $pred_done ) {
	$message=sprintf("%s\t%s\t%s\t%s",
			 $password,$user_addr,$ret_ov_licence,$the_date);
	system "echo $message >> $File_licenceComLog";
	return $ret_ov_licence;}

				# --------------------------------------------------
				# no error detected
				# --------------------------------------------------
    $message= sprintf ("%s\t%s\t%s\t%s" , 
		       $password,$user_addr,$ret_ok,$the_date);
    system "echo $message >> $File_licenceComLog";
    return $ret_no_problem;
}				# end licence_check

#==========================================================================
sub record_predict{
    local ($password) = @_ ;
    local ($pred_done, $find, $file_com_tmp);

    # set password in upper case
    $password =~ tr/a-z/A-Z/;
    $Default_password =~ tr/a-z/A-Z/;

    # exit if default password
    return                      
	if ($password eq $Default_password);
    
    # create of temporary copy of com_pred file
    $file_com_tmp = "$File_com_pred" . "." . $$;

#   --------------------------------------------------
#   read commercial prediction log file
#   --------------------------------------------------
    open(COMPRED, $File_com_pred) || warn "$This_file: Can't open $File_com_pred: $!\n";
    open(COMTMP, ">$file_com_tmp") || warn "$This_file: Can't open $file_com_tmp: $!\n";
    while (<COMPRED>) {
	if ($_=~/^$password\t/ ) {
	    ($password, $pred_done) = split(/\t/,$_);
	    $pred_done =~ s/\s//g;
	    $pred_done++;
	    printf COMTMP "%s\t%s\n" , $password, $pred_done;
	    $find = 1;}
	else {
	    printf COMTMP $_;}}
    close(COMPRED);
    close(COMTMP);

#   --------------------------------------------------
#   update the file
#   --------------------------------------------------
    if ($find ) {
	system ("mv $file_com_tmp $File_com_pred");}
    else {
	system ("\\rm $file_com_tmp");
	# append user to commercial prediction  file
	open(COMPRED,">>$File_com_pred")  || 
	    warn "licence_check: Can't open $File_com_pred $!\n";
	printf COMPRED "%s\t%s\t%s\t%s\t%s\n" ,$password, 1;
	close(COMPRED);}
}
				# end of record_prediction

#==========================================================================
sub diff_date {
    local ($date1, $date2) = @_;
    local ($d1, $d2, $m1, $m2, $y1, $y2 );
#--------------------------------------------------------------------------------
#   return the date1 - date2 after converting date to absolute arbitrary number
#   if dat1 > date2 it return a positive number else a negative one
#   the dates must be in format dd-mm-yy (like 25-10-94)
#--------------------------------------------------------------------------------
  
    ($d1, $m1, $y1) = split('-',$date1);
    ($d2, $m2, $y2) = split('-',$date2);
    $n1= ($y1 * 10000) + ($m1 * 100) + $d1;
    $n2= ($y2 * 10000) + ($m2 * 100) + $d2;
    return ($n1 - $n2);
}				# end diff_date

#==========================================================================
sub is_commercial {
    local ($addr) = @_;
#--------------------------------------------------------------------------------
#   test if the address belong to a commercial user.
#   return TRUE or FALSE
#--------------------------------------------------------------------------------

				# aol, t-online
    return(0)                   if ($addr =~ /[\@\.](aol|hotmail|t-online|netscape)\.com/);
    return(0)                   if ($addr =~ /[\@\.](yahoo|compuserve|mailcity)\.com/);
    return(0)                   if ($addr =~ /[\@\.](netmail|angelfire)\.com/);

				# e.g. 'singnet.com.sg'
    return(0)                   if ($addr =~ /net\.com\.[a-z][a-z]$/);
				# .com extension
    return(1)                   if ($addr =~ /\.com$/i);

				# .co.uk|jp extension
    return(1)                   if ($addr =~ /\.co\.(uk|jp|[a-z][a-z])$/i);
    return(1)                   if ($addr =~ /\.com\.(uk|jp|[a-z][a-z])$/i);
    return(1)                   if ($addr =~ /\.mil$/i);
    return(1)                   if ($addr =~ /\.firm$/i);
    return(1)                   if ($addr =~ /\.store$/i);
    return(1)                   if ($addr =~ /\.ltd\.[a-z][a-z]$/i);
    return(1)                   if ($addr =~ /\.plc\.[a-z][a-z]$/i);
    return(1)                   if ($addr =~ /\.tm$/i);
	
    return(0);			# not comercial
}				# end is_commercial

#==========================================================================
sub decrypt{
    local ($user_addr,$file_name,$tmp_file1,$tmp_file2,$tmp_file3,$tmp_file4) = @_ ;
    local ($key, $no_crypt, $crypt_ok, $crypt_ko, $line, $crypt_section);
#--------------------------------------------------------------------------------
#   checks whether a file contains a crypted section and then try to uncrypt it
#   (if there is a crypt key available for this user)
#
#   the sub return a status which can be:
#     - "N" : not crypt needed
#     - "Y" : uncrypt needed was successfull
#     - an error message : uncrypt needed but fails
#--------------------------------------------------------------------------------
    # initialise
    $crypt_of=      "N";
    $crypt_on=      "Y";
    $crypt_section= 0;
    $crypt_flag=    0;

    # Is there a crypted section? if yes,extract it in $tmp_file1 
    # ===========================================================

    open(FILETMP1,">$tmp_file1") || return "$tmp_file1: Cannot open new=$tmp_file1: $!";
    open(FILEIN,  $file_name)    || return "$file_name: Cannot open old=$file_name: $!";
    while (<FILEIN>) {chop;
		      if ($_ !~ $crypt_section && $_ =~ /^begin / ) {
			  $crypt_section=  1;
			  print FILETMP1 "begin 600 $tmp_file2\n";}
		      elsif ($crypt_section && $_ =~ /^end/ ){
			  $crypt_section=  0;
			  $crypt_flag=     1;
			  print FILETMP1 "$_\n";}
		      elsif ($crypt_section) {
			  print FILETMP1 "$_\n";}}close(FILEIN);
    close(FILETMP1);

    # if no complete crypted section , just return
    return $crypt_of 
	if (! $crypt_flag);
	

    # try to get users encryption key
    # ===============================

    # set user address in upper case
    $user_addr=~ tr/a-z/A-Z/;

    # read key file (if impossible return no crypt) 
    open(KEY, $File_key) || return $crypt_of ;
    while (<KEY>) {$line = $_ ;
		   $_ =~ tr/a-z/A-Z/;
		   if ($_=~/^$user_addr\t(\S*)/ ) {
		       $key = $line;
		       chop($key);
	    $key =~ s/^\S*\t(\S*)/$1/;}}close(KEY);

    # if no key found , just return no crypt
    if (!$key) {
	return $crypt_of ; }

    # try to uncrypt the crypted section
    # ===================================

    # uudecode step
    $status= system "uudecode $tmp_file1";
    return "uudecode return a bad status"
	if ($status) ;
	

    # is the crypt file here
    return "no crypted file after uudecode"
	if (! -B $tmp_file2);
	

    # uncrypt step
    $status= system "crypt $key < $tmp_file2 > $tmp_file3";
    return "crypt return a bad status"
	if ($status);
	

    # is the file uncrypted
    return "no uncrypted file after crypt "
	if (! -T $tmp_file3);
	

    # rebuild a input file
    # ====================
    
    # copy the uncrypt header in $tmp_file4
    open(FILETMP4, ">$tmp_file4") || return "$This_file: Can't open $tmp_file4: $!";
    open(FILEIN, $file_name) || return "$This_file: Can't open $file_name: $!";
    while (<FILEIN>) {chop;
		      if ($_=~ /^begin / ) {
			  close(FILETMP4);
			  last;}
		      else {
			  print FILETMP4 "$_\n";}}
    close(FILEIN);

    # append the decrypt part to $tmp_file4
    $status = system "cat $tmp_file3 >> $tmp_file4";
    return "bad status when appending to $tmp_file4"
	if ($status);
	
    print "ca va pas non\n";
    # overwrite the input file 
    $status= system "\\mv $tmp_file4 $file_name";
    return "bad status when overwriting input file"
	if ($status);
	

    # test the result file
    return $crypt_on;
}
	
#==========================================================================
sub crypt{
    local ($user_addr, $file_name, $basename) = @_ ;
    local ($key, $no_crypt, $crypt_ok, $crypt_ko, $line);
    local ($tmp_file1, $tmp_file2, $tmp_file3);
#--------------------------------------------------------------------------------
#   checks whether a file must or must not be crypted
#   The file is crypted if there is a crypt key available for this user else not
#
#   the sub return a status which can be:
#     - "N" : not crypt needed
#     - "Y" : crypt needed was successfull
#     - an error message : crypt needed but fails
#
#--------------------------------------------------------------------------------

    # initialise
    $crypt_of= "N";
    $crypt_on= "Y";

    # set user address in upper case
    $user_addr =~ tr/a-z/A-Z/;

    # read key file 
    open(KEY, $File_key) || return "$This_file: Can't open $File_key: $!";
    while (<KEY>) {$line= $_ ;
		   $_=~ tr/a-z/A-Z/;
		   if ($_=~/^$user_addr\t(\S*)/ ) {
		       $key= $line;
		       chop($key);
		       $key=~ s/^\S*\t(\S*)/$1/;}}close(KEY);

    # if no key found , just return
    return $crypt_of 
	if (!$key);
	

    # else try to crypt the file
    $tmp_file1= "$basename" . ".k1";
    $tmp_file2= "$basename" . ".k2";

    # crypt step
    $status= system "crypt $key < $file_name > $tmp_file1";
    return "crypt return a bad status"
	if ($status);
	
    # is the crypt file here
    return "no crypted file after crypt"
	if (! -B $tmp_file1);

    # uucode step
    $status= system "uuencode $tmp_file1 prediction > $tmp_file2";
    return "uucode return a bad status" 
	if ($status);
	

    # is the uucode file here
    return "no uucode file after uucode"
	if (! -T $tmp_file2);
	

    # overwrite the input file 
    $status= system "\\mv $tmp_file2 $file_name";
    return "bad status when overwriting input file"
	if ($status);
	

    # test the result file
    return $crypt_on;
}

1; # a package must return a value




