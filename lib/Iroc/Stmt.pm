package Iroc::Stmt;

use strict;
use warnings;
use feature 'switch';
no warnings 'experimental';

use Exporter qw<import>;
our @EXPORT_OK = qw<new>;

sub new {
  bless { ($_[1]//())->%* }, $_[0];
}

sub stringify {
  my ($self, $expr) = @_;
  return $self->{env}->lkp($expr->{data}->[0]->{token}) // '-'
    if ($expr->{_type} eq 'id');
  my $v = $expr->eval;
  $v =~ s/(?<!\\)\\n/\n/g;
  $v =~ s/(?<!\\)\\r/\r/g;
  $v =~ s/(?<!\\)\\t/\t/g;
  $expr->{_type} eq 'binary'
    ? ($v ? 'true' : 'false')
    : $v; #sprintf('i do not know how to stringify %s', $expr->{_type});
}

sub eval {
  my ($self) = @_;
  given (my $t = $self->{type}) {
    when ($t eq 'fn') {
      given (my $n = $self->{name}) {
        when ($n eq 'print' || $n eq 'printn') {
          my @e = map { $self->stringify($_) } $self->{expr}->@*;
          $e[0] .= "\n" if $e[0] && $n eq 'printn';
          printf @e;
        }
        default {
          die 'Not able to find a function with name ' . $self->{name};
        };
      };
    };
    when ($t eq 'def') {
      $self->{env}->set($self->{name}, $self->{expr}, 0);
    };
    when ($t eq 'if') {
      if ($self->{expr}->eval) {
        $_->eval for $self->{then}->@*;
      } else {
        $_->eval for $self->{else}->@*;
      }
    }
    when ($t eq 'call') {
      use DDP;
      p $self;
      die 'nyi - call (Iroc::Stmt)';
      $self->{expr}->eval;
    }
    when ($t eq 'ctrl') { die Iroc::Control->new($self->{stmt}); }
    when ($t eq 'while') {
      my $r;
      W:while (!!$self->{expr}->eval) {
        for my $s ($self->{block}->@*) {
          eval {
            $s->eval;
            1;
          } or do {
            my $err = $@;
            if (ref $err eq 'Iroc::Control') {
              last W if $err->t eq 'last';
              next W if $err->t eq 'next';
            } else {
              die $err;
            }
          };
        }
      }
    }
    default {
      die "I don't know what to do with: " . $t;
    };
  };
}

package Iroc::Control {
  sub new { bless { type => $_[1], }, __PACKAGE__; };
  sub t   { $_[0]->{type}; };
};

'0e0';
