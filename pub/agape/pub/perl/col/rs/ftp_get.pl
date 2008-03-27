ftp.pl is very easy to use. I think it would be difficult to make it
easier without losing some generality. The following is a sub from my
ftp-getting .forward file. It is invoked as &ftpget($site, $dir, @files).
It logs progress in @result, and uucp's the resulting files to
$REMOTEHOST. Was it really that difficult ?

So ... get down !!

sub ftpget {
        local(@result);
        local($site) = shift;
        local($dir) = shift;
        &dirmake($LOCALPUBLIC);
        chdir($LOCALPUBLIC) ||
                push(@errors, "Unable to cd to $LOCALPUBLIC\n");
        FTPGET: {
            push(@ftpcommands, "ftpget $site: $dir/ " . join(' ', @_));
            push(@result, "ftp> open $site");
            &ftp'open($site, 21, 30, 3)             || next FTPGET;
            push(@result, $ftp'response);
            push(@result, "ftp> login $LOGIN");
            &ftp'login($LOGIN, $PASSWORD)           || next FTPGET;
            push(@result, $ftp'response);
            push(@result, "ftp> binary");
            &ftp'type("I")                          || next FTPGET;
            push(@result, $ftp'response);
            push(@result, "ftp> cd $dir");
            &ftp'cwd($dir)                          || next FTPGET;
            push(@result, $ftp'response);
            foreach (@_) {
                push(@result, "ftp> get $_");
                &ftp'get($_, $_)                    || next FTPGET;
                push(@result, $ftp'response);
                chmod(0644, "$_");      
                $REMOTEHOST && `uucp -r $_ $REMOTEHOST!~/$_`;
                $?                                  && next FTPGET;
                push(@result, "$_ queued for sending to $REMOTEHOST");
            }
            $ftp'response = 'ftpget successful';
        }
        push(@result, $ftp'response);
        push(@result, "ftp> quit");
        &ftp'quit;
        push(@result, $ftp'response);
        push(@ftpresults, join("\n", @result));
        chdir($HOME);
}


