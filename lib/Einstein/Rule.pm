package Einstein::Rule;
use Moo;

has src => is => "ro"; # id to which this rule applies
has dst => is => "ro"; # other cells in rule

sub apply {
    my ($self, $cell, $board) = @_;

    die "Abstract class method called";
    # returns possible positions of DST
    # given that SRC is at $cell
};

sub create {
    my $class = shift;
    my ($src, $dst, @rest) = @_;

    $class = "Einstein::Rule::".$class unless $class =~ /::/;
    return $class->new( src => $src, dst => $dst, @rest );
};

my %num_args = (
    '3' => 3,
);
my %dispatch = (
    '=' => sub { create (Same => $_[0], $_[1]), create (Same => $_[1], $_[0] ); },
    '<' => sub { create (Left => $_[1], $_[0]), create (Right => $_[0], $_[1]); },
    '2' => sub { create (Near => $_[0], $_[1]), create (Near => $_[1], $_[0]); },
    '3' => sub { 
        create (Near => $_[0], $_[1]),
        create (Near => $_[1], $_[0]),
        create (Near => $_[1], $_[2]),
        create (Near => $_[2], $_[1]),
        create (Distance => $_[0], $_[2], distance => 2),
        create (Distance => $_[2], $_[0], distance => 2),
    },
);

sub parse {
    my ($class, $max, $str) = @_;

    my ($sign, @ids) = $str =~ /(\S+)/g;
    my $todo = $dispatch{$sign};
    die "Unknown rule prefix $sign"
        unless $todo;
    if ( scalar @ids != ( $num_args{$sign} || 2 ) ) {
        die "Wrong argument count for $sign, found: @ids"
    };

    return my @list_context = $todo->(@ids);
};

package Einstein::Rule::Same;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell) = @_;

    return $cell;
};

package Einstein::Rule::Left;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell) = @_;

    return 0 .. $cell-1;
};

package Einstein::Rule::Right;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell, $board) = @_;

    return $cell+1 .. $board->size;
};


package Einstein::Rule::Near;
use Moo;

extends 'Einstein::Rule';

sub apply {
    my ($self, $cell) = @_;

    return $cell-1, $cell+1;
};

package Einstein::Rule::Distance;
use Moo;

extends 'Einstein::Rule';

has distance => is => "ro", required => 1;
sub apply {
    my ($self, $cell) = @_;

    return $cell - $self->distance, $cell + $self->distance;
};

1;
