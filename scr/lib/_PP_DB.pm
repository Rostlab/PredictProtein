#!/usr/bin/perl -w

use strict;
{
#    use lib '/data2/ppuser/meta/lib/perl5/site_perl/5.6.1/i386-linux';
#    use lib '/data2/ppuser/meta/lib/perl5/site_perl/5.6.1';
    package _PP_DB;
	use Carp qw| cluck :DEFAULT |;
    use DBI;

    sub new{
	my ($self, $host , $db_name, $user, $pass ) = @_;

	my $db_ref = $self->open ($host , $db_name, $user, $pass);
	bless $db_ref, $_[0];
	return $db_ref;
    }

    sub getServerData{
	my ($self, $svc_id, $dbg) = @_;
	my $str_sql = "select id, cgi, url, webresponse, name from services where ID = '$svc_id'";

#	_META_PP->_msg ("SQL: $str_sql") if ($dbg);
#	_META_PP->_msg ("SQL: $str_sql");
	my $ref_data =  $self->select($str_sql);
	return $ref_data->[0];
    }

    sub getServerByName{
        my ($self, $svc_name, $dbg) = @_;
        my $str_sql = "select id, cgi, url, webresponse, name from services where NAME = '$svc_name'";
#        _META_PP->_msg ("SQL: $str_sql") if ($dbg); 
        my $ref_data =  $self->select($str_sql);
        return $ref_data->[0];
    }



    sub getServerParams{
	my ($self, $svc_id, $dbg) =@_;

	my %param_data =();
	# Get a list of params for this service
	my $str_sql = "select param_name, param_val from params where svc_id = $svc_id";
	my $ref_data =  $self->select($str_sql);
	

	# Construct the parmaeter array
	foreach my $ref(@$ref_data){
	    my $name = $ref->{'param_name'};
	    my $val = $ref->{'param_val'};
	    $param_data{"$name"} = $val;
	}

	# construct the query string
	return \%param_data;
    }			       

    sub setJobState{
	my ($self, $job_id, $state, $dbg) = @_;
	my $sql = "update requests set STATE=$state WHERE id = $job_id";
#	_META_PP->_msg ("SQL: $sql");# if ($dbg); 
	my $result = $self->execQuery($sql);
	return $result;
    }


    sub setBatchState{
	my ($self, $batch_id, $state, $dbg) = @_;
	my $sql = "update batches set STATE=$state WHERE id = $batch_id ";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 

	my $result = $self->execQuery($sql);
	return $result;
    }

    sub setBatchStartTime{
	my ($self, $id, $dbg) =@_;
	my $sql = "UPDATE batches SET STARTTIME=NOW() where id=$id";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $result = $self->execQuery($sql);
	return $result;
    }

    sub setBatchMD5ID{
	my ($self, $batch_id, $md5id, $dbg) = @_;
	my $sql = "update batches set MD5ID='".$md5id."' WHERE id = $batch_id ";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $result = $self->execQuery($sql);
	return $result;

    }


    sub setJobStartTime{
	my ($self, $id, $dbg) =@_;
	my $sql = "UPDATE requests SET TIMEMODIFIED=NOW() where id=$id";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $result = $self->execQuery($sql);
	return $result;
    }


    sub setJobModTime{
	my ($self, $id, $dbg) =@_;
	my $sql = "UPDATE jobs SET MODIFIEDTIME=NOW() where id=$id";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $result = $self->execQuery($sql);
	return $result;
    }


    sub setJobAttempts{
	my ($self, $id, $attempts, $dbg) =@_;
	my $sql = "UPDATE jobs SET ATTEMPTS=$attempts where id=$id";
	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $result = $self->execQuery($sql);
	return $result;
    }

#    sub getNextBatchJob{
#	my ($self, $dbg) = @_;
#	my $sql = "SELECT * FROM batches WHERE id = (select min(id) from batches where STATE=0)";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
#	my $ref_result = $self->select($sql);
#	return $ref_result->[0];
#    }


   sub getNextJob{
	my ($self, $state,$dbg) = @_;
#	my $sql = "SELECT * FROM batches WHERE id = (select min(id) from batches where  STATE < $max_state)";
	my $sql = "select * from requests where id = (SELECT min(ID) FROM requests WHERE STATE =$state)";
#	print $sql,"\n";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $ref_result = $self->select($sql);
	return $ref_result;
    }


    sub getBatchJobs{
	my ($self, $batch_id, $dbg) = @_;
	my $sql = "SELECT * FROM jobs WHERE BATCH_ID = $batch_id";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $ref_result = $self->select($sql);
	return $ref_result;
    }


    sub getJobsForBatch{
	my ($self, $batch_id, $dbg) = @_;
	my $sql = "SELECT ID, SVC_ID FROM jobs WHERE BATCH_ID = $batch_id and STATE=0";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $ref_result = $self->select($sql);
	return $ref_result;
    }

    sub getJobs{
	my ($self, $batch_id, $dbg) = @_;
	my $sql = "SELECT ID,SVC_ID, RESULT_ID, STARTTIME, MODIFIEDTIME, ATTEMPTS FROM jobs WHERE ID = $batch_id";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $ref_result = $self->select($sql);
	return $ref_result;
    }


    sub setResults{
	my ($self, $job_id, $contents, $req_name, $dbid, $dbg) =@_;
	my ($result, $msg);
	my $dbh = $self->{'dbh'};
	if( !$dbid) { confess("no $dbid"); }

	$dbh->do('lock tables results write, results_content write') || confess( $dbh->errstr );

	# Do we have this `REQ_ID` already?
	my $res_id = undef;
	{
		my $recs = $dbh->selectall_arrayref('select `ID` from results where `REQ_ID` = ?', undef, $dbid ) || confess( $dbh->errstr );
		if( @$recs )
		{
			$res_id = $recs->[0]->[0];
			warn "found result id ($res_id) for this REQ_ID ($dbid), will do update";
		}
		
	}

	my $sql  = "INSERT INTO  results (NAME,  TIMECREATED, REQ_NAME, REQ_ID ) VALUES ('$job_id',NOW(), '$req_name', $dbid) ON DUPLICATE KEY UPDATE NAME = values(NAME), TIMECREATED = values(TIMECREATED)";
	my $sql2 = "INSERT INTO  results_content (res_id, CONTENT) VALUES (?,COMPRESS(?)) ON DUPLICATE KEY UPDATE CONTENT = values(CONTENT)";
	
	eval{ # Start TX
	    my $sth  = $self->{'dbh'}->prepare($sql);
		warn $sql;
	    my $rv = $sth->execute() || confess( $dbh->errstr ); # "execute" returns the number of rows affected: 1 for an insert, 2 for an update, 0 for no change

		if( $rv == 1 && $res_id ) { confess("the impossible has just happened: inserted a record with a duplicate REQ_ID: $dbid"); };
		if( $rv == 2 && !$res_id ) { confess("the impossible has just happened: updated a record with no results.id (REQ_ID = $dbid)"); };

		if( $rv == 1 )
		{
			$res_id = $dbh->selectrow_arrayref("select last_insert_id()") || confess( $dbh->errstr );
			$res_id = $res_id->[0];
		}

	    my $sth2 = $self->{'dbh'}->prepare($sql2);
	    $sth2->execute( $res_id,$contents );
	    $result = $res_id;
	    $msg = "updated results\n";
	};
	# if any errors ---> rollback
	if ($@)	{
		warn;
	    $msg =  "Couldn't execute query '$sql': $DBI::errstr\n";
	    $self->{'dbh'}->rollback();
		$dbh->do('unlock tables') || confess( $dbh->errstr );
	    return (undef,$msg); 
	}
# 	warn ($result,$msg);
	$dbh->do('unlock tables') || confess( $dbh->errstr );
	return ($result,$msg);
    }


    sub setXMLResults{
	my ($self,$dbid, $contents, $errConv,  $dbg, $__p ) =@_;
	# $__p = { XMLLINT_ERRNO => str }
	my $result;
	my $sql;

	eval{ # Start TX
	    $sql = "INSERT INTO  XMLRESULTS (REQUESTID, XML_CONTENT,UCONV_ERR, XMLLINT_ERRNO ) VALUES ($dbid, COMPRESS(?), ".$self->{'dbh'}->quote($errConv).
			", ".$self->{'dbh'}->quote($__p->{XMLLINT_ERRNO}).") ON DUPLICATE KEY UPDATE XML_CONTENT = values(XML_CONTENT), UCONV_ERR = values(UCONV_ERR), XMLLINT_ERRNO = values(XMLLINT_ERRNO)";
	    $self->{'dbh'}->do($sql,undef,$contents) || die ( $DBI::errstr);
	    $result .= "updated results\n";

            if( $dbg ) { warn( qq|--- DBI::do: "$sql"| ); }
	};
         # if any errors ---> rollback
	if ($@)	{
	    my $msg =  "Couldn't execute query '$sql': $DBI::errstr\n";
	    $self->{'dbh'}->rollback();
	    return (undef,$msg); 
	}
	return $result;
    }


    sub getBatchResults{
	my ($self, $batch_id, $dbg) =@_;
	my $sql = "SELECT s.NAME,r.CONTENT, j.STATE, j.ATTEMPTS FROM services s, jobs j LEFT JOIN results r ON r.id = j.result_id 
                   WHERE (s.id=j.svc_id AND j.batch_id=$batch_id)";
#	my $sql ="SELECT s.NAME,r.CONTENT, j.STATE, j.ATTEMPTS FROM results r, jobs j, services s WHERE (s.id=j.svc_id and r.id = j.result_id AND j.batch_id=$batch_id)";
#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $ref_result = $self->select($sql);
	return $ref_result; 
    }				


    
    sub getBatchResultsByInput{
	my ($self,  $serviceID, $proteinName, $sequence, $dbg) =@_;

	my $sql = "SELECT s.NAME, r.CONTENT, j.STATE, j.ATTEMPTS FROM services s, jobs j LEFT JOIN results r ON r.id = j.result_id ";
	$sql .= "WHERE (s.id = j.svc_id AND j.batch_id = (SELECT b.id FROM batches b, jobs j ";
	$sql .= "WHERE b.input = '".$sequence."' AND b.job_name = '".$proteinName."' AND b.id = j.batch_id AND j.svc_id =$serviceID))";

#	_META_PP->_msg ("SQL: $sql") if ($dbg); 
	my $ref_result = $self->select($sql);

	return $ref_result->[0]; 
    }		


    sub open{
	my ($self, $host , $db_name, $user, $pass) = @_;

#	my $dsn = "dbi:mysql:$db_name;$host";
	my $dsn = "dbi:mysqlPP:database=$db_name;host=$host";
	my $dbh = DBI->connect( $dsn, $user, $pass ) || return undef;
	my $drh = DBI->install_driver( "mysqlPP" ) || return undef;

	my $hash_ref = {
	    dsn => $dsn,	 
	    dbh => $dbh,
	    drh => $drh		
	    };			 
	return $hash_ref;
    }
    

    sub execQuery{
	my ($self, $sql) = @_;
	# Now retrieve data from the table.
#	if (!$self->{'dbh'}){
#	    $self->open('bonsai.bioc.columbia.edu','PREDICTPROTEIN','phd','Pr3d8ct');
#	}
	my  $sth = $self->{'dbh'}->prepare("$sql");

	$sth->execute() || die "Couldn't execute query '$sql': $DBI::errstr\n"; 
	return 1;
    }

    sub select{
	my ($self, $sql) = @_;
	# Now retrieve data from the table.

#	if (!$self->{'dbh'}){
#	    $self->open('bonsai.bioc.columbia.edu','PREDICTPROTEIN','phd','Pr3d8ct');
#	}
	
	my  $sth = $self->{'dbh'}->prepare("$sql");

	$sth->execute() || warn "Couldn't execute query '$sql': $DBI::errstr\n"; 

	my $numrows=0;
	my @data;

	eval { 
	    while (my $ref = $sth->fetchrow_hashref()){
		push @data, $ref;
		$numrows++;
	    }
	}; warn $@ if $@;
#	print "_PP_DB.pm Line 262\n";
	$sth->finish();
	return undef if ($numrows==0);
	return \@data;
    }


    sub close{
	my $self = $_[0];
	$self->{'dbh'}->disconnect();
    }

    sub msg{
	my $s = shift;
	print ($s);
	print "\n";
	
    }

    sub set_tranx{   
	my $self =$_[0];		      
#	$self->{'dbh'}->{AutoCommit} = 0; # enable transactions, if possible
	$self->{'dbh'}->{RaiseError} = 1;
    }

    sub commit_tranx{
	my $self =$_[0];		     
	$self->{'dbh'}->commit;	# commit the changes if we get this far
    }

    sub rollback_tranx{
	my $self =$_[0];		      
	eval { $self->{'dbh'}->rollback };
    }



   ########## Genetegrate META #######################################################

    sub setServiceJob{
        my ($self, $batch_id,$service_id, $dbg) =@_;
        my $id;
        my $sql = "INSERT INTO jobs (BATCH_ID, SVC_ID) VALUES ($batch_id,$service_id)";
        eval{ # Start TX
#            _META_PP->_msg ("SQL: $sql") if ($dbg);
            $self->execQuery($sql);
            $id = $self->{'dbh'}->{'mysql_insertid'};
            # got this far means no errors
            $self->{'dbh'}->commit();
        };
        # if any errors ---> rollback
        if ($@) {
            my $msg =  "Couldn't execute query '$sql': $DBI::errstr\n";
            $self->{'dbh'}->rollback();
            return (undef,$msg);
        }
        return $id;
    }



    sub setBatchJob{
        my ($self, $email,$prot_name, $sequence, $dbg) =@_;
        my $id;
        my $sql = "INSERT INTO batches (USER_EMAIL, JOB_NAME, INPUT) VALUES (\'$email\',\'$prot_name\',\'$sequence\')";
        eval{ # Start TX
#            _META_PP->_msg ("SQL: $sql") if ($dbg);
            $self->execQuery($sql);
            $id = $self->{'dbh'}->{'mysql_insertid'};
            # got this far means no errors
            $self->{'dbh'}->commit();
        };
        # if any errors ---> rollback
        if ($@){
            my $msg =  "Couldn't execute query '$sql': $DBI::errstr\n";
            $self->{'dbh'}->rollback();
            return (undef,$msg);
        }
#       $id=$dbg;
        return $id;
    }

    ###################################################################################





}				
1; 

