#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Einstein::Solver;

my $solver;

note "case 1";
$solver = Einstein::Solver->new();
$solver->init( size => 3, ids => [["foo", "bar", "baz"]], rules => ["< foo bar", "< bar baz"] );

note explain $solver;

my $tboard = $solver->board->clone;
my $res = $solver->fork( foo => 1, $tboard );
is ($res, undef, "Try wrong placement, get nothing")
    or diag explain $res;
note $tboard->to_string;

# die;

$res = $solver->search();
ok ($res);
is_deeply( $res->solved, { foo=>0, bar => 1, baz =>2 } );


done_testing;
