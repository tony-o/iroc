package Iroc::Parser;

use strict;
use warnings;
use feature 'switch';
no warnings 'experimental';

use Exporter qw<import>;
our @EXPORT_OK = qw<parse>;

use Iroc::Stmt;
use Iroc::Expression;
use Iroc::Env;
our $VERBOSE = 0;

sub new {
  bless {
    tokens  => [ref $_[1] eq 'ARRAY' ? $_[1] : @_[1..@_-1]],
    idx     => 0,
    stmt    => [],
    env     => Iroc::Env->new(undef, {ident => 0}),
    idt     => undef,
    _scopel => 0,
  }, $_[0];
}

sub parse {
  my $i = Iroc::Parser->new(ref $_[0] eq 'Iroc::Parser' ? @_[1..@_-1] : @_);
  $i->{idx} = 0;
  my $e;
  while (!$i->_end) {
    $e = $i->_stmt;
    last unless $e;
    push $i->{stmt}->@*, $e if ref $e eq 'Iroc::Stmt';
  }
# need to do something if we have more garbage.
  #use DDP; p $i->{stmt};
  $i;
}

sub _stmt {
  my ($self) = @_;
  my $idx = $self->{idx};
  if ($self->_eat(qr/^ID$/, 1, 1)) {
    my $id = $self->_previous;
    if ($id->{token} eq 'print' || $id->{token} eq 'printn') {
      return $self->_print;
    } elsif ($self->_eat(qr/^DEF$/)) {
      return $self->_decl($id);
    } else {
      die sprintf("I don't know what you want with %s\n", $self->_previous->{token});
    }
  }
  $self->{idx} = $idx; # don't FF
  undef;
}

sub _decl {
  my ($self, $id) = @_;
  my $expr = $self->_printeat
    or die 'Expected expression in variable declaration';
  $self->_eatordie(qr/^(NL|EOF)$/, 'Expect new line or EOF after variable declaration');
  Iroc::Stmt->new({
    type => 'def',
    name => $id->{token},
    expr => $expr,
    env  => $self->{env},
  });
}

sub _printeat {
  my ($self) = @_;
  eval {
    $self->_expression;
#  } or eval {
#    $self->_id;
  } or do {
    undef;
  };
}
sub _print {
  my ($self) = @_;
  my $tok  = $self->_previous;
  my @expr;
  my $x;
  while ($x = $self->_printeat) {
    push @expr, $x;
  }
  $self->_eatordie(qr/^(NL|EOF)$/, 'Expect new line after print statement');
  Iroc::Stmt->new({
    type  => 'fn',
    name  => $tok->{token},
    expr  => \@expr,
    token => $tok,
    env   => $self->{env},
  });
}

sub _id {
  my ($self) = @_;
  if ($self->_eat(qr/^ID$/)) {
    return Iroc::Expression->new(
      'id',
      $self->{env},
      $self->_previous,
    );
  }
  undef;
}

sub _expression {
  $_[0]->_equality;
}

sub _equality {
  my ($self) = @_;
  my $expr   = $self->_comparison;
  while ($self->_eat(qr/^(EQ|NE)$/)) {
    $expr = Iroc::Expression->new(
      'binary',
      $self->{env},
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
    $expr = Iroc::Expression->new(
      'binary',
      $self->{env},
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
    $expr = Iroc::Expression->new(
      'binary',
      $self->{env},
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
    $expr = Iroc::Expression->new(
      'binary',
      $self->{env},
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
    return Iroc::Expression->new(
      'unary',
      $self->{env},
      $self->_previous,
      $self->_unary,
    );
  }
  $self->_primary;
}

sub _primary {
  my ($self) = @_;
  return Iroc::Expression->new('literal', $self->{env}, $self->_previous)
    if ($self->_eat(qr/^(NULL|TRUE|FALSE)$/));
  return Iroc::Expression->new('literal',  $self->{env}, $self->_previous)
    if ($self->_eat(qr/^(NUM|STR)$/));
  if ($self->_eat(qr/^(LPAR)$/)) {
    my $tok = $self->_expression;
    $self->_eatordie(qr/^RPAR$/, 'Expected right paren, did not find.');
    return Iroc::Expression->new('group', $self->{env}, $tok);
  }
  return $self->_id || 
    die $self->_error('expected expression')->error;
}

sub _eat {
  my ($self, $regex, $eatws, $changescope) = @_;
  my $idx = $self->{idx};
  $changescope //= 0;
  if ($eatws//1) { #consume meaningless WS
    my $is = 0;
    while ($self->{tokens}->[$idx] && $self->{tokens}->[$idx]->{type} eq 'SPACE') {
      $is += length $self->{tokens}->[$idx]->{token};
      $idx++;
    }
    if ($self->{tokens}->[$idx]->{type} !~ $regex) {
      return undef;
    }
    if ($changescope) {
      my $level = $is; #$idx - $self->{idx};
      if ($self->{_scopel} < $level) {
        $self->{env} = Iroc::Env->new($self->{env}, { ident => $is });
      } elsif ($self->{_scopel} > $level) {
        while ($self->{env}->{meta}->{ident} > $level) {
          $self->{env} = $self->{env}->{parent} or die 'unwound environment too far.';
        }
      }
      $self->{_scopel} = $level;
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
sub _end {
  my ($self) = @_;
  return 1 if $self->{tokens}->@* <= $self->{idx};
  my $idx = $self->{idx};
  while ($self->{tokens}->@* > $idx) {
    return 0 if $self->{tokens}->[$idx++]->{type} !~ m/^(NL|SPACE|EOF)$/;
  }
  return 1;
}

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

'0e0';
