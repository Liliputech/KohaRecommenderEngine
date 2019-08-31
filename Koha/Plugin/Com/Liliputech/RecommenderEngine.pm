use strict;
use warnings;
package Koha::Plugin::Com::Liliputech::RecommenderEngine;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Auth;

## Here we set our plugin version
our $VERSION = '1.2';

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Koha Recommender Plugin',
    author => 'Arthur Suzuki, Josef Moravec',
    description => 'This plugin implements recommendations for each Bibliographic reference based on all other borrowers old issues',
    date_authored   => '2016-06-27',
    date_updated    => '2019-08-24',
    minimum_version => '17.11.00.000',
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
    $self->store_data( { opacenabled => 1, recordnumber => 10, interval => 1 } );
    $self->updateSQL();
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

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
	print 'first template';
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        $template->param( opacenabled => $self->retrieve_data('opacenabled'), recordnumber => $self->retrieve_data('recordnumber'), interval => $self->retrieve_data('interval'), last_configured_by => $self->retrieve_data('last_configured_by'), );

	$self->output_html( $template->output() );
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
        $self->go_home();
    }
}

sub intranet_js {
    my ( $self , $args ) = @_;
    my $recommender_js = q|
<script>
/* JS for Koha Recommender Plugin 
This JS was added automatically by installing the Recommender plugin
Please do not modify */
$(document).ready(function() { if ($('body#catalog_detail').size() > 0 && $('div#bibliodetails').size() > 0) detailRecommendations(); } );

function detailRecommendations() {
	//Get the biblionumber from URL
	var biblionumber = location.search.split('biblionumber=')[1]		
        var tabMenu = "<li class='ui-state-default ui-corner-top' role='tab' tabindex='-1' aria-controls='recommendations' aria-labelledby='ui-id-7' aria-selected='false'><a href='#recommendations' class='ui-tabs-anchor' role='presentation' tabindex='-1' id='ui-id-7'>Similar Items</a></li>";

	var tabContent = "\
	       <div id='recommendations'>\
	       <table id='recommendationTable' style='width:100%'>\
	       <thead>\
	       <tr>\
	       <th>Biblionumber</th>\
	       <th>Title</th>\
	       <th>Subtitle</th>\
	       <th>Part</th>\
	       <th>Author</th>\
	       <th>Score</th>\
	       </tr>\
	       </thead>\
	       </table>\
	       </div>";

	var tabs = $('div#bibliodetails').tabs();
	var ul = tabs.find("ul");
	$( tabMenu ).appendTo( ul );
	$( tabContent ).appendTo(tabs);
	tabs.tabs( "refresh" );

	$('#recommendationTable').DataTable( {
		ajax: {
			url : window.location.origin+"/cgi-bin/koha/svc/report?id=| . $self->retrieve_data('report_id') . q|&sql_params="+biblionumber+"&sql_params="+biblionumber,
			dataSrc : ""
		},
		order: [5,"desc"],
		lengthChange: false,			
		paging: false,
		searching: false,
		info: false,
		columnDefs:[{targets:0,render: function ( data, type, full, meta ) {return "<a href='detail.pl?biblionumber="+data+"'>"+data+"</a>";}}]
	} );
}
/* End of JS for Koha Recommender Plugin */
</script>|;

    return $recommender_js;
}

sub opac_js {
    my ( $self, $args ) = @_;
    my $recommender_js = "";
    if($self->retrieve_data('opacenabled')) {
    	$recommender_js = q|
<script>
/*      JS for Koha Recommender Plugin 
   	This JS was added automatically by installing the Recommender plugin
   	Please do not modify */

$(document).ready(function() { if ($('body#opac-detail').size() > 0 && $('div#bibliodescriptions').size() > 0) detailRecommendations(); } );

function detailRecommendations() {
	//Get the biblionumber from URL
	var biblionumber = location.search.split('biblionumber=')[1]		
        var tabMenu = "<li class='ui-state-default ui-corner-top' role='tab' tabindex='-1' aria-controls='recommendations' aria-labelledby='ui-id-7' aria-selected='false'><a href='#recommendations' class='ui-tabs-anchor' role='presentation' tabindex='-1' id='ui-id-7'>Similar Items</a></li>";

	var tabContent = "\
	       <div id='recommendations' aria-labelledby='ui-id-7' class='ui-tabs-panel ui-widget-content ui-corner-bottom' role='tabpanel' style='display: none;' aria-expanded='false' aria-hidden='true'>\
	       <table id='recommendationTable' class='table table-bordered table-striped dataTable no-footer' width='100%' cellspacing='0'>\
	       <thead>\
	       <tr>\
	       <th>Biblionumber</th>\
	       <th>Title</th>\
	       <th>Subtitle</th>\
	       <th>Part</th>\
	       <th>Author</th>\
	       <th>Score</th>\
	       </tr>\
	       </thead>\
	       </table>\
	       </div>";

	var tabs = $('div#bibliodescriptions').tabs();
	var ul = tabs.find("ul");
	$( tabMenu ).appendTo( ul );
	$( tabContent ).appendTo(tabs);
	tabs.tabs( "refresh" );

	$('#recommendationTable').DataTable( {
		ajax: {
			url: window.location.origin+"/cgi-bin/koha/svc/report?id=| . $self->retrieve_data('report_id') . q|&sql_params="+biblionumber+"&sql_params="+biblionumber,
			dataSrc: ""
		},
		order: [5,"desc"],
		lengthChange: false,			
		paging: false,
		info: false,
		searching: false,
		columnDefs:[{targets:0,render: function ( data, type, full, meta ) {return "<a href='opac-detail.pl?biblionumber="+data+"'>"+data+"</a>";}}]
	} );
}
</script>
|;
    }
    return $recommender_js;
}

sub updateSQL() {
    my ( $self, $args ) = @_;

    ## Create ExtractValue query according to MARC format
    my $marcflavour = C4::Context->preference('marcflavour');
    my $marcdata;
    if ($marcflavour eq 'UNIMARC') {
        $marcdata = "biblio.title,
		coalesce(ExtractValue(metadata,'//datafield[\@tag=\"200\"]/subfield[\@code=\"d\"]'),\"\") subtitle,
		coalesce(ExtractValue(metadata,'//datafield[\@tag=\"200\"]/subfield[\@code=\"h\"]'),\"\") partnumber,
		biblio.author,";
    } elsif ($marcflavour eq 'MARC21') {
        $marcdata = "biblio.title,
		coalesce(ExtractValue(metadata,'//datafield[\@tag=\"245\"]/subfield[\@code=\"b\"]'),\"\") subtitle,
		coalesce(ExtractValue(metadata,'//datafield[\@tag=\"245\"]/subfield[\@code=\"n\"]'),\"\") partnumber,
		biblio.author,";
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

    $self->output_html( $template->output() );
}
1;
