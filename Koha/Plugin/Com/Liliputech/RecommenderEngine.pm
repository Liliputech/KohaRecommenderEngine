package Koha::Plugin::Com::Liliputech::RecommenderEngine;

## It's good practive to use Modern::Perl
use Modern::Perl;
use Data::Dumper;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Members;
use C4::Auth;

## Here we set our plugin version
our $VERSION = 1.1;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Koha Recommender Plugin',
    author => 'Arthur O Suzuki',
    description => 'This plugin implements recommendations for each Bibliographic reference based on all other borrowers old issues',
    date_authored   => '2016-06-27',
    date_updated    => '2017-01-12',
    minimum_version => '3.16',
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

sub install() {
    my ( $self, $args ) = @_;
    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    # Removing Plugin JS from Syspref
    my $opacuserjs = C4::Context->preference('opacuserjs');
    $opacuserjs =~ s/\n\/\* JS for Koha Recommender Plugin.*End of JS for Koha Recommender Plugin \*\///gs;
    C4::Context->set_preference( 'opacuserjs', $opacuserjs );
    my $intranetuserjs = C4::Context->preference('intranetuserjs');
    $intranetuserjs =~ s/\n\/\* JS for Koha Recommender Plugin.*End of JS for Koha Recommender Plugin \*\///gs;
    C4::Context->set_preference( 'intranetuserjs', $intranetuserjs );

    # Remove configurations data and public report
    my $report_id = $self->retrieve_data('report_id');
    my $dbh = C4::Context->dbh;
    my $query = "delete from saved_sql where id=$report_id";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    $query = "delete from plugin_data where plugin_class like '%RecommenderEngine%'";
    $sth = $dbh->prepare($query);
    $sth->execute();
}

sub configure() {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        $template->param( opacenabled => $self->retrieve_data('opacenabled'), recordnumber => $self->retrieve_data('recordnumber'), interval => $self->retrieve_data('interval'), last_configured_by => $self->retrieve_data('last_configured_by'), );

        print $cgi->header(
                {
                -type     => 'text/html',
                -charset  => 'UTF-8',
                -encoding => "UTF-8"
                }
                );
        print $template->output();
    }

    else {
        my $opacenabled = $cgi->param('opacenabled');
        my $recordnumber = $cgi->param('recordnumber');
        my $interval = $cgi->param('interval');
        $self->store_data(
            {
                opacenabled => $opacenabled,
                recordnumber => $recordnumber,
                interval => $interval,
                last_configured_by => C4::Context->userenv->{'number'}
            }
        );
	$self->updateSQL();
        $self->updateJS();
        $self->go_home();
    }
    return 1;
}

sub updateJS() {
    my ( $self, $args ) = @_;

    my $intranetuserjs = C4::Context->preference('intranetuserjs');
    $intranetuserjs =~ s/\n\/\* JS for Koha Recommender Plugin.*End of JS for Koha Recommender Plugin \*\///gs;

    my $template = $self->get_template( { file => 'intranetuserjs.tt' } );
    $template->param( 'report_id' => $self->retrieve_data('report_id') );
    my $recommender_js = $template->output();

    $recommender_js = qq|\n/* JS for Koha Recommender Plugin 
   This JS was added automatically by installing the Recommender plugin
   Please do not modify */\n|
      . $recommender_js
      . q|/* End of JS for Koha Recommender Plugin */|;

    $intranetuserjs .= $recommender_js;
    C4::Context->set_preference( 'intranetuserjs', $intranetuserjs );

    my $opacuserjs = C4::Context->preference('opacuserjs');
    if($self->retrieve_data('opacenabled')) {
	## Insert or Update Plugin JS
    	$opacuserjs =~ s/\n\/\* JS for Koha Recommender Plugin.*End of JS for Koha Recommender Plugin \*\///gs;
	
    	my $template = $self->get_template( { file => 'opacuserjs.tt' } );
	$template->param( 'report_id' => $self->retrieve_data('report_id') );
    	my $recommender_js = $template->output();

    	$recommender_js = qq|\n/* JS for Koha Recommender Plugin 
   	This JS was added automatically by installing the Recommender plugin
   	Please do not modify */\n|
      	. $recommender_js
      	. q|/* End of JS for Koha Recommender Plugin */|;

    	$opacuserjs .= $recommender_js;
    }
    else {
    	## Removing Plugin JS from Syspref
    	$opacuserjs =~ s/\n\/\* JS for Koha Recommender Plugin.*End of JS for Koha Recommender Plugin \*\///gs;
    }
    C4::Context->set_preference( 'opacuserjs', $opacuserjs );
}

sub updateSQL() {
    my ( $self, $args ) = @_;

    ## Create ExtractValue query according to MARC format
    my $marcflavour = C4::Context->preference('marcflavour');
    my $marcdata;
    if ($marcflavour eq 'UNIMARC') {
        $marcdata = "ExtractValue(metadata,'//datafield[\@tag=\"200\"]/subfield[\@code=\"a\"]') title,
		ifnull(ExtractValue(metadata,'//datafield[\@tag=\"200\"]/subfield[\@code=\"d\"]'),\"\") subtitle,
		ifnull(ExtractValue(metadata,'//datafield[\@tag=\"200\"]/subfield[\@code=\"h\"]'),\"\") partnumber,
		ifnull(ExtractValue(metadata,'//datafield[\@tag=\"200\"]/subfield[\@code=\"f\"]'),\"\") author,";
    } elsif ($marcflavour eq 'MARC21') {
        $marcdata = "ExtractValue(metadata,'//datafield[\@tag=\"245\"]/subfield[\@code=\"a\"]') title,
		ifnull(ExtractValue(metadata,'//datafield[\@tag=\"245\"]/subfield[\@code=\"b\"]'),\"\") subtitle,
		ifnull(ExtractValue(metadata,'//datafield[\@tag=\"245\"]/subfield[\@code=\"n\"]'),\"\") partnumber,
		ifnull(ExtractValue(metadata,'//datafield[\@tag=\"245\"]/subfield[\@code=\"c\"]'),\"\") author,";
    }
    my $template = $self->get_template( { file => 'savedsql.tt' } );
    $template->param( 	'marcdata' => $marcdata,
			'interval' => $self->retrieve_data('interval'),
			'recordnumber' => $self->retrieve_data('recordnumber'),
			);
    my $recommender_sql = $template->output();
    my $dbh = C4::Context->dbh;
    my $query;
    my $report_id = $self->retrieve_data('report_id');
    if($report_id){
	$query = "UPDATE saved_sql SET savedsql=? WHERE id=?;";
	my $sth = $dbh->prepare($query);
	$sth->execute($recommender_sql,$report_id);
     }
    else
    {
	$query = "INSERT INTO saved_sql (savedsql,report_name,notes,cache_expiry,public) VALUES (?,'RecommendationEngine','RecommendationEngine - DO NOT REMOVE',0,1);";
    	my $sth = $dbh->prepare($query);
	$sth->execute($recommender_sql);
	$self->store_data( {'report_id' => $dbh->last_insert_id(undef,undef,undef,undef) });
    }
}

sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'report.tt' });

    print $cgi->header();
    print $template->output();
}
1;
