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
		<component type="Upload" show_help="always"/>
		<component type="Documents">
			<field ref="content"/>
			<field ref="format"/>
			<field ref="formatdesc"/>
			<field ref="security"/>
			<field ref="license"/>
			<field ref="date_embargo"/>
			<!--  <field ref="relation" /> -->
			<!--  <field ref="language" /> -->
		</component>
		<component type="Field::Multi">
			<title>Dataset Information</title>
			<field ref="title" required="yes" input_lookup_url="{$config{rel_cgipath}}/users/lookup/title_duplicates" input_lookup_params="id={eprintid}&amp;dataset=eprint&amp;field=title"/>
			<field ref="data_type" required="yes"/>
			<field ref="abstract"/>
			<field ref="creators" input_lookup_url="{$config{rel_cgipath}}/users/lookup/name"/>
			<field ref="contributors" />
			<field ref="publisher" required="yes"/>
			<field ref="date"/>
			<field ref="official_url"/>
			<field ref="bounding_box"/>
			
		</component>
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
	$when_statement->appendChild($xml->create_element("stage", ref=>"dataset"));

	my $otherwise_statement = $xml->create_element("epc:otherwise");
	$choose_statement->appendChild($otherwise_statement);
	$otherwise_statement->appendChild($flow_elements);

	open( FILE, ">", $filename );

	print FILE $xml->to_string($dom, indent=>1);

	close( FILE );

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
	my $choose = $dom->ownerDocument->getElementById("dataplus_choose");
	my @choices = $dom->getElementsByTagName("epc:choose");
	foreach my $element (@choices)
	{
		print STDERR $xml->to_string($element)."bacon\n\n";
		if($element->hasAttribute("required_by") && $element->getAttribute("required_by") eq $self->{package_name})
		{
			$choose = $element;
			last;
		}
	}
	my $choose_parent = $choose->parentNode; #probably the flow element but err on the side of caution
	my @otherwise = $choose->getElementsByTagName("otherwise");

        foreach my $element ($otherwise[0]->childNodes()){
                $element->unbindNode();
                $choose_parent->appendChild($element);
        }

	open( FILE, ">", $filename );

	print FILE $xml->to_string($dom, indent=>1);

	close( FILE );

	EPrints::XML::remove_package_from_xml( $filename, $self->{package_name} );

	$self->reload_config if !$skip_reload;
}

1;
