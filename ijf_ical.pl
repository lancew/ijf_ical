#!/use/bin/env perl
use strict;
use warnings;

use Data::Dumper;

use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;
use JSON qw( decode_json );
use LWP::Simple;

my @dates;
my $calendar = Data::ICal->new();
my $json;

for my $year (qw/2018 2019/){
    for my $age (qw/SEN JUN CAD/) {
        $json
            = get('http://data.judobase.org/'
                . 'api/get_json'
                . '?params[action]=competition.get_list'
                . '&params[year]='
                . $year
                . '&params[id_age]='
                . $age );

        my $decoded_json = decode_json($json);

        for my $event (@$decoded_json) {
            $event->{age} = $age || 'SEN';
            push @dates, $event;
        }
    }
}

@dates = sort { $a->{date_from} cmp $b->{date_from} } @dates;

for my $event (@dates) {
    my $vevent = Data::ICal::Entry::Event->new;

    $event->{date_from} =~ m{(\d+)/(\d+)/(\d+)}
        or die 'Date did not match';

    $vevent->add_properties(
        summary     => $event->{age} . ' ' . $event->{name},
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
        )->ical . time,
    );

    $event->{date_to} =~ m{(\d+)/(\d+)/(\d+)}
        or die 'Date did not match';

    $vevent->add_properties(
        dtend => Date::ICal->new(
            year  => $1,
            month => $2,
            day   => $3,
            hour  => 20
        )->ical
    );
    $calendar->add_entry($vevent);
}

print $calendar->as_string;
