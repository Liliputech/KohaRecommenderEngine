package Koha::Plugin::Com::Liliputech::RecommenderEngine::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

sub list {
	my $c = shift->openapi->valid_input or return;
	my @recommendations = map {
		{
			biblionumber => "test",
			title => "potter",
		}
		} @recommendations;
	return $c->render(status => 200, openapi => \@recommendations);
}

1;
