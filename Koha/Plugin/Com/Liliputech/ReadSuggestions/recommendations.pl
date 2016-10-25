#!/usr/bin/perl

use Modern::Perl;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../../../../../";  # use the parent directory

use Koha::Plugin::Com::Liliputech::ReadSuggestions;

use CGI;

my $cgi = new CGI;

my $recommendations = Koha::Plugin::Com::Liliputech::ReadSuggestions->new({ cgi => $cgi });
$recommendations->report();
