#!/bin/env perl5
#
# (C) Rob W.W. Hooft, EMBL 1989-1995.
#

##
## process arguments
##
$job=shift;
$queue=shift;
$args=join(" ",@ARGV);
$PWD=`pwd`;

##
## See if we recognize the queue name. If not, it is another argument
##
if ($queue!="now" && $queue!="batch" && $queue!="soon" && $queue!="quick") {
  $args="$queue $args" if $queue;
  $queue="";
}
##
## Turn the job into a reasonable jobname
##
$name=$job;
$name=~s/^.*\///;
$name=~s/ .*$//;
$name="batchjob" unless $name;
##
## Do not overwrite the logfile
##
if (-e "$name.log") {
  warn "subm: Logfile exists. Renamed.\n";
  $inode=(stat("$name.log"))[1];
  rename("$name.log","$name.log$inode");
}
##
## See if it is a command or a script. Commands go in short queue by default
## scripts go in long queue by default. Non-executable scripts need to be
## sourced?
##
if (-f $job) {
  $queue="batch" unless $queue;
  $job="source $job" unless (-x $job);
} else {
  $queue="now" unless $queue;
}
##
# ## We now have all information required for submission 
require "lib-ut.pl"; require "lib-br.pl";
##
open(JOB,"|/usr/local/lsf/bin/qsub -q $queue -o $name.log -eo -r $name $args");
print JOB <<ENDJOB;
#!/bin/sh
cd $PWD
echo Job \$LSB_JOBNAME started at \`date\` on \$LSB_QUEUE
/bin/time $ENV{SHELL} -c '$job $options'
errno=\$?
write $ENV{USER} <<ENDWRITE > /dev/null 2>&1 
Job \$LSB_JOBNAME (queue \$LSB_QUEUE) finished with status \$errno
ENDWRITE
exit
ENDJOB
close(JOB);
