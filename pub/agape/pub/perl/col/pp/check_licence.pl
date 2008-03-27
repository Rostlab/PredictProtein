#!/usr/pub/bin/perl4
#----------------------------------------------------------------------
# xscriptname
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	check_license License_phd title no_free_requests user 
#                             file_license_fst file_license_new
#
# task:		1: check user = .com ?
#               2: license exists ?
#               3: license expired ?
#               4: add new user
#               5: increase number of requests by current user
#
# routines:     license_check
#               license_date
# 		
#
#--------------------------------------------------------------------------------#
#	Burkhard Rost	               		  April,        1994             #
#			          changed:	  April,      	1994             #
#	EMBL				          Version 0.1                    #
#	Meyerhofstrasse 1                                                        #
#	D-69117 Heidelberg		          (rost@EMBL-Heidelberg.DE)      #
#--------------------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;
push (@INC, "/home/schneider/perl") ;
require "ctime.pl";
require "/home/phd/ut/perl/lib-ut.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; 
$month_out = "";
&conv_month_3char_to_number($Date[1]);
$date_loc = $Date[2] . "-" . $month_out . "-" . $Date[$#Date]; # x.x

#----------------------------------------
# read input
#----------------------------------------
$user          	  = $ARGV[1];
$file_license	  = $ARGV[2];
$title_tmp	  = $ARGV[3];
$no_free_requests = $ARGV[4];
$file_license_fst = $ARGV[5];
$file_license_new = $ARGV[6];
$file_request=      $ARGV[7];

$file_tmp = "/home/phd/backup/tmplicense_users.log";

				# ******************************
				# hack
$Lhas_password=0;
open(FHTMP1,"$file_request")  || warn "license_check 0: Can't open $file_request: $!\n";
while (<FHTMP1>) {
    $tmp=$_;$tmp=~tr/[A-Z]/[a-z]/;
    if ( $tmp=~ /password\(.*\)/ ) {
	$Lhas_password=1; }
    last if ($Lhas_password);
}
close(FHTMP1);

if (!Lhas_password) {
    open(FHTMP1,">>$file_tmp")  || warn "license_check 1: Can't open $file_tmp: $!\n";
    &license_check($user, $file_license, $date_loc, $title_tmp, $no_free_requests);

    if ( $License_fst ) {
	$file_out = "$file_license_fst";
	open(FHOUT,">$file_out") || warn "license_check 2: Can't open $file_out: $!\n";
	print FHOUT "new license : user=$user, file=$title_tmp, \n";
	close(FHOUT);
    } elsif ( $License_new ) {
	$file_out = "$file_license_new";
	open(FHOUT,">$file_out") || warn "license_check 3: Can't open $file_out: $!\n";
	print FHOUT "license expired: user=$user, file=$title_tmp, \n";
	close(FHOUT);
    }
    close(FHTMP1);
}

exit;


#==========================================================================
sub license_check {
    local ($user_in, $file_license, $date_loc, $title_in, $no_free_requests) = @_ ;

#--------------------------------------------------------------------------------
#   checks whether or not current user is commercial,
#   and if, then checks the license
#
#   global: user_name
#--------------------------------------------------------------------------------

    $user_in =~ tr/[A-Z]/[a-z]/;
    ($name,$rest)=split(/\@/,$user_in);
    @ar_address = split(/\./,$rest);

#   ----------------------------------------------------------------------
#   user is .com
#   ----------------------------------------------------------------------
    if ( $ar_address[$#ar_address] =~ /com/ ) {
	$License_fst = 0; $License_new = 0;
#	$site = $rest; $site =~ s/\.com|\n|\s//g;
	$site = $ar_address[$#ar_address-1]; $site =~ s/\.com|\n|\s//g;

#       --------------------------------------------------
#       read license file 
#       --------------------------------------------------
	open(FHIN,$file_license)  || warn "license_check: Can't open $file_license: $!\n";
	$Lfound = 0;
	while (<FHIN>) {
	    if ( /$site/ ) {
		($address_lic,$site_lic,$date_lic,$payed_lic,$req_lic) = split(/\t/,$_);
		$date_lic =~ s/\s//g; $payed_lic =~ s/\s//g; $req_lic =~ s/\s|\n//g; # 
		$Lfound = 1;
	    }
	} close(FHIN);

	if ($Lfound) {
	    print "check_license.pl found: \t $site, $date_lic, $payed_lic, $req_lic \n"; #x.x
	    $License_expired = $License_tooold = $License_toomany = 0;

#           --------------------------------------------------
#           too old?
#           note: global $License_expired, $License_tooold
#           --------------------------------------------------
	    &license_date ($date_loc, $date_lic);

#           --------------------------------------------------
#           more requests than payed?
#           --------------------------------------------------
	    if ( ($payed_lic + $no_free_requests) < $req_lic ) {
		$License_expired = 1; $License_toomany = 1;
	    }

#           --------------------------------------------------
#           not expired -> add
#           --------------------------------------------------
	    if (! $License_expired) {
		open(FHIN,"$file_license")  || 
		    warn "license_check: Can't open $file_license: $!\n";
		$file_tmp = "$title_in" . "_lic.tmp";
		open(FHTMP,">$file_tmp")  || 
		    warn "license_check: Can't open $file_license: $!\n";
		while (<FHIN>) {
		    if ( /$site/ ) {
			++$req_lic;
			printf FHTMP "%s\t%s\t%s\t%s\t%s\n" ,
			        $address_lic,$site_lic,$date_lic,$payed_lic,$req_lic;
		    } else {
			print FHTMP $_;
		    }
		} close(FHIN); close(FHTMP);
		system ("\\cp $file_tmp $file_license"); system ("\\rm $file_tmp");
	    } else {
		if ( $payed_lic == 0 ) {
		    $License_fst = 1;
		    print "\t \t \t apply first time \n"; # x.x
		} else {
		    $License_new = 1;
		    print "\t \t \t apply anew \n"; # x.x
		}
	    }

#       --------------------------------------------------
#       append user to license file
#       --------------------------------------------------
	} else {
	    open(FHIN,">>$file_license")  || 
		warn "license_check: Can't open $file_license: $!\n";
	    printf FHIN "%s\t%s\t%s\t%s\t%s\n" ,
	                 $user_in,$site,$date_loc,0,1;
	}
    } else {
	print FHTMP1 "address passed:$user| \n"; # x.x
    }


    
}				# end license_check

#==========================================================================
sub license_date {
    local ($date_loc, $date_lic ) = @_;
    local ($diff_year, $diff_month, $diff_day, @ar_date_now, @ar_date_lic);

#--------------------------------------------------------------------------------
#   checks date and number of license
#
#   global: $License_expired, $License_tooold
#--------------------------------------------------------------------------------

#   --------------------------------------------------
#   check date
#   --------------------------------------------------
    @ar_date_now = split('-',$date_loc); @ar_date_lic = split('-',$date_lic); 
    $diff_year  = $ar_date_now[$#ar_date_now]-$ar_date_lic[$#ar_date_lic];
    $diff_month = $ar_date_now[2]-$ar_date_lic[2]; 
    $diff_day   = $ar_date_now[1]-$ar_date_lic[1]; 

#   ------------------------------
#   older than a year ?
#   ------------------------------
    if ( $diff_year >= 2 ) {
	$License_expired = 1; $License_tooold = 1;

#   ------------------------------
#   same year  => check month
#   ------------------------------
    } elsif ( $diff_year == 1 ) {
	if ( $diff_month > 0  ) {
	    $License_expired = 1; $License_tooold = 1;

#       ------------------------------
#       same month => check day
#       ------------------------------
	} elsif ( ($diff_month == 0) && ($diff_day > 0)  ) {
	    $License_expired = 1; $License_tooold = 1;
	}
    } 

}				# end license_date_num



#==========================================================================
sub conv_month_3char_to_number {
    local ($in) = @_ ;
    local ($tmp, $tmp1, $it);
#--------------------------------------------------------------------------------
#   converts "Jan" -> 1
#   global: month_out
#--------------------------------------------------------------------------------
    $tmp="JanFebMarAprMayJunJulAugSepOctNovDec";
    for ($it=1; $it<=12; ++$it) {
	$tmp1 = substr($tmp,(($it-1)*3+1),3);
	if ($tmp1 =~ $in) { $month_out = $it; $it = 15; }
    }
    if ( $it < 15 ) { print "ERROR \n", 
		      "ERROR in conv_month_3char_to_number: $in cannot be converted \n", 
		      "ERROR \n"; }

}				# conv_month_3char_to_number



