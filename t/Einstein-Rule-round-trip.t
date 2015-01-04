#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Einstein::Rule;

ok_round_trip( "< a b" );
ok_round_trip( "= a b" );
ok_round_trip( "2 a b" );
ok_round_trip( "d 2 a b" );
ok_round_trip( "= x y", "= y z");
ok_round_trip( "d 1 a b" );
ok_round_trip( "3 a b c" );

done_testing;

sub ok_round_trip {
    my @r1 = rules_uniq(@_);
    my @r2 = rules_uniq(@r1);
    my $ret = is_deeply(\@r1, \@r2, "Rules round trip for ".p_rules(@_));
    if ($ret ) {
        note sprintf "Iteration 1: %s", p_rules(@r1);
    } else {
        diag sprintf "Iteration 1: %s\nIteration 2: %s", p_rules(@r1), p_rules(@r2)
    };
    return $ret;
};

sub p_rules {
    return join ", ", map { "'$_'" } @_;
};

sub rules_uniq {
    my @rules = Einstein::Rule->parse( @_ );
    my %uniq;
    $uniq{"$_"}++ for @rules;
    return sort keys %uniq;
};

