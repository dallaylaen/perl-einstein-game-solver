#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

use Einstein::Group;

$SIG{__DIE__} = \&Carp::confess;

my @ids = qw(envy gluttony wrath lust sloth greed vanity);

my $group = Einstein::Group->new( size => 7, ids => \@ids );

# construction
is ( $group->size, 7, "Constructed: size" );
is ( $group->unsolved, 7, "Constructed: unsolved" );
is_deeply ( [sort $group->list], [sort @ids], "Constructed: list" );

# r/o
is_deeply ( [$group->invert( 1, 3, 5 )], [0,2,4,6], "Inversion" );
is_deeply ( [$group->where("envy")], [0..6], "Where" );

# r/w
ok ($group->put( gluttony => 5 ), "put works"); 
is ($group->unsolved, 6, "Unsolved decreased");
is_deeply( [$group->where( "gluttony")], [5], "Where strict");
is_deeply( [$group->where( "envy")], [0..4, 6], "Where with hole");

ok (!$group->put( gluttony => 3 ), "second put !works"); 
ok (!$group->put( gluttony => 5 ), "second put !works");

ok ( $group->restrict( envy => 2,3 ), "Restricting envy" );
is_deeply ( [$group->where( "envy" )], [2,3], "Restricting worked" );
is ($group->unsolved, 6, "Unsolved stays");

ok ( $group->restrict( envy => 3,4 ), "Restricting envy again" );
is_deeply ( [$group->where( "envy" )], [3], "Restricting worked" );
is ($group->unsolved, 5, "Unsolved decreased");

is_deeply( $group->what(3), ["envy"], "What works");

# cloning

my $new = $group->clone;

note Dumper( $new );

ok ( $new->restrict( lust => 0 ), "Change clone");
is_deeply( [$new->where("lust")], [0], "lust found");
is_deeply( [$group->where("lust")], [0..2,4,6], "lust found in origin");

# note Dumper( $group );
note $group->to_string;

my $incomplete = Einstein::Group->new(size => 7, ids => [qw(foo bar baz)]);

# FIXME bug! 
# We should handle imcomplete groups, too
ok ($incomplete->restrict (foo => 1,0));
note $incomplete->to_string;
ok ($incomplete->restrict (baz => 5,6));
note Dumper( $incomplete );
note $incomplete->to_string;
ok ($incomplete->restrict (bar => 1,3,5));

note $incomplete->to_string;

ok ($incomplete->forbid (bar=>3));
ok ($incomplete->forbid (foo=>0));
note $incomplete->to_string;

done_testing;

