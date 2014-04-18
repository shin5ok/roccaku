package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use File::Find;
use File::Basename;
use FindBin;
use lib qq($FindBin::Bin/../lib);

our %gen_code;

### no need ### our $__GEN_SORT = 250;

sub run {
  my ($self) = @_;

  my $code ||= get_datetime_comment();

  my $lib_path = dirname ( File::Spec->rel2abs( __FILE__ ) );
  find( \&generating_code, "$lib_path/../" );

  for my $c ( sort { $a <=> $b } keys %gen_code ) {
    $code .= $gen_code{$c};
  }

  $code .= "1;\n";

  warn $code;
  return $code;

}

sub generating_code {
  my $f = $File::Find::name;

  (defined $f and -f $f and $f =~ /\.pm$/)
    or return;

  open my $fh, "<", $f
    or return;
  # default 100
  my $gen_sort_num;
  my $code = qq{};
  while (my $line = <$fh>) {
    if ($line =~ m{^\s* our \s+ \$__GEN_SORT \s* \= \s* (\d+) }x) {
      $gen_sort_num = eval { $1 };
    }
    $line =~ m{^1\s*\;\s*\#} and next;
    $line =~ m{\s?(?:use|require)\s+Roccaku} and next;
    $line =~ s{Roccaku}{Roccaku_x}g;
    $code .= $line;
  }
  close $fh;

  defined $gen_sort_num or return;

  $code .= "\n";

  {
    no strict 'refs';
    $gen_code{$gen_sort_num} .= $code;
  }

  return;
}

sub get_datetime_comment {
  my $datetime = strftime "%Y-%m-%d %H:%M:%S", localtime;
  "########## " . $datetime . " ##########\n\n";
}

1; # End of Roccaku::Remote;
