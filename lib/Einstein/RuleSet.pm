package Einstein::RuleSet;
use Moo;

use Einstein::Rule;

has set => is => "rw", default => sub { {} };

sub add_rules {
    my ( $self, $lines ) = @_;

    my @rules = map { ref $_ ? $_ : Einstein::Rule->parse($_) } @$lines;

    foreach (@rules) {
        push @{ $self->set->{ $_->src } }, $_;
    };

    return $self;
};

sub get_rules {
    my ($self, $src) = @_;

    return @{ $self->set->{$src} || [] };
};

sub list {
    my $self = shift;
    return keys %{ $self->set };
};

1;
