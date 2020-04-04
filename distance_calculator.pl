use strict;
use warnings;


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

    #  warn Dumper $geo_location;

    push @locations, {
    	name => $location->{display_name},
	lat  => $location->{lat},
	lon  => $location->{lon}
    };
}


my $index = 0;
for my $event (@locations){
    if ($index == 0) {
	    $event->{distance} = 0;
	    $index++;
	    next;
    }
    
    my $prev = $locations[$index - 1];
    my $distance = $gis->distance( $prev->{lat}, $prev->{lon}, $event->{lat}, $event->{lon} );
    $event->{distance} = $distance->kilometre;

    $index++;
}


my $total_distance;

map { $total_distance += $_->{distance}} @locations;

warn "Total distance: " . int($total_distance);
