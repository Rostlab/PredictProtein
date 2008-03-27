#!/usr/bin/perl
use SOAP::Lite;#+trace => qw(debug);
use SOAP::MIME;
use MIME::Entity;

my $ent = build MIME::Entity
  Type        => "image/gif",
  Encoding    => "base64",
  Path        => "ps.gif",
  Filename    => "saveme.gif",
  Disposition => "attachment";


$HOST   = "http://sequoia/cgi-bin/acceptAttach.cgi";
$NS     = "http://sequoia/SOAP_MIME_Test";

my @parts = ($ent);

my $som = SOAP::Lite
  ->readable(1)
  ->uri($NS)
  ->parts(@parts)
  ->proxy($HOST)
  ->echo(SOAP::Data->name("foo" => "bar"));
die;
#print $som->result,"\n";
print "BEFORE\n"x10;
foreach my $part (${$som->parts}) {
  print "TEST:\t $part->stringify";
}
