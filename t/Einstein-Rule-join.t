#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Einstein::Rule;

my @initial = Einstein::Rule->parse( 
    "2 i B", "2 B iii", "d 2 B D", "d 2 D F", "< i ii", "< ii iii", "< i D");

my %added;
foreach my $first (@initial) {
    foreach my $second (@initial) {
        next unless $first->dst eq $second->src;
        next if $first->src eq $second->dst;
        my $same = $first->src =~ /[iv]/ eq $second->dst =~ /[iv]/;
        foreach ( Einstein::Rule->join( $first, $second, $same ) ) {
            $added{$_} = $_;
        };
    };
};

is_deeply( [sort grep { !/^[pP]/ } keys %added]
    , [ sort '< i iii', '> iii i', '< B D', '> D B', 'd 4 B F', 'd 4 F B',
        'd 2 i iii', 'd 2 iii i' ]
    , "Added as expected");

done_testing;
