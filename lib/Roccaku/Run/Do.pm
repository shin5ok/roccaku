package Roccaku::Run::Do;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base qw( Roccaku::Run::Base );

sub favor {
  my ($self, @args) = @_;

  for my $arg ( @args ) {
    if (ref $arg eq q{HASH}) {
      while (my ($method, $value) = each %$arg) {
        $self->$method( $value );
      }
    } else {
      $self->command( $arg );
    }
  }
}

sub file {
  my ($self, $argv) = @_;

  open my $fh, "<", $argv->{path};
  if (! $fh) {
    $self->fail("$argv->{path} cannot open");
    return 0;
  }
  flock $fh, 2;

  my @contents = <$fh>;
  my @rewrites = ref $argv->{rewrite} eq q{ARRAY}
               ? @{$argv->{rewrite}}
               : ( $argv->{rewrite} );

  my $failure = 0;
  my @news;
  local $@;
  eval {
    no strict 'refs';
    for my $r ( @rewrites ) {
      my %cond;
      exists $r->{after}  and $cond{after}  = 0;
      exists $r->{before} and $cond{before} = 0;

      my $regexp;
      my $cond_name;
      _CONTENTS_:
      for my $line ( @contents ) {
        if (exists $cond{after} and exists $cond{before}) {
          if (! $cond{after}) {
            $regexp    = $r->{after};
            $cond_name = "after";
          } else {
            $regexp    = $r->{before};
            $cond_name = "before";
          }
        } elsif (    exists $cond{after} and not exists $cond{before}) {
          $regexp    = $r->{after};
          $cond_name = "after";
        } elsif (not exists $cond{after} and     exists $cond{before}) {
          $regexp    = $r->{before};
          $cond_name = "before";
        }

        if (defined $regexp and $line =~ /$regexp/) {
          $cond{$cond_name} = 1;
          if ($cond_name eq q{before}) {
            push @news, $r->{add}, $line;
            $regexp = undef;
          }
          elsif ($cond_name eq q{after}) {
            if (not exists $cond{before}) {
              push @news, $line, $r->{add};
              $regexp = undef;
            }
          }
          elsif (exists $r->{remove} and $line =~ /$r->{remove}/) {
            next _CONTENTS_;
          } else {
            push @news, $line;
          }
        }

      }
    }
  };

  seek $fh, 0, 0;
  truncate $fh, 0;
  print {$fh} @news;

  return $failure == 0;

}

1; # End of Roccaku::Do;
