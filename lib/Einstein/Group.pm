package Einstein::Group;
use Moo;

extends 'Einstein::Storage';

# Group is a set of <= n values in n cells. 
# Values can't occupy the same cell.

use Storable qw(dclone);
use Carp;

has cells => is => "ro", lazy => 1, default => sub { 
        my @empty; push @empty, {} for 1..$_[0]->size; \@empty
    };

sub clone {
    my $self = shift;
    return (ref $self)->new( %$self, cells => dclone( $self->cells ) );
};

# put and forbid return $self || ()
# so we can do something like 
# @foo = map { ...->clone->put/forbid(...) } @bar
# $self is returned IFF the change was valid, and DID actually change anything

sub put {
    my ($self, $value, $n) = @_;

    $self->validate( $value => $n )
        unless $Einstein::clean;

    my $cell = $self->cells->[$n];
    return if !ref $cell;
    return if $cell->{$value};
    return $self->forbid( $value, 0..$n-1, $n+1..$self->size - 1 );
};

sub restrict {
    my ($self, $value, @n) = @_;
    return $self->forbid( $value => $self->invert( @n ) );
};

sub forbid {
    my ($self, $value, @n) = @_;

    $self->validate( $value => @n )
        unless $Einstein::clean;

    my %change;
    foreach my $i( @n ) {
        my $cell = $self->cells->[$i];
        ref $cell or next;
        $cell->{$value} and next;
        $change{$i}++;
    };
    return unless %change;

    # calculate what left after all
    my @left = grep { 
            !$change{$_} and ref $self->cells->[$_] and !$self->cells->[$_]{$value};
        } 0 .. $self->size-1;
    return unless @left; # illegal

    # put if only one possible cell left
    if (@left == 1) {
        $self->cells->[ $left[0] ] = $value;
        $self->unsolved( $self->unsolved-1 );
    };
    $self->cells->[$_]{$value}++ for keys %change;

    # GC everything else
    foreach my $i ( 1 .. $self->size - 1 ) {
        my $cell =  $self->cells->[$i];
        next unless ref $cell;
        if (scalar keys %$cell == $self->size - 1) {
            my @only = grep { !$cell->{$_} } $self->list;
            confess "ILLEGAL in forbid(): 1 != @only"
                if (@only != 1);
            if (!$self->restrict( $only[0] => $i ) ) {
                # If we are here, there are NO OTHER cells where only[0] can exist
                # Work around bad design and set it manually.
                # Somebody has to rewrite this shit.
                $self->cells->[$i] = $only[0];
                $self->unsolved( $self->unsolved-1 );
            };
        };
    };

    return $self;
};

sub where {
    my ($self, $value) = @_;

    $self->ids->{$value}
        or die "Unknown id=$value";

    my @ret;
    foreach ( 0 .. $self->size - 1 ) {
        my $cell = $self->cells->[$_];
        if (ref $cell) {
            !$cell->{$value} and push @ret, $_;
        } else {
            $cell eq $value and return ($_);
        };
    };
    return @ret;
};

sub what {
    my ($self, $n) = @_;

    my $cell = $self->cells->[$n];
    return [$cell] unless ref $cell;

    return [grep { !$cell->{$_} } $self->list ];
};

sub to_string {
    my $self = shift;

    my @str;
    foreach my $n (0 .. $self->size-1) {
        my $data = $self->what($n);
        push @str, sprintf '[%s]', join "|", map { "'$_'" } @$data;
    };
    return join ",", @str;
};

1;
