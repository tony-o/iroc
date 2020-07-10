package Iroc::Expression;

use strict;
use warnings;
use feature 'switch';
no warnings 'experimental';

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
      return $self->{data}->[0]->{token};
    };
    when ($t eq 'group')   { return $self->{data}->eval($self->{env}); };
    when ($t eq 'id') {
      return $self->{env}->lkp($self->{data}->[0]->{token});
    };
    when ($t eq 'binary') {
      my ($l, $o, $r) = ($self->{data}->@*);
      return $l->eval($self->{env}) le $r->eval($self->{env}) if $o eq 'LE';
      return $l->eval($self->{env}) lt $r->eval($self->{env}) if $o eq 'LT';
      return $l->eval($self->{env}) ge $r->eval($self->{env}) if $o eq 'GE';
      return $l->eval($self->{env}) gt $r->eval($self->{env}) if $o eq 'GT';
      return $l->eval($self->{env}) eq $r->eval($self->{env}) if $o eq 'EQ';
      return $l->eval($self->{env}) ne $r->eval($self->{env}) if $o eq 'NE';
      return $l->eval($self->{env}) -  $r->eval($self->{env}) if $o eq 'MINUS';
      return $l->eval($self->{env}) +  $r->eval($self->{env}) if $o eq 'PLUS';
      return $l->eval($self->{env}) *  $r->eval($self->{env}) if $o eq 'STAR';
      return $l->eval($self->{env}) /  $r->eval($self->{env}) if $o eq 'DIV';
      return undef;
    }
    when ($t eq 'unary') {
      my $r = $self->{data}->[1]->eval($self->{env});
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

'0e0';
