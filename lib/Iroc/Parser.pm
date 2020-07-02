package Iroc::Parser;

use strict;
use warnings;
use feature 'switch';
no warnings 'experimental';

use Exporter qw<import>;
our @EXPORT_OK = qw<parse>;

our $VERBOSE = 0;

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
  sub new {
    my ($pkg, $t, @rest) = @_;
    bless { _type => $t, data => \@rest, }, $pkg; 
  };

  sub eval {
    my ($self) = @_;
    my $t;
    given ($t = $self->{_type}) {
      when ($t eq 'literal') { return $self->{data}->[0];  };
      when ($t eq 'group')   { return $self->{data}->eval; };
     
      when ($t eq 'binary') {
        printf "binary\n";
        my ($l, $o, $r) = ($self->{data}->@*);
        return $l le $r if $o eq 'LE';
        return $l lt $r if $o eq 'LT';
        return $l ge $r if $o eq 'GE';
        return $l gt $r if $o eq 'GT';
        return $l eq $r if $o eq 'EQ';
        return $l ne $r if $o eq 'NE';
        return $l - $r if $o eq 'MINUS';
        return $l + $r if $o eq 'PLUS';
        return $l * $r if $o eq 'STAR';
        return $l / $r if $o eq 'DIV';
        return undef;
      }
      when ($t eq 'unary') {
        my $r = $self->{data}->[1]->eval;
        return $self->{data}->[1] * -1
          if $self->{data}->[0]->{type} eq 'MINUS';
        return !$self->{data}->[1]
          if $self->{data}->[0]->{type} eq 'BANG';
        return undef;
      }
      default {
        die sprintf('I do not know how to evalute expression of type %s', $self->{_type});
      };
    };
  }
};

'0e0';
