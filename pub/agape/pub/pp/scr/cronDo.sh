#! /bin/sh
#
#=============================================================
# calls a perl program that checks changes on wwwPP home
#=============================================================
#

echo '       --------------------' >> /home/rost/pub/pp/log/crontab.log
echo 'start: '`date` >> /home/rost/pub/pp/log/crontab.log
echo 'run  : /home/rost/pub/pp/scr/wwwPP2ftp.pl /home/www/htdocs/Services/sander/predictprotein/'  >> /home/rost/pub/pp/log/crontab.log

/home/rost/pub/pp/scr/wwwPP2ftp.pl /home/www/htdocs/Services/sander/predictprotein/ >> /home/rost/pub/pp/log/screen-wwwPP2ftp.tmp

echo 'end  : '`date` >> /home/rost/pub/pp/log/crontab.log
#=============================================================
