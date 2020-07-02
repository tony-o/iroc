package Iroc::Parser;

use strict;
use warnings;

use Exporter qw<import>;
our @EXPORT_OK = qw<parse>;

our $VERBOSE = 0;
use DDP;

sub new {
  bless {
    tokens => [ref $_[1] eq 'ARRAY' ? $_[1] : @_[1..@_-1]],
    idx    => 0,
  }, $_[0];
}

sub parse {
  my $i = Iroc::Parser->new(ref $_[0] eq 'Iroc::Parser' ? @_[1..@_-1] : @_);
  $i->{idx} = 0;
  $i->_expression;
}

sub _expression {
  $_[0]->_equality;
}

sub _equality {
  my ($self) = @_;
  my $expr   = $self->_comparison;
  while ($self->_eat(qr/^(EQ|NE)$/)) {
    $expr = Iroc::Parser::Expression->new(
      'binary',
      $expr,
      $self->_previous->{type},
      $self->_comparison,
    );
  }
  $expr;
}

sub _comparison {
  my ($self) = @_;
  my $expr = $self->_addition;
  printf "==> _comparison: %s\n", np $expr;
  while ($self->_eat(qr/^(GT|GE|LT|LE)$/)) {
    $expr = Iroc::Parser::Expression->new(
      'binary',
      $expr,
      $self->_previous->{type},
      $self->_addition,
    );
  }
  $expr;
}

sub _addition {
  my ($self) = @_;
  my $expr = $self->_multiplication;
  printf "==> _addition: %s\n", np $expr;
  while ($self->_eat(qr/^(MINUS|PLUS)$/)) {
    $expr = Iroc::Parser::Expression->new(
      'binary',
      $expr,
      $self->_previous->{type},
      $self->_multiplication,
    );
  }
  $expr;
}

sub _multiplication {
  my ($self) = @_;
  my $expr = $self->_unary;
  printf "==> _multiplication: %s\n", np $expr;
  while ($self->_eat(qr/^(SLASH|STAR)$/)) {
    $expr = Iroc::Parser::Expression->new(
      'binary',
      $expr,
      $self->_previous->{type},
      $self->_unary,
    );
  }
  $expr;
}

sub _unary {
  my ($self) = @_;
  printf "==> _unary\n";
  if ($self->_eat(qr/^(BANG|MINUS)$/)) {
    return Iroc::Parser::Expression->new(
      'unary',
      $self->_previous,
      $self->_unary,
    );
  }
  $self->_primary;
}

sub _primary {
  my ($self) = @_;
  printf "==> _primary\n";
  return Iroc::Parser::Expression->new('literal', $self->_previous)
    if ($self->_eat(qr/^(NULL|TRUE|FALSE)$/));
  return Iroc::Parser::Expression->new('literal', $self->_previous)
    if ($self->_eat(qr/^(NUM|STR)$/));
  if ($self->_eat(qr/^(LPAR)$/)) {
    my $tok = $self->_expression;
    $self->_eatordie(qr/^RPAR$/, 'Expected right paren, did not find.');
    return Iroc::Parser::Expression->new('group', $tok);
  }
  die $self->_error('expected expression')->error;
}

sub _eat {
  my ($self, $regex, $eatws) = @_;
  my $idx = $self->{idx};
  if ($eatws//1) { #consume meaningless WS
    while ($self->{tokens}->[$idx] && $self->{tokens}->[$idx]->{type} eq 'SPACE') {
      $idx++;
    }
    if ($self->{tokens}->[$idx]->{type} !~ $regex) {
      return undef;
    }
    $self->{idx} = $idx;
  }
  $self->_current && $self->_current->{type} =~ $regex
    ? $self->{idx}++ || 1
    : undef;
}
sub _eatordie {
  my ($self, $regex, $err, $strict) = @_;
  $strict //= 0;
  $self->_eat($regex,$strict);
  die $self->_error('unexpected token')->error if ($self->_previous->{type}//'') !~ $regex;
  undef;
}
sub _fastforward {
  my ($self) = @_;
  while ($self->_current && $self->_current->{type} ne 'NL') {
    $self->{idx}++;
  }
  undef;
}
sub _current  { $_[0]->{tokens}->[$_[0]->{idx}]; }
sub _previous { $_[0]->{idx} == 0 ? undef : $_[0]->{tokens}->[$_[0]->{idx}-1]; }
sub _end { $_[0]->{tokens}->@* < $_[0]->{idx} ? 1 : 0; }

sub _error {
  my ($self, $err) = @_;
  Iroc::Parser::Error->new($self->_current->{type} eq 'EOF'
    ? sprintf("Error line %d pos %d: %s\n", $self->_current->{line}, $self->_current->{pos}, $err)
    : sprintf("Error token %s on line %d pos %d: %s\n", $self->_current->{type}, $self->_current->{line}, $self->_current->{pos}, $err)
  );
}

package Iroc::Parser::Error {
  sub new   { bless { error => $_[1], }, $_[0];    };
  sub error { $_[0]->{error} // 'undefined error'; };
};
package Iroc::Parser::Expression {
  use DDP; 
  sub new {
    my ($pkg, $t, @rest) = @_;
    printf("Made %s expression '%s'\n", $t, np @rest)
      if $VERBOSE;
    bless { _type => $t, data => \@rest, }, $pkg; 
  };
};

'0e0';
