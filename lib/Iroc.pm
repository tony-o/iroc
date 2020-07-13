package Iroc;

use strict;
use warnings;

use Exporter qw<import>;
our @EXPORT_OK = qw<run run_file>;

use Iroc::Scanner;
use Iroc::Parser;

our $VERBOSE = 0;

sub run {
  my ($str) = @_;
  $Iroc::Scanner::VERBOSE = $VERBOSE;
  $Iroc::Parser::VERBOSE = $VERBOSE;
  my $x = Iroc::Parser::parse(
    Iroc::Scanner::scan($str)
  );
  for my $s ($x->{stmt}->@*) {
    eval {
      $s->eval($x->{env});
      1;
    } or do {
      my $err   = $@;
      if (ref $@ eq 'Iroc::Control') {
        $err = sprintf '%s called outside of while', $err->t;
      }
      my @lines = split "\n", $str;
      my $linex = $s->{token}->{line};
      my $posx  = $s->{token}->{pos};
      $linex -= 4;
      while ($linex < $s->{token}->{line} && $linex < @lines) {
        printf "%d %s\n", 1 + $linex, $lines[$linex] if $linex >= 0 && $linex < @lines;
        $linex++;
      }
      printf "Runtime exception: %s\n", $err;
#      caught at:\n  line: %d\n  position %d\n",
#             $err,
#             $linex,
#             $posx,
#             ;
      exit 255;
    };
  }
  undef;
}

sub run_file {
  my ($f) = @_;
  open my $fh, '<', $f or die "Unable to open to file $f";
  my $str = do { local $/; <$fh> };
  close $fh;

  run($str);
}

420;
