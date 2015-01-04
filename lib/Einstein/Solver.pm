package Einstein::Solver;
use Moo;

# recursive solver

use JSON::XS;

use Einstein::RuleSet;
use Einstein::Field;

has rules => is => "rw", default => sub { {} };
has board => is => "rw";
has found => is => "rw", default => sub { {} };
has search_order => is => "rw";

sub init {
    my ($self, %opt) = @_;

    my $size = $opt{size} or die "No size provided";

    my $board = Einstein::Field->new( size => $size );
    $board->init(@{ $opt{ids} });

    my $rules = Einstein::RuleSet->new;
    $rules->add_rules( $opt{rules} );

    # check that keys are the same
    my @bad = grep { !exists $board->id_lookup->{ $_ } } $rules->list;
    die "Unknown keys @bad in ruleset" if @bad;

    $self->board($board);
    $self->rules($rules);

    my @xrules = $self->join_rules;
    $rules = Einstein::RuleSet->new;
    $rules->add_rules( \@xrules );
    warn "Extended ruleset: ".join ", ", map { "'$_'" } @xrules;
    $self->rules($rules);

    $self;
};

sub search {
    my ($self, $board, $order, $depth) = @_;

    $board ||= $self->board;
    $order ||= $self->select_probe;
    $depth ||= 0;

    warn "||| Search order: @$order"
        unless $depth;

    return $board if !$board->unsolved;

    for ( my $i = $depth; $i < @$order; ) {
        my $id = $order->[$i++];
        next if $board->is_solved($id);

        my @where = $board->where($id);

        foreach my $pos(@where) {
            my $t_board = $board->clone;

            warn "...[$i] Trying $id => $pos";
            my $ret = $self->fork($id => $pos, $t_board);
            next unless $ret;

            warn ">>>[$i] Testing $id => $pos; got fixed: ".encode_json($ret);
            $ret = $self->search( $t_board, $order, $i );
            return $ret if $ret;
            warn "<<<[$i] $id => $pos - no luck";
        };
        last;
    };
    return ();
};

sub fork {
    my ($self, $value, $pos, $board) = @_;

    my @set_q = [$value, $pos];
    my %found;

    while (my $action = shift @set_q) {
        my $found = $board->restrict( @$action );
        return () unless $found; # we did something illegal

        # warn "fork(): alive after @$action: ".encode_json($found);

        # now apply rules to all set values
        while( my ($src, $pos) = each %$found ) {
            $found{$src} = $pos;
            my @rules = $self->rules->get_rules($src);
            next unless @rules;
            # warn "$src=>$pos invoked ".(scalar @rules)." rules";
            foreach (@rules) {
                push @set_q, [ $_->dst, $_->apply( $pos, $board ) ];
            };
        };
    };

    return \%found;
};

sub select_probe {
    my $self = shift;

    my @list = $self->board->list;

    my %n_rules;
    my %n_rules_group;
    my %group;
    my %n_rules_2nd;

    foreach (@list) {
        $group{$_} = $self->board->group_n_of($_);
        my @r = $self->rules->get_rules($_);
        $n_rules{$_} = scalar @r;
        $n_rules_group{ $group{$_} } += scalar @r;
    };
    foreach my $this (@list) {
        my @r = $self->rules->get_rules($this);
        foreach my $rule( @r ) {
            $n_rules_2nd{ $rule->dst } += $n_rules{$this};
        };
    };

    @list = sort {
            ($n_rules_2nd{$b} || 0) <=> ($n_rules_2nd{$a} || 0)
        } @list;

    return \@list;
};



# foreach rules such that x-(rule1)->y, y-(rule2)->z
# create a new rule x-(rule1+rule2)->z unless such already exists
sub join_rules {
    my $self = shift;

    my @rule_q = map { $self->rules->get_rules($_) } $self->rules->list;
    my %seen;
    my @ret;

    while (my $first = shift @rule_q) {
        $seen{ $first }++ and next;
        foreach my $second ( $self->rules->get_rules( $first->dst ) ) {
            next if $second->dst eq $first->src; # avoid mirroring
            my $same = $self->board->group_n_of( $first->src )
                eq $self->board->group_n_of( $second->dst );
            push @rule_q, Einstein::Rule->join( $first, $second, $same );
        };
        push @ret, $first;
    };

    return @ret;
};

1;
