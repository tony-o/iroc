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
  use DDP max_depth => 15 ;
  p $x->{data};
}

sub run_file {
  my ($f) = @_;
  open my $fh, '<', $f or die "Unable to open to file $f";
  my $str = do { local $/; <$fh> };
  close $fh;

  run($str);
}

420;
