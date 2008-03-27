#!/usr/local/bin/perl -w

use strict;
use CGI qw(:standard);
require HTTP::Request;
require HTTP::Response;
require LWP::UserAgent;

my $query = new CGI;
my %params = $query->Vars;

print $query->header;

my ($key,$value);
my $content = "";
foreach $key ( keys %params ) {
    $value = $params{$key};
    $content .= "$key=$value&";
}
$content =~ s/\&$//;
   

my $cubicCGI = "http://cubic.bioc.columbia.edu/cgi-bin/pp/submit";
my $method = 'POST';
my $type = 'multipart/form-data';

my $request = new HTTP::Request($method, $cubicCGI); 
$request->header($type); 
$request->content($content); 
                         
my $ua = new LWP::UserAgent;
my $response = $ua->request($request);
if ($response->is_success) {
    print $response->content;
} else {
    print $response->error_as_HTML;
}

			#log file
my $logFile = "/home/$ENV{USER}/server/log/cgi.log"; # HARD CODED
open (LOG, ">>$logFile" ) or warn "cannot append to $logFile:$!";
print LOG "Referer: ",$query->referer."\n";
print LOG $query->query_string."\n\n";
close LOG;


exit;





