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
has on_solve => is => "rw";

sub clone {
    my $self = shift;
    return (ref $self)->new( %$self, cells => dclone( $self->cells ) );
};

# put and forbid return $self || ()
# so we can do something like
# @foo = map { ...->clone->put/forbid(...) } @bar
# return () if failed, or { id => fixed_position, id => fixed_position ... }
#       if succeeded

sub restrict {
    my ($self, $value, @n) = @_;
    return $self->forbid( $value => $self->invert( @n ) );
};

sub forbid {
    my ($self, $value, @n) = @_;

    $self->validate( $value => @n )
        unless $Einstein::clean;

    my $cells = $self->cells;

    my %change;
    foreach my $i( @n ) {
        my $cell = $cells->[$i];
        if ( !ref $cell ) {
            $cell eq $value and return (); # trying to forbid already set value
            next;
        };
        $cell->{$value} and next;
        $change{$i}++;
    };

    # calculate what left after all
    my @left;
    foreach (0 .. $self->size-1) {
        $change{$_} and next;
        if (ref $cells->[$_]) {
            !$cells->[$_]{$value} and push @left, $_;
        } else {
            $cells->[$_] eq $value and return { }; # already there, nothing changed
        };
    };
    return {} unless %change; # nothing to be done
    return unless @left;   # illegal

    my %result;
    # put if only one possible cell left
    if (@left == 1) {
        $self->_final( $value => $left[0], $cells );
        $result{$value} = $left[0];
    };
    $cells->[$_]{$value}++ for keys %change;

    # GC everything else
    # if a cell now only allows one value, set it there & cascade
    for (my $i = $self->size; $i-->0; ) {
        ref $cells->[$i] or next;
        my $count = scalar keys $cells->[$i];
        if ($count == $self->size - 1) {
            # we have the ONLY value in a cell.
            # fix it, forbid everywhere else, and start all over again
            my @only = grep { !$cells->[$i]{$_} } $self->list;
            # this means we're SERIOUSLY broken
            @only == 1 or confess ("ILLEGAL STATE in forbid(): must be 1 but @only found");
            $self->_final( $only[0], $i, $cells );
            $result{ $only[0] } = $i;
            ref $_ and $_->{$only[0]}++ for @$cells;
            $i = $self->size;
        };
    };

    return \%result;
};

sub _final {
    my ($self, $value, $pos, $cells) = @_;
    $cells ||= $self->cells;
    $cells->[$pos] = $value;
    $self->unsolved( $self->unsolved - 1 );
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
