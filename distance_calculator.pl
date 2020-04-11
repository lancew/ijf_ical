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

our $VERSION = 1.0000;
my @dates;
my $geocoder = Geo::Coder::OSM->new();
my $gis = GIS::Distance->new();
my $json;

$|++;

for my $year (qw/2019/) {
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


my $index = 0;
for my $event (@locations){
    if ($index == 0) {
	    $event->{distance} = 0;
        say '* ' . sprintf("%8d", $event->{distance}) . ' km' . "\t\t" . $event->{name};
	    $index++;
	    next;
    }

    my $prev = $locations[$index - 1];
    my $distance = $gis->distance( $prev->{lat}, $prev->{lon}, $event->{lat}, $event->{lon} );
    $event->{distance} = int($distance->kilometre);
    say '* ' . sprintf("%8d", $event->{distance}) . ' km' . "\t\t" . $event->{name};

    $index++;
}


my $total_distance;

map { $total_distance += $_->{distance}} @locations;

say "Total distance: " . int($total_distance);

# 259 g/km pesimistic co2 per km fot flight
# from https://en.wikipedia.org/wiki/Carbon_footprint#Flight

my $carbon = 259 * $total_distance;
say 'Carbon for the tour: ' . int($carbon/1000) . 'kg Co2';

