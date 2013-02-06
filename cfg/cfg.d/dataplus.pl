$c->{plugins}->{"Screen::NewDataset"}->{params}->{disable} = 0;

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
