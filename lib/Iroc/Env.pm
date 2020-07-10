package Iroc::Env;

use strict;
use warnings;
#use feature 'switch';
#no warnings 'experimental';

use Exporter qw<import>;
our @EXPORT_OK = qw<new>;

sub new {
  bless { data => {}, meta => ($_[2]//{}), parent => $_[1]//undef, }, $_[0];
}

sub lkp {
  my ($self, $lkp) = @_;

  return $self->_data->{$lkp} if exists $self->_data->{$lkp};
  die sprintf("Variable %s not in scope.", $lkp)
    if !defined $self->_parent;
  return $self->_parent->lkp($lkp);
}

sub set {
  my ($self, $x, $y) = @_;
  $y = $y->eval if ref $y eq 'Iroc::Expression';
  $self->_data->{$x} = $y;
}
sub def {
  my ($self, $lkp) = @_;
use DDP;  printf "lkp(%s)\n%s\n", $lkp, np $self;
  exists $self->_data->{$lkp} ||
  ($self->_parent && $self->_parent->def($lkp));
}

sub _parent {
  ref $_[0]->{parent} eq 'Iroc::Env' ? $_[0]->{parent} : undef;
}

sub _data {
  $_[0]->{data};
}

'0e0';
