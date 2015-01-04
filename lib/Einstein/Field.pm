package Einstein::Field;
use Moo;

use Storable qw(dclone);
use Carp;

extends 'Einstein::Storage';
use Einstein::Group;

# Groups of identifiers that cannot occupy the same cell
has groups     => is => "ro", default => sub { [] };
has id_lookup  => is => "ro", default => sub { {} };
has solved     => is => "ro", default => sub { {} };

sub init {
    my ($self, @ids) = @_;

    my %seen;
    my $n = 0;
    foreach my $gr (@ids) {
        my @group = @$gr;
        $seen{$_}++ and die "Duplicate identifier $_" for @group;
    
        @group > $self->size and die "Group too large: @group";
        my $storage = Einstein::Group->new( size => $self->size, ids => \@group );
        push @{ $self->groups }, $storage;
        $self->id_lookup->{$_} = $n for @group;
        $n++;
    };

    $self->unsolved( scalar keys %seen );
    $self;
};

sub clone {
    my $self = shift;

    my @newgr = map { $_->clone } @{ $self->groups };

    return __PACKAGE__->new(
        %$self, groups => \@newgr, solved => {%{ $self->solved }},
    );
};

sub is_solved {
    my ($self, $id) = @_;
    return exists $self->solved->{$id};
};

sub group_n_of {
    my ($self, $value) = @_;

    return $self->id_lookup->{$value};
};

sub group_of {
    my ($self, $value) = @_;

    return $self->groups->[ $self->id_lookup->{$value} ];
};

sub forbid {
    my ($self, $value, @n) = @_;

    my $gr = $self->group_of($value);
    my $ret = $gr->forbid($value => @n);
    return unless $ret;
    $self->solved->{$_} = $ret->{$_} for keys %$ret;
    $self->unsolved( $self->unsolved - scalar keys %$ret );
    return $ret;
};

sub restrict {
    my ($self, $value, @n) = @_;

    my $gr = $self->group_of($value);
    my $ret = $gr->restrict($value => @n);
    return unless $ret;
    $self->solved->{$_} = $ret->{$_} for keys %$ret;
    $self->unsolved( $self->unsolved - scalar keys %$ret );
    return $ret;
};

sub where {
    my ($self, $value) = @_;

    return $self->group_of($value)->where($value);
};

sub left_from {
    my ($self, $value) = @_;
    return 0 .. [$self->where($value)]->[-1]-1;
};

sub right_from {
    my ($self, $value) = @_;
    return [$self->where($value)]->[0]+1 .. $self->size-1;
};

sub list {
    my $self = shift;
    return keys %{ $self->id_lookup };
};

sub to_string {
    my $self = shift;
    return join "\n", map { $_->to_string } @{ $self->groups };
};


1;
