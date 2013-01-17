package EPrints::Plugin::Screen::EPMC::Datashare;

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



	$self->reload_config if !$skip_reload;
}

sub action_disable
{
	my( $self, $skip_reload ) = @_;

	$self->SUPER::action_disable( 1 );

	my $repo = $self->{repository};

	my $default_xml = $repo->config( "config_path" )."/workflows/eprint/default.xml";
	EPrints::XML::remove_package_from_xml( $default_xml, $self->{package_name} );

	$self->reload_config if !$skip_reload;
}

1;
