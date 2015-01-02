#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Einstein::Rule;

my $board = Board->new;

my @rules = map { Einstein::Rule->parse( 6, $_ ) } 
    "< foo bar",
    "= iii lust",
    "2 a b",
    "3 a iii bar",
    ;

my %sort;
push @{ $sort{ $_->src } }, $_ for @rules;

note explain \%sort;

is_deeply( [sort keys %sort], [sort qw( foo bar iii lust a b) ], "Sorted by src");

my %apply = ();
foreach my $r( @{ $sort{bar} } ) {
    $apply{$r->dst}{$_}++ for $r->apply( 3, $board );
};

is_deeply( \%apply, { 
        foo => { 0=>1, 1=>1, 2=>1 }, 
        iii => { 2=>1, 4=>1 },
        a => { 1 => 1, 5 => 1 },
    }, "Apply rules forks (bar)" );

done_testing;

package Board;
sub new { return bless {}, shift };
sub size { return 7 };
