#! /bin/sh
#
#=============================================================
# calls a perl program that checks changes on wwwPP home
#=============================================================
#

echo '       --------------------' >> /home/$USER/server/log/cronExe_wwwDocs_to_ftpPP.log
echo 'start: '`date` >> /home/$USER/server/log/cronExe_wwwDocs_to_ftpPP.log
echo 'run  : /home/$USER/server/scr/ut/wwwDocs_to_ftpPP.pl auto'  >> /home/$USER/server/log/cronExe_wwwDocs_to_ftpPP.log

/home/$USER/server/scr/ut/wwwDocs_to_ftpPP.pl auto

echo 'end  : '`date` >> /home/$USER/server/log/cronExe_wwwDocs_to_ftpPP.log
#=============================================================
