# CVEs detected via cpan-audit, so force load
# newer versions.
requires 'File::Temp', '== 0.2311';
requires 'Compress::Raw::Zlib', '== 2.206';

# Dependencies of this code
requires 'Data::ICal', '== 0.24';
requires 'JSON::MaybeXS', '== 1.004003';
requires 'LWP::Simple', '== 6.67';
requires 'LWP::Protocol::https', '== 6.10';
requires 'Geo::Coder::OSM', '== 0.03';
requires 'GIS::Distance', '== 0.19';
requires 'Date::ICal', '== 2.678';
requires 'Number::Format', '== 1.75';
requires 'String::Pad', '== 0.021';
