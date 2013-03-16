$c->{plugins}->{"Screen::NewDataset"}->{params}->{disable} = 0;

$c->{uk_data_archive_eprint_render} = $c->{eprint_render};

$c->{eprint_render} = sub
{
        my( $eprint, $repository, $preview ) = @_;

	my ($page, $title, $links ) = $repository->call("uk_data_archive_eprint_render", $eprint, $repository, $preview);

	my $div_right = $repository->make_element('div', class => "rd_citation_right");
	$page->appendChild($div_right);

	my $xml = $repository->xml;
	my $heading = $xml->create_element('h2', class => "file_list_heading");
    	$heading->appendChild($xml->create_text_node("Available Files"));
	$div_right->appendChild($heading);
	
	if(scalar $eprint->get_all_documents() eq 0 ){
		my $nodocs = $repository->make_element('p', class => "file_list_nodocs");
	        $nodocs->appendChild($repository->make_text(" No Files to display"));
		$div_right->appendChild($nodocs);
		return ( $page, $title, $links );
	}
	my $chunks = {};
	foreach my $doc ($eprint->get_all_documents())
	{
                $div_right->appendChild($doc->render_citation_link("uk_data_archive_full"));
#		if(!defined $chunks->{$doc->value("content")."key"})
#		{
#			my $doc_frag = $xml->create_document_fragment;
#			$div_right->appendChild($doc_frag);
#			$chunks->{$doc->value("content")."key"} = $doc_frag;
#			my $content_heading = $xml->create_element('h2', class => "file_title");
#			$content_heading->appendChild($repository->html_phrase("content_typename_".$doc->value("content")));
#			$doc_frag->appendChild($content_heading);
#		}
#
#		$chunks->{$doc->value("content")."key"}->appendChild($doc->render_citation_link("uk_data_archive_full"));
	}
	



        return( $page, $title, $links );
};

push (@{$c->{summary_page_metadata}}, qw/
      alt_title
      creators
      corp_creators
      data_type
      contributors
      funders
      collection_date
      temportal_cover
      grant
      date
      date_type
      geographic_cover
      collection_method
      bounding_box
      legal_ethical
      provenance
      note
      language
      relation
      projects
      ispublished
      publisher
      restrictions
      copyright_holders
      contact_email
      lastmod
      /
);

$c->add_dataset_field( "eprint", {
        name => 'bounding_box',
        type => 'compound',
        fields => [
                {
                        sub_name => 'north_edge',
                        type => 'float',
                },
                {
                        sub_name => 'east_edge',
                        type => 'float',
                },
                {
                        sub_name => 'south_edge',
                        type => 'float',
                },
                {
                        sub_name => 'west_edge',
                        type => 'float',
                },
        ],
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'alt_title',
        type => 'longtext',
        input_rows => 3,
}, reuse => 1 );


$c->add_dataset_field( "eprint", {
        name => 'collection_method',
        type => 'longtext',
        input_rows => '10',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'grant',
        type => 'text',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'provenance',
        type => 'longtext',
        input_rows => '3',

}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'restrictions',
        type => 'text',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'geographic_cover',
        type => 'text',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'language',
        type => 'text',

}, reuse => 1 );

$c->add_dataset_field( "eprint", {       
	name => 'legal_ethical',
        type => 'longtext',
        input_rows => '10',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {   name => 'terms_conditions_agreement',
    type => 'boolean',
    input_style => 'medium',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {   name => 'collection_date',
        type => 'compound',
        fields => [
                {
                        sub_name => 'date_from',
                        type => 'date',
                    render_res => 'day',
        },
                {
                        sub_name => 'date_to',
                        type => 'date',
        },
        ],
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'temporal_cover',
        type => 'compound',
        fields => [
                {
                        sub_name => 'date_from',
                        type => 'date',
                    render_res => 'day',
        },
                {
                        sub_name => 'date_to',
                        type => 'date',
        },
        ],
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
   name => 'original_publisher',
   type => 'text',
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
        name => 'related_resources',
        type => 'compound',
        multiple => 1,
        render_value => 'EPrints::Extras::render_url_truncate_end',
        fields => [
                {
                        sub_name => 'url',
                        type => 'url',
                        input_cols => 40,
                },
                {
                        sub_name => 'type',
                        type => 'set',
                        render_quiet => 1,
            options => [qw(
                                pub
                                author
                                org
                        )],
                }
        ],
        input_boxes => 1,
        input_ordered => 0,
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
   name => 'funders_other_text',
   type => 'text',
   multiple => 1,
}, reuse => 1 );

$c->add_dataset_field( "eprint", {
   name => 'doi',
   type => 'text',
}, reuse => 1 );