__END__

my %User_Preferences;







				# 
print "Content-type:text/html\n\n";

my $db_host = $User_Preferences{"DB_HOST"};
my $db_user = $User_Preferences{"DB_USER"};
my $db_pass = $User_Preferences{"DB_PASS"};
my $db_name = $User_Preferences{"DB_INSTANCE"};


# 

# 

# 
$sth = $dbh->prepare("SELECT * FROM services");
$sth->execute;
$numRows = $sth->rows;
$numFields = $sth->{'NUM_OF_FIELDS'};
print "$numFields\n"x10;
#while ($row_ref = $sth->fetchrow_hashref())
#{
#    print "User <b>$row_ref->{User}</b> has privileges on <b>$row_ref->{Host}</b>.<br>";
#}


exit;




#use DBI;
#$db_handle = DBI->connect("dbi:mysql:database=$db_name;host=$db_host;user=$db_user;password=$db_pass")
#    or die "Couldn't connect to database: $DBI::errstr\n";
#$sql = "SELECT * FROM services";
#$statement = $db_handle->prepare($sql)
#    or die "Couldn't prepare query '$sql': $DBI::errstr\n";
#$statement->execute()
#    or die "Couldn't execute query '$sql': $DBI::errstr\n";
#$db_handle->disconnect();
# vim:ai:ts=4:
