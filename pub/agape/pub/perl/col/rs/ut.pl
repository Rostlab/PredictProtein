#! /usr/sbin/perl
#
#
#======================================================================

sub run_program {
    local ($cmd, $log_file, $action) = @_ ;
    local ($out_command);

    ($cmd, @out_command) = split(",",$cmd) ;

    print "running command: $cmd\n" ;
    open (TMP_CMD, "|$cmd") || ( do {
             if ( $log_file ) {
                print $log_file "Can't run command: $cmd\n" ;
             }
             warn "Can't run command: $cmd\n" ;

             $action ;
       } );
    foreach $command (@out_command) {
# delete end of line, and spaces in front and at the end of the string
      $command =~ s/\n// ;
      $command =~ s/^ *//g ;
      $command =~ s/ *$//g ;
      print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;
}

sub open_file {
    local ($file_handle, $file_name, $log_file) = @_ ;
    local ($temp_name) ;

    close ("$file_handle") ;
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
       print "INFO: file $temp_name does not exist; create it\n" ;
       open ($file_handle, ">$temp_name") || ( do {
             warn "Can't create new file: $temp_name\n" ;
             if ( $log_file ) {
                print $log_file "Can't create new file: $temp_name\n" ;
             }
       } );
       close ("$file_handle") ;
    }
  
    open ($file_handle, "$file_name") || ( do {
             warn "Can't open file: $temp_name\n" ;
             if ( $log_file ) {
                print $log_file "Can't create new file: $temp_name\n" ;
             }
             die ;
       } );
}
1;






