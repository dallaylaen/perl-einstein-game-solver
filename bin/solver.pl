#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Einstein::Solver;

$Einstein::clean++;

defined ($_ = <>) or die "Failed to read stdin: $!";

/size (\d+)/ or die "First line MUST be 'size nnn'";
my $size = $1;

defined ($_ = <>) or die "Failed to read stdin: $!";

/__BOARD__/ or die "Second line MUST be __BOARD__";

my @ids;
while (<>) {
    /^__RULES__/ and last;
    /^\s*#/ and next;
    /\S/ or next;

    my @data = /(\S+)/g;
    push @ids, \@data;
};

# now rules
my @rules;
while (<>) {
    /^__END__/ and last;
    /^\s*#/ and next;
    /\S/ or next;

    push @rules, $_;
};

$SIG{__DIE__} = \&Carp::confess;
my $solver = Einstein::Solver->new;
$solver->init( size => $size, ids => \@ids, rules => \@rules );

my $answer = $solver->search;

if ($answer) {
    print $answer->to_string, "\n";
} else {
    print "Unsolvable!\n";
};


