#!/use/bin/env perl
use strict;
use warnings;

use Carp 'croak';
use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;
use JSON qw( decode_json );
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");
use LWP::Simple;
use Geo::Coder::OSM;

our $VERSION = 1.0000;
my @dates;
my $calendar = Data::ICal->new();
my $geocoder = Geo::Coder::OSM->new();
my $json;

$|++;

for my $year (qw/2020 2021/) {
    for my $age (qw/SEN JUN CAD/) {

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

for my $event (@dates) {
    my $vevent = Data::ICal::Entry::Event->new;

    my $uid = $event->{name};
    $uid =~ s/ //smg;

    $event->{date_from} =~ m{(\d+)/(\d+)/(\d+)}xms
        or croak 'Date did not match';

    $vevent->add_properties(
        summary     => "$event->{age} $event->{name}",
        description => $event->{name} . ' ('
            . $event->{country_short} . ') '
            . $event->{rank_name} . ' ['
            . $event->{age} . ']',
        dtstart => Date::ICal->new(
            year  => $1,
            month => $2,
            day   => $3,
            hour  => 10
        )->ical,
        dtstamp => Date::ICal->new(
            year  => $1,
            month => $2,
            day   => $3,
            hour  => 10
        )->ical,
        uid => Date::ICal->new(
            year  => $1,
            month => $2,
            day   => $3,
            hour  => 10
            )->ical
            . $uid,
    );

    $event->{date_to} =~ m{(\d+)/(\d+)/(\d+)}xms
        or croak 'Date did not match';

    $vevent->add_properties(
        dtend => Date::ICal->new(
            year  => $1,
            month => $2,
            day   => $3,
            hour  => 20
        )->ical
    );

    my $geo_location = $geocoder->geocode(
        location => $event->{city} . ', ' . $event->{country},
        city     => $event->{city},
        country  => $event->{country},
        limit    => 1,
    );
    $vevent->add_properties(
        geo => $geo_location->{lat} . ';' . $geo_location->{lon} )
        if $geo_location && $geo_location->{lat};

    $calendar->add_entry($vevent);
}

my $calendar_text = $calendar->as_string;
$calendar_text =~ s/^$//smx;
my $ok = print $calendar_text;
