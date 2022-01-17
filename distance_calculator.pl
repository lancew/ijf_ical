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
use Geo::Coder::OSM;
use GIS::Distance;
use Number::Format 'format_number';
use String::Pad 'pad';

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");
use LWP::Simple;

our $VERSION = 1.0000;
my @dates;
my $geocoder = Geo::Coder::OSM->new();
my $gis      = GIS::Distance->new();
my $json;

$|++;

for my $year (qw/2022/) {
    for my $age (qw/SEN/) {
        my $url
            = 'https://data.ijf.org/'
            . 'api/get_json'
            . '?params[action]=competition.get_list'
            . '&params[year]='
            . $year
            . '&params[id_age]='
            . $age;

        my $req = HTTP::Request->new( GET => $url );
        my $res = $ua->request($req);

        if ( $res->is_success ) {
            $json = $res->content;
        }
        else {
            die $res->status_line;
        }

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
    next if $event->{name} =~ /Mixed teams/i;
    next if $event->{name} =~ /Veterans/i;
    next if $event->{name} =~ /\bkata\b/i;
    #    warn Dumper $event;

    my $location = $geocoder->geocode(
        location => $event->{city} . ', ' . $event->{country},
        city     => $event->{city},
        country  => $event->{country},
        limit    => 1,
    );

    push @locations,
        {
        name => $event->{name},
        city => "$event->{city}, $event->{country}",
        lat  => $location->{lat},
        lon  => $location->{lon}
        };
}

my $loc_base = $geocoder->geocode(
    location => 'London, United Kingdom',
    limit    => 1
);

say 'IJF World Tour Distances and Carbon Footprint (from '
    . $loc_base->{address}->{city} . ')';

my $index = 0;
for my $event (@locations) {

    #my $prev = $locations[$index - 1];
    my $prev = $loc_base;

    my $distance = $gis->distance( $prev->{lat}, $prev->{lon}, $event->{lat},
        $event->{lon} );
    $event->{distance} = int( $distance->kilometre * 2 );
    say '* '
        . pad( format_number( sprintf( "%8d", $event->{distance} ) ), 8, 'l' )
        . ' km' . "\t\t"
        . $event->{name};

    $index++;
}

my $total_distance;

map { $total_distance += $_->{distance} } @locations;

say "\tTotal distance: \t"
    . pad( format_number( int($total_distance) ), 8, 'l' ) . ' km';

# 259 g/km pesimistic co2 per km fot flight
# from https://en.wikipedia.org/wiki/Carbon_footprint#Flight

my $carbon = 259 * $total_distance;
say "\tCarbon for the tour: \t"
    . pad( format_number( int( $carbon / 1000 ) ), 8, 'l' )
    . ' kg Co2';

