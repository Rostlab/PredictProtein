#!/bin/sh
#
# =============================================================
#   
# restart the scanner (just in case)
#
# =============================================================
#
. /nfs/data5/users/$USER/.bashrc
echo `date` >> /nfs/data5/users/$USER/server/log/crontab.log
echo 'run /nfs/data5/users/$USER/server/scr/scannerPPctrl.pl start' >> /nfs/data5/users/$USER/server/log/crontab.log
/nfs/data5/users/$USER/server/scr/scannerPPctrl.pl start >> /nfs/data5/users/$USER/server/log/crontab.log



