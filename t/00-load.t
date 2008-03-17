#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok('Carp');
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
	use_ok( 'WWW::PAUSE::RecentUploads' );
}

diag( "Testing WWW::PAUSE::RecentUploads $WWW::PAUSE::RecentUploads::VERSION, Perl $], $^X" );


use WWW::PAUSE::RecentUploads;

my $pause = WWW::PAUSE::RecentUploads->new( login => 'blah', pass => 'bar' );

isa_ok( $pause, 'WWW::PAUSE::RecentUploads' );
can_ok( $pause, qw( login pass ua_args get_recent error ) );

is( $pause->login, 'blah', "login() method" );
is( $pause->pass, 'bar', "pass() method"    );
my $args = $pause->ua_args;

is(
    ref $args,
    'HASH',
    "ua_args() method must return a hashref",
);

ok(
    exists $args->{timeout},
    "hashref from ua_args method must have `timeout` key",
);

is(
    $args->{timeout},
    30,
    "ua_args `timeout` key must be set to 30 by default",
);