#!/bin/sh
#
#=============================================================
#   
# stop and start the scanner
#
#=============================================================
#
. $HOME/.profile
echo `date` >> $HOME/server/log/crontab.log
echo 'run $HOME/server/scr/scannerPPctrl.pl stop' >> $HOME/server/log/crontab.log
$HOME/server/scr/scannerPPctrl.pl stop >> $HOME/server/log/crontab.log

#echo 'sleep half a minute'
sleep 30 >> $HOME/server/log/crontab.log

echo 'run $HOME/server/scr/scannerPPctrl.pl start' >> $HOME/server/log/crontab.log
$HOME/server/scr/scannerPPctrl.pl start >> $HOME/server/log/crontab.log
