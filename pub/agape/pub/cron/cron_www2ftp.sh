#! /bin/sh
#
#=============================================================
# calls a perl program that checks changes on wwwPP home
#=============================================================
#

echo '       --------------------' >> /home/rost/pub/cron/cron_www2ftp.log
echo 'start: '`date` >> /home/rost/pub/cron/crontab.log
echo 'run  : /home/rost/pub/cron/wwwRost_to_ftp.pl auto'  >> /home/rost/pub/cron/cron_www2ftp.log

/home/rost/pub/cron/wwwRost_to_ftp.pl auto

echo 'end  : '`date` >> /home/rost/pub/cron/cron_www2ftp.log
#=============================================================
