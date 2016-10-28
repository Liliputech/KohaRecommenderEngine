#!/usr/bin/perl

use Modern::Perl;

use FindBin;                 # locate this script
use lib "$FindBin::Bin/../../../../../";  # use the parent directory

use Koha::Plugin::Com::Liliputech::RecommenderEngine;

use CGI;

my $cgi = new CGI;

my $recommendations = Koha::Plugin::Com::Liliputech::RecommenderEngine->new({ cgi => $cgi });
$recommendations->report();
