package Einstein::Field;
use Moo;

use Storable qw(dclone);
use Carp;

extends 'Einstein::Storage';
use Einstein::Group;

# Groups of identifiers that cannot occupy the same cell
has groups     => is => "ro", default => sub { [] };
has id_lookup  => is => "ro", default => sub { {} };

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
        %$self, groups => \@newgr,
    );
};

sub group_of {
    my ($self, $value) = @_;

    return $self->groups->[ $self->id_lookup->{$value} ];
};

sub forbid {
    my ($self, $value, @n) = @_;

    my $gr = $self->group_of($value);
    my $unsolved = $gr->unsolved;
    my $ret = $gr->forbid($value => @n);
    $self->unsolved( $self->unsolved - $unsolved + $gr->unsolved ); 
            # apply unsolved delta
    return $ret;
};

sub restrict {
    my ($self, $value, @n) = @_;

    my $gr = $self->group_of($value);
    my $unsolved = $gr->unsolved;
    my $ret = $gr->restrict($value => @n);
    $self->unsolved( $self->unsolved - $unsolved + $gr->unsolved ); 
            # apply unsolved delta
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



1;
