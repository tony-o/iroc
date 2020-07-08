package Iroc::Scanner;

use strict;
use warnings;
use feature 'switch';
no warnings 'experimental';

use Exporter qw<import>;
our @EXPORT_OK = qw<scan>;

our $VERBOSE = 0;

sub scan {
  my @src = split '', $_[ref $_[0] eq 'Iroc::Scanner' ? 1 : 0];
  my ($pos, $line, $c, $take, $tok, $type) = (0,1,0,0,);
  my @tokens;
  while ($c < @src) {
    $tok  = shift @src;
    $type = 'IGNORE';
    $take = -1;
    given ($tok) {
      when ( $tok eq '!' && $src[0] eq '=' ) {
        $take = 1;
        $type = 'NE';
      }
      when ( $tok eq '>' && $src[0] eq '=' ) {
        $take = 1;
        $type = 'GE';
      }
      when ( $tok eq '<' && $src[0] eq '=' ) {
        $take = 1;
        $type = 'LE';
      }
      when ( $tok eq ':' && $src[0] eq '=' ) {
        $take = 1;
        $type = 'DEF';
      }
      when ( $tok eq 'f' && (join '', @src[0..2]) eq 'alse' ) {
        $take = 4;
        $type = 'FALSE';
      }
      when ( $tok eq 't' && (join '', @src[0..2]) eq 'rue' ) {
        $take = 3;
        $type = 'TRUE';
      }
      when ( $tok eq 'n' && (join '', @src[0..2]) eq 'ull' ) {
        $take = 3;
        $type = 'NULL';
      }
      when ( $tok eq '(' ) { $type = 'LPAR';   }
      when ( $tok eq ')' ) { $type = 'RPAR';   }
      when ( $tok eq ',' ) { $type = 'COMMA';  }
      when ( $tok eq '.' ) { $type = 'DOT';    }
      when ( $tok eq '-' ) { $type = 'MINUS';  }
      when ( $tok eq '+' ) { $type = 'PLUS';   }
      when ( $tok eq '*' ) { $type = 'STAR';   }
      when ( $tok eq '/' ) { $type = 'DIV';    }
      when ( $tok eq '!' ) { $type = 'NOT';    }
      when ( $tok eq '=' ) { $type = 'EQ';     }
      when ( $tok eq '>' ) { $type = 'GT';     }
      when ( $tok eq '<' ) { $type = 'LT';     }
      when ( $tok eq ':' ) { $type = 'COLON';  }
      when ( $tok eq "\r" || $tok eq "\t") {   }
      when ( $tok eq "\n" ) {
        $line++;
        $pos = 0;
        $type = 'NL';
      }
      when ( $tok eq ' ' ) {
        join('', @src) =~ m/^[ ]*/;
        $take = length($&) || 0;
        $type = 'SPACE';
      }
      when ( $tok eq '"' || $tok eq '\'' ) {
        join('', @src) =~ m/^.*(?<!\\)$tok/g;
        $take = length($&) || 0;
        $type = 'STR';
      }
      when ( ($tok ge 'a' && $tok le 'z') || ($tok ge 'A' && $tok le 'Z') ) {
        join('', @src) =~ m/^[a-zA-Z0-9_]+/;
        $take = length($&) || 0;
        $type = 'ID';
      }
      when ( $tok ge '0' && $tok le '9' ) {
        join('', @src) =~ m/^\d+/;
        $take = length($&) || 0;
        $type = 'NUM';
      }
      default {
        printf("Unexpected character '%s' line(%s) pos(%s)\n", $tok, $line, $pos);
        exit 128;
      }
    }
    if ( $type ne 'IGNORE' ) {
      my $addon = join '', @src[0..($take - 1)];
      @src = @src[$take..@src - 1] if $take > -1;
      printf("token :type<%s> :token<%s>\n", $type, $type eq 'NL' ? '␤' : "$tok" . ($addon // ''))
        if $VERBOSE;
      push @tokens, {
        type  => $type,
        token => "$tok" . ($addon // ''),
        line  => $line,
        pos   => $pos,
      };
    }
    $pos++;
  }
  push @tokens, { type => 'EOF', token => undef, line => $line, pos => $pos, };
  @tokens;
}

420;
