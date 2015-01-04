package Einstein::Rule;
use Moo;

has src => is => "ro"; # id to which this rule applies
has dst => is => "ro"; # other cells in rule

use overload '""'=>"to_string";

sub apply {
    my ($self, $cell, $board) = @_;

    die "Abstract class method called";
    # returns possible positions of DST
    # given that SRC is at $cell
};

# Abbreviated constructor: src, dst, %other_stuff
sub create {
    my $class = shift;
    my ($src, $dst, @rest) = @_;

    $class = "Einstein::Rule::".$class unless $class =~ /::/;
    return $class->new( src => $src, dst => $dst, @rest );
};

my %num_args = (
    '3' => 3,
    'd' => 3,
);
my %dispatch = (
    '=' => sub { create (Same => $_[0], $_[1]), create (Same => $_[1], $_[0] ); },
    '<' => sub { create (Left => $_[1], $_[0]), create (Right => $_[0], $_[1]); },
    '>' => sub { create (Right => $_[1], $_[0]), create (Left => $_[0], $_[1]); },
    '2' => sub {
        create (Distance => $_[0], $_[1]),
        create (Distance => $_[1], $_[0]);
    },
    '3' => sub {
        create (Distance => $_[0], $_[1]),
        create (Distance => $_[1], $_[0]),
        create (Distance => $_[1], $_[2]),
        create (Distance => $_[2], $_[1]),
        create (Distance => $_[0], $_[2], distance => 2),
        create (Distance => $_[2], $_[0], distance => 2),
    },
    d => sub {
        create (Distance => $_[1], $_[2], distance => $_[0]),
        create (Distance => $_[2], $_[1], distance => $_[0]),
    },
    p => sub {
        create ( Parity => $_[0], $_[1], parity => 0 ),
        create ( Parity => $_[1], $_[0], parity => 0 ),
    },
    P => sub {
        create ( Parity => $_[0], $_[1], parity => 1 ),
        create ( Parity => $_[1], $_[0], parity => 1 ),
    },
);

sub parse {
    my $class = shift;

    my @res;
    foreach (@_) {
        my ($sign, @ids) = /(\S+)/g;
        my $todo = $dispatch{$sign};
        die "Unknown rule prefix $sign"
            unless $todo;
        if ( scalar @ids != ( $num_args{$sign} || 2 ) ) {
            die "Wrong argument count for $sign, found: @ids"
        };

        push @res, $todo->(@ids)
    };
    return @res;
};

my %join_action = (
    "> >" => sub { create( Left => $_[0],$_[1] ), create( Right => $_[1],$_[0] ) },
    "< <" => sub { create( Right => $_[0],$_[1] ), create( Left => $_[1],$_[0] ) },
    "= =" => sub { create( Same => $_[0], $_[1] ) },
    "= >" => sub { create( Left => $_[0],$_[1] ), create( Right => $_[1],$_[0] ) },
    "= <" => sub { create( Right => $_[0],$_[1] ), create( Left => $_[1],$_[0] ) },
    "same d d" => sub {
        $_[2]->distance == $_[3]->distance or return ();
        create ( Distance => $_[0], $_[1], distance => 2*$_[2]->distance ),
        create ( Distance => $_[1], $_[0], distance => 2*$_[2]->distance ),
    },
    "same d <" => sub {
        $_[2]->distance == 1 or return ();
        create( Right => $_[0],$_[1] ), create( Left => $_[1],$_[0] )
    },
    "same d >" => sub {
        $_[2]->distance == 1 or return ();
        create( Left => $_[0],$_[1] ), create( Right => $_[1],$_[0] )
    },
    "d d" => sub {
        my $p = $_[2]->distance + $_[3]->distance;
        create ( Parity => $_[0], $_[1], parity => $p ),
        create ( Parity => $_[1], $_[0], parity => $p ),
    },
    "d p" => sub {
        my $p = $_[2]->distance;
        create ( Parity => $_[0], $_[1], parity => $p ),
        create ( Parity => $_[1], $_[0], parity => $p ),
    },
    "d P" => sub {
        my $p = $_[2]->distance + 1;
        create ( Parity => $_[0], $_[1], parity => $p ),
        create ( Parity => $_[1], $_[0], parity => $p ),
    },
);

sub join {
    my ($class, $first, $second, $same) = @_;
    my $sign = join " ", $first->sign, $second->sign;
    my @ret;
    if (my $todo = $join_action{$sign}) {
        push @ret, $todo->( $first->src, $second->dst, $first, $second );
    };
    if ($same and my $todo = $join_action{"same $sign"}) {
        push @ret, $todo->( $first->src, $second->dst, $first, $second );
    };
    return @ret;
};

sub to_string {
    my $self = shift;
    return sprintf "%s %s %s", $self->sign, $self->src, $self->dst;
};

package Einstein::Rule::Same;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell) = @_;

    return $cell;
};

sub sign { "=" };

package Einstein::Rule::Left;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell) = @_;

    return 0 .. $cell-1;
};

sub sign { ">" };

package Einstein::Rule::Right;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell, $board) = @_;

    return $cell+1 .. $board->size;
};

sub sign { "<" };

package Einstein::Rule::Distance;
use Moo;

extends 'Einstein::Rule';

has distance => is => "ro", default => sub{1};
sub apply {
    my ($self, $cell) = @_;

    return $cell - $self->distance, $cell + $self->distance;
};

sub sign { "d" };

sub to_string {
    my $self = shift;
    return join " ", $self->distance == 1 ? ("2") : ("d", $self->distance)
        , $self->src, $self->dst;
};

package Einstein::Rule::Parity;
use Moo;

extends 'Einstein::Rule';

has parity => is => "ro", default => sub { 0 };

sub apply {
    my ($self, $pos, $field) = @_;
    
    my $p = ( $self->parity + $pos ) & 1;
    return map { $p + 2 * $_ } 0 .. $field->size / 2;
};

sub sign {
    my $self = shift;
    $self->parity & 1 ? 'P' : 'p';
};

1;
