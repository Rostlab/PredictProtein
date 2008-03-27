#! /usr/sbin/perl
#
#
#======================================================================

&check_quota ;
$delete_Nfiles = 5 ;
$dir_old_files = "." ;

if ( $over_disk_quota || $over_file_quota ) {
 print "  Eijaje, Burkhard darf aufrauemen !! \n" ;
 @files = `\\ls -tr $dir_old_files` ;
 while ( $i < $delete_Nfiles ) {
   $command = '\rm -f ' . "@files[$i]\n" ;
   print "$command " ;
#   &run_program ("$command" , "LOGFILE" , "warn" );
   $i ++ ;
 }
}


exit;

sub check_quota {
# check if we exceed the disk and/or file quota
# if the quota is exceeded this routine returns 2 defined variables:
#   $over_disk_quota = "True" 
#   $over_file_quota = "True" 
# otherwise the variables are not defined

   undef $over_disk_quota ;
   undef $over_file_quota ;

   @check = `quota -v` ;
   $n_line = scalar(@check) ;

   foreach $line (@check) {
     $i = 0 ;
     @column = split(' ',$line) ;
     foreach $pos (@column) {
       if ($pos eq "usage" ) {
          $usage_pos = $i ;
       } elsif ($pos eq "quota" && ! $quota_pos ) {
          $quota_pos = $i ;
       } elsif ($pos eq "limit" && ! $limit_pos) {
          $limit_pos = $i ; 
       } elsif ($pos eq "files" ) {
          $file_pos = $i ;
       } elsif ($pos eq "quota" && ! $quota_file_pos ) {
          $quota_file_pos = $i ; 
       } elsif ($pos eq "limit" && ! $limit_file_pos ) {
          $limit_file_pos = $i ; 
       }
       $i++ ;
     }
     last if ($usage_pos > 0) ;
   }

   $i =0 ;
   foreach $line (@check) {
     $i ++ ;
     if ($i < $n_line) { next };
     @column = split(' ',$line) ;
     if ( @column[$usage_pos] > @column[$quota_pos] ) {
       print "Oha, we exceeded the disk quota: \n" ;
       print "usage: @column[$usage_pos]  quota: @column[$quota_pos] \n" ;
       $over_disk_quota = "True" ;
     }
     if ( @column[$file_pos] > @column[$quota_file_pos] ) {
        print "Oha, we exceeded the file quota: \n" ;
        print "files: @column[$file_pos]  quota: @column[$quota_file_pos] \n" ;
        $over_file_quota = "True" ;
     }
   }
}
