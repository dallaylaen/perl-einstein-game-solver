#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

use Einstein::Group;

$SIG{__DIE__} = \&Carp::confess;

my @ids = qw(foo bar baz);

my $group = Einstein::Group->new( size => scalar @ids, ids => \@ids );

$group->restrict (foo => 0,1);
$group->restrict (bar => 2,1);
$group->restrict (baz => 0,2);

# note explain $group;

my $case1 = $group->clone;
# note explain $case1;
my $result = $case1->restrict( foo => 0 );
ok ($result, "restrict foo works" );
is_deeply ($result, { foo => 0, bar => 1, baz => 2 }, "Got resolved values (all 3)");
# note "Result = ", explain $result;

# note explain $case1;

is ($case1->unsolved, 0, "0 unsolved");
note $case1->to_string;

done_testing;
