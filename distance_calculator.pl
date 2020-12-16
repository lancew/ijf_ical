use 5.028;

use strict;
use warnings;
use utf8;

binmode STDOUT, ":encoding(UTF-8)";

# This script will take the IJF world tour data and calculate the distances involved
# and the carbon footprint. Later versions may allow you to set a home location and
# calculate based on return journeys

# steps
# * get the events for the year
# * loop around getting the lat/lon
# * calculate distance beteen and add to an array of hashes
# * display results

use Carp 'croak';
use JSON qw( decode_json );
use LWP::Simple;
use Geo::Coder::OSM;
use GIS::Distance;
use Number::Format 'format_number';
use String::Pad 'pad';

our $VERSION = 1.0000;
my @dates;
my $geocoder = Geo::Coder::OSM->new();
my $gis = GIS::Distance->new();
my $json;

$|++;

for my $year (qw/2020/) {
    say $year;	
    for my $age (qw/SEN/) {
        $json
            = get('http://data.judobase.org/'
                . 'api/get_json'
                . '?params[action]=competition.get_list'
                . '&params[year]='
                . $year
                . '&params[id_age]='
                . $age );

        my $decoded_json = decode_json($json);

        for my $event ( @{$decoded_json} ) {
            $event->{age} = $age || 'SEN';
            push @dates, $event;
        }
    }
}

@dates = sort { $a->{date_from} cmp $b->{date_from} } @dates;

use Data::Dumper;

my @locations;

for my $event (@dates) {
    next unless $event->{prime_event};
    #    warn Dumper $event;

    my $location = $geocoder->geocode(
        location => $event->{city} . ', ' . $event->{country},
        city     => $event->{city},
        country  => $event->{country},
        limit    => 1,
    );


    push @locations, {
    	name => $event->{city},
	lat  => $location->{lat},
	lon  => $location->{lon}
    };
}


my $loc_london = $geocoder->geocode(
    location => 'London, United Kingdom',
    limit    => 1
);



say 'IJF World Tour Distances and Carbon Footprint (from London)';


my $index = 0;
for my $event (@locations){

    #my $prev = $locations[$index - 1];
    my $prev = $loc_london;

    my $distance = $gis->distance( $prev->{lat}, $prev->{lon}, $event->{lat}, $event->{lon} );
    $event->{distance} = int($distance->kilometre * 2);
    say '* ' . pad( format_number( sprintf("%8d", $event->{distance})), 8, 'l') . ' km' . "\t\t" . $event->{name};

    $index++;
}


my $total_distance;

map { $total_distance += $_->{distance}} @locations;

say "\tTotal distance: \t" . pad(format_number(int($total_distance)), 8,'l') . ' km';

# 259 g/km pesimistic co2 per km fot flight
# from https://en.wikipedia.org/wiki/Carbon_footprint#Flight

my $carbon = 259 * $total_distance;
say "\tCarbon for the tour: \t" . pad(format_number(int($carbon/1000)), 8, 'l') . ' kg Co2';

