package Einstein::Storage;
use Moo;

# base class for field & group

use Carp;

has size => is => "ro", required => 1;
has ids => is => "ro", default => sub { {} }, coerce => sub {
        my $data = shift;
        if (ref $data eq 'ARRAY') {
            $data = { map { $_ => 1 } @$data };
        };
        $data;
    };
has unsolved => is => "rw", lazy => 1, default => sub { scalar $_[0]->list };

sub validate {
    my $self = shift;
    my $value = shift;

    confess "Unknown identifier '$value'"
        if defined $value and !exists $self->ids->{$value};

    my @bad = grep {
        !/^\d+$/ or $_ > $self->size;
    } @_;

    @bad and confess "Bad columns: @bad (of @_)";
    return $self;
};

sub invert {
    my $self = shift;
    my %seen;
    $seen{$_}++ for @_;
    return grep { !$seen{$_} } 0 .. $self->size-1;
};

sub list {
    my $self = shift;
    return keys %{ $self->ids };
};

1;
