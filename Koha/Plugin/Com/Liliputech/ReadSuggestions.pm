package Koha::Plugin::Com::Liliputech::ReadSuggestions;

## It's good practive to use Modern::Perl
use Modern::Perl;
use Data::Dumper;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Branch;
use C4::Members;
use C4::Auth;

## Here we set our plugin version
our $VERSION = 1.00;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Read Suggestions Plugin',
    author => 'Arthur O Suzuki',
    description => 'This plugin implements read suggestions for each Bibliographic reference based on all other borrowers old issues',
    date_authored   => '2016-06-27',
    date_updated    => '2016-09-14',
    minimum_version => '3.18.13.000',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( scalar $cgi->param('biblionumber') ) {
        $self->report_step1();
    }
    else {
        $self->report_step2();
    }
}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'report-step1.tt' });

    print $cgi->header();
    print $template->output();
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;
 
    ##Biblionumber to query
    my $biblionumber = scalar $cgi->param('biblionumber');

	##Eventually set a limit to the number of results to display
	my $limit = "";
	my $recordnumber = scalar $cgi->param('recordnumber');
	if($recordnumber) {
		$limit = "limit $recordnumber";
	}
    
	##Choose how to output data (set to html if undefined)
	my $template;
	my $output = scalar $cgi->param('output');
	if ($output eq 'csv') {
		$template = $self->get_template({ file => 'report-step2-csv.tt' });
		print "Content-type: text/plain\n\n";
	} else {
        $template = $self->get_template({ file => 'report-step2.tt' });
	    print "Content-type: text/html\n\n";
    }

	## First fetch value if UNIMARC or MARC21
    my $query = "select value from systempreferences where variable='marcflavour'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $marcflavour = ${$dbh->selectcol_arrayref($query)}[0];
    
    ## Create ExtractValue query according to MARC format
    my $marcfilter;
	if ($marcflavour eq 'UNIMARC') {
        $marcfilter = "ExtractValue(marcxml,'//datafield[\@tag=\"200\"]/subfield[\@code=\"a\"]')";
	} elsif ($marcflavour eq 'MARC21') {
        $marcfilter = "ExtractValue(marcxml,'//datafield[\@tag=\"245\"]/subfield[\@code=\"a\"]')";
    }
    
    ## Wow such a big shit...
    ##Query ok for UNIMARC Format (200a), this has to be changed in configuration if another cataloging format is to be used.

    $query = "
	select suggestions.biblioitemnumber as biblionumber, $marcfilter AS title, totalPrets as nissues from biblioitems
	inner join (
	select distinct biblioitemnumber, sum(pretExemplaire) totalPrets from items inner join (
		select distinct itemnumber, count(itemnumber) pretExemplaire from old_issues
		where
		itemnumber is not null and borrowernumber is not null and
		borrowernumber in (
			select distinct borrowernumber from old_issues
			where borrowernumber is not null and itemnumber IN (
				select itemnumber from items where biblioitemnumber = '$biblionumber'
			)
		) group by itemnumber
	) exemplaires on items.itemnumber=exemplaires.itemnumber
	where biblioitemnumber <> '$biblionumber'
    and items.statisticvalue in (select distinct statisticvalue from items where biblioitemnumber = '$biblionumber')
	group by biblioitemnumber
	order by totalPrets desc
	$limit) suggestions
	on biblioitems.biblioitemnumber=suggestions.biblioitemnumber";

    $sth = $dbh->prepare($query);
    $sth->execute();

    my @results;
    while ( my $row = $sth->fetchrow_hashref() ) {
        push( @results, $row );
    }
 
    $template->param(
		biblionumber => $biblionumber,
        results => \@results
    );

    print $template->output();
}
1;
