package Iroc::Expression;

use strict;
use warnings;
use feature 'switch';
no warnings 'experimental';
use Scalar::Util qw(looks_like_number);

use Exporter qw<import>;
our @EXPORT_OK = qw<new>;

use Iroc::Stmt;

sub new {
  my ($pkg, $t, $env, @rest) = @_;
  die 'please provide a valid environment' unless ref $env eq 'Iroc::Env';
  bless { _type => $t, env => $env, data => \@rest, }, $pkg; 
};

sub eval {
  my ($self) = @_;
  my $t;
  given ($t = $self->{_type}) {
    when ($t eq 'literal') {
      return $self->{data}->[0]->{type} eq 'NULL' ? undef : $self->{data}->[0]->{token};
    };
    when ($t eq 'group') {
      return $self->{data}->[0]->eval($self->{env});
    };
    when ($t eq 'id') {
      return $self->{env}->lkp($self->{data}->[0]->{token});
    };
    when ($t eq 'binary') {
      my ($l, $o, $r) = ($self->{data}->@*);
      my ($x, $y) = ($l->eval($self->{env}), $r->eval($self->{env}));
      if (looks_like_number($x) && looks_like_number($y)) {
        return $x <= $y if $o eq 'LE';
        return $x <  $y if $o eq 'LT';
        return $x >= $y if $o eq 'GE';
        return $x >  $y if $o eq 'GT';
        return $x == $y if $o eq 'EQ';
        return $x != $y if $o eq 'NE';
      }
      return $x le $y if $o eq 'LE';
      return $x lt $y if $o eq 'LT';
      return $x ge $y if $o eq 'GE';
      return $x gt $y if $o eq 'GT';
      return $x eq $y if $o eq 'EQ';
      return $x ne $y if $o eq 'NE';
      return $x -  $y if $o eq 'MINUS';
      return $x +  $y if $o eq 'PLUS';
      return $x *  $y if $o eq 'STAR';
      return $x /  $y if $o eq 'DIV';
      return undef;
    };
    when ($t eq 'call') {
      use DDP;
      p $self;
      die 'nyi - call (Iroc::Expression)';
    };
    when ($t eq 'unary') {
      my $r = $self->{data}->[1]->eval($self->{env});
      return $self->{data}->[1] * -1
        if $self->{data}->[0]->{type} eq 'MINUS';
      return !$self->{data}->[1]
        if $self->{data}->[0]->{type} eq 'BANG';
      return undef;
    };
    when ($t eq 'logic') {
      my ($l, $o, $r) = ($self->{data}->@*);
      $l = $l->eval;
      $r = $r->eval;
      return $o eq 'and' ? $l && $r : $o eq 'or' ? $l || $r : die 'How did you get here?'; 
    };
    default {
      die sprintf('I do not know how to evalute expression of type %s', $self->{_type});
    };
  };
}

'0e0';
