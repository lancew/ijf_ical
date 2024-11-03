# CVEs detected via cpan-audit, so force load
# newer versions.
requires 'File::Temp', '== 0.2311';
requires 'Compress::Raw::Zlib', '== 2.213';

# Dependencies of this code
requires 'Data::ICal', '== 0.24';
requires 'JSON::MaybeXS', '== 1.004008';
requires 'LWP::Simple', '== 6.77';
requires 'LWP::Protocol::https', '== 6.14';
requires 'Geo::Coder::OSM', '== 0.03';
requires 'GIS::Distance', '== 0.20';
requires 'Date::ICal', '== 2.682';
requires 'Number::Format', '== 1.76';
requires 'String::Pad', '== 0.021';

requires 'App::UpdateCPANfile', '== v1.1.1';
