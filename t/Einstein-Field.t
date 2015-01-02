#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

use Einstein::Field;

my $field = Einstein::Field->new( size => 7 );
my @ids = ( ['a'..'g'], [qw(i ii iii iv v vi vii)], 
    [qw(envy gluttony wrath lust sloth greed vanity)] );

$field->init( @ids );

ok( $field->forbid( a => 1,3,4 ), "forbid" );
is_deeply( $field->forbid( a => 1,3,4 ), {}, "forbid again => no work" );

$field->restrict (lust => 5);
is_deeply( [ $field->right_from("lust") ], [6], "right from");

ok ( $field->is_solved( "lust" ), "is_solved added");
ok (!$field->is_solved( "sloth" ), "is_solved not added for non_solved value");
is ($field->solved->{lust}, 5, "Lust reported correctly in solved");

my $new = $field->clone;

$new->restrict( iv => 4 );

is_deeply ( [$new->where("iv")], [4], "Clone's iv");
is_deeply ( [$field->where("iv")], [0..6], "Origin's iv");

done_testing;

