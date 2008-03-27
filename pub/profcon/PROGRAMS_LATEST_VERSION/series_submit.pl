#!/usr/bin/perl -w


$list_file="/data2/ppuser/server/pub/profcon/list_ids";
open(LIST,"<$list_file");

while (<LIST>) {

($user_name)=substr($_,0,6); $user_name =~ s/\s//g; chomp($user_name);
#($name,$ch)=split(/\_/,$user_name);

#if ($ch eq "0") {
#system("cp /data/derived/pdb/split/${name}.f /data2/ppuser/server/pub/profcon/${user_name}.f");
#        }
#else {
#system("cp /data/derived/pdb/split/${user_name}.f /data2/ppuser/server/pub/profcon/${user_name}.f");
#        }


system("/data2/ppuser/server/pub/profcon/run_prof08_TMP.pl ${user_name}.f $user_name");


	}
