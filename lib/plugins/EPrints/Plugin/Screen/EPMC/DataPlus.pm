package EPrints::Plugin::Screen::EPMC::DataPlus;

@ISA = qw( EPrints::Plugin::Screen::EPMC );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{actions} = [qw( enable disable )];
	$self->{disable} = 0; # always enabled, even in lib/plugins

	$self->{package_name} = "dataplus";

	return $self;
}

sub action_enable
{
	my( $self, $skip_reload ) = @_;

	$self->SUPER::action_enable( 1 );


my $dataset_stage = '<?xml version="1.0"?>
<workflow xmlns="http://eprints.org/ep3/workflow" xmlns:epc="http://eprints.org/ep3/control">
	<stage name="dataset">
		<component><field ref="title" required="yes" input_lookup_url="{$config{rel_cgipath}}/users/lookup/title_duplicates" input_lookup_params="id={eprintid}&amp;dataset=eprint&amp;field=title" /></component>
		<component><field ref="abstract" required="yes"/></component>
		<component><field ref="keywords" required="yes"/></component>
		<component><field ref="divisions" required="yes"/></component>

		<component collapse="yes"><field ref="alt_title"/></component>
		<component><field ref="creators" required="yes" input_lookup_url="{$config{rel_cgipath}}/users/lookup/name" /></component>
		<component collapse="yes"><field ref="corp_creators"/></component>
		
		<epc:if test="$STAFF_ONLY = \'TRUE\'">
			<component show_help="always"><field ref="doi" required="yes"/></component>
		</epc:if>
		<component><field ref="data_type" required="yes" input_lookup_url="{$config{perl_url}}/users/lookup/simple_file" input_lookup_params="file=data_type" /></component>

		<component><field ref="contributors" collapse="yes" /></component>
		<component type="Field::Multi">
		    <title>Research Funders</title>
		    <field ref="funders" required="yes" input_lookup_url="{$config{perl_url}}/users/lookup/simple_file" input_lookup_params="file=funders" />
		    <field ref="funders_other_text" />
		</component>
		<component><field ref="grant" collapse="yes" /></component>
		<component collapse="yes"><field ref="projects"/></component>
		<component type="Field::Multi">
		    <title>Time period</title>
		    <help>Help text here</help>
		    <field ref="collection_date" required="yes" />
		    <field ref="temporal_cover" required="yes" />
		</component>
		<component collapse="yes"><field ref="geographic_cover"/></component>
		<component type="Field::Multi" show_help="always" collapse="yes">
		    <title>Geographic location</title>
		    <help>Enter if applicable the Longitude and Latitude values of a theoretical geographic bounding rectangle that would cover the region in which your data were collected. You can use</help>
		    <field ref="bounding_box" />
		</component>
		<component collapse="yes"><field ref="collection_method"/></component>
		<component collapse="yes"><field ref="legal_ethical"/></component>
		<component collapse="yes"><field ref="provenance"/></component>
		<component><field ref="language" required="yes"/></component>
		<component collapse="yes"><field ref="note"/></component>
		<component collaspe="yes"><field ref="related_resources"/></component>
		<component type="Field::Multi">
		    <title> Original Publication Details</title>
		    <field ref="publisher"/>
		    <field ref="ispublished" required="yes"/>
		    <field ref="official_url"/>
		    <field ref="date" />
		    <field ref="date_type"/>
		</component>
		<component><field ref="copyright_holders" required="yes" /></component>


		<component><field ref="contact_email" required="yes"/></component>
		<component collapse="yes"><field ref="suggestions"/></component>
	</stage>
</workflow>';

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $filename = $repo->config( "config_path" )."/workflows/eprint/default.xml";

	EPrints::XML::add_to_xml( $filename, $dataset_stage, $self->{package_name} );

	my $dom = $xml->parse_file( $filename );

	my @flow = $dom->getElementsByTagName("flow");
	my $flow_elements = $xml->create_document_fragment();

	foreach my $element ($flow[0]->childNodes()){
		$element->unbindNode();
		$flow_elements->appendChild($element);
	}

	my $choose_statement = $xml->create_element("epc:choose", required_by=>"dataplus", id=>"dataplus_choose");
	$flow[0]->appendChild($choose_statement);

	my $when_statement = $xml->create_element("epc:when", test=>"type = 'dataset'");
	$choose_statement->appendChild($when_statement);
	$when_statement->appendChild($xml->create_element("stage", ref=>"files"));
	$when_statement->appendChild($xml->create_element("stage", ref=>"dataset"));
	$when_statement->appendChild($xml->create_element("stage", ref=>"subjects"));

	my $otherwise_statement = $xml->create_element("epc:otherwise");
	$choose_statement->appendChild($otherwise_statement);
	$otherwise_statement->appendChild($flow_elements);

	open( FILE, ">", $filename );

	print FILE $xml->to_string($dom, indent=>1);

	close( FILE );

	my $namedset = EPrints::NamedSet->new( "content",
		repository => $repo
	);
 
	$namedset->add_option( "data", $self->{package_name} );
	$namedset->add_option( "documentation", $self->{package_name} );
	$namedset->add_option( "readme", $self->{package_name} );
	$namedset->add_option( "metadata", $self->{package_name} );
	$namedset->add_option( "full_archive", $self->{package_name} );

	$namedset = EPrints::NamedSet->new( "licenses",
		repository => $repo
	);
 
	$namedset->add_option( "odc_by", $self->{package_name} );
	$namedset->add_option( "odc_odbl", $self->{package_name} );
	$namedset->add_option( "odc_dbcl", $self->{package_name} );

	$self->reload_config if !$skip_reload;
}

sub action_disable
{
	my( $self, $skip_reload ) = @_;

	$self->SUPER::action_disable( 1 );

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $filename = $repo->config( "config_path" )."/workflows/eprint/default.xml";

	my $dom = $xml->parse_file( $filename );

	my $choose;
	my @choices = $dom->getElementsByTagName("choose");
	foreach my $element (@choices)
	{
		if($element->hasAttribute("required_by") && $element->getAttribute("required_by") eq $self->{package_name})
		{
			$choose = $element;
			last;
		}
	}

	if(defined $choose) {
		my $choose_parent = $choose->parentNode; #probably the flow element but err on the side of caution
		my @otherwise = $choose->getElementsByTagName("otherwise");
		foreach my $element ($otherwise[0]->childNodes()){
			$element->unbindNode();
			$choose_parent->appendChild($element);
		}

		open( FILE, ">", $filename );

		print FILE $xml->to_string($dom, indent=>1);

		close( FILE );
	}

	EPrints::XML::remove_package_from_xml( $filename, $self->{package_name} );


	$dom = $xml->parse_file( $filename );

	open( FILE, ">", $filename );

	print FILE $xml->to_string($dom, indent=>1);

	close( FILE );

	my $namedset = EPrints::NamedSet->new( "content",
		repository => $repo
	);
 
	$namedset->remove_option( "data", $self->{package_name} );
	$namedset->remove_option( "documentation", $self->{package_name} );
	$namedset->remove_option( "readme", $self->{package_name} );
	$namedset->remove_option( "metadata", $self->{package_name} );
	$namedset->remove_option( "full_archive", $self->{package_name} );

	$namedset = EPrints::NamedSet->new( "licenses",
		repository => $repo
	);
 
	$namedset->remove_option( "odc_by", $self->{package_name} );
	$namedset->remove_option( "odc_odbl", $self->{package_name} );
	$namedset->remove_option( "odc_dbcl", $self->{package_name} );

	$self->reload_config if !$skip_reload;
}

1;
