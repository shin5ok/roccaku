=begin
  no use this module
  change name Roccaku::Remote to Roccaku::Generate_Code
=cut
package Roccaku::Generate_Code;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use File::Find;
use File::Basename;
use FindBin;
use lib qq($FindBin::Bin/../lib);

use Roccaku;
use base qw( Roccaku );

our %gen_code;

sub run {
  my ($self) = @_;

  my $code ||= get_datetime_comment();

  my $lib_path = dirname ( File::Spec->rel2abs( __FILE__ ) );
  find( \&generating_code, "$lib_path/../" );

  for my $c ( sort { $a <=> $b } keys %gen_code ) {
    $code .= $gen_code{$c};
  }

  $code .= "\n";
  $code .= generating_code( "$lib_path/../bin/roccaku" );
  $code .= "\n__END__\n";
  if (exists $self->{config_path}) {
    $code .= generating_code( $self->{config_path} );
  }

  return $code;

}

sub generating_code {
  my $f = $File::Find::name;
  $f ||= shift;

  (defined $f and -f $f)
    or return qq{};

  open my $fh, "<", $f
    or return qq{};
  # default 100
  my $gen_sort_num;
  my $code = qq{};
  while (my $line = <$fh>) {
    if ($line =~ m{^\s* our \s+ \$__GEN_SORT \s* \= \s* (\d+) }x) {
      $gen_sort_num = eval { $1 };
    }
    $line =~ m{^\s*$}                        and next;
    $line =~ m{^\s*#}                        and next;
    $line =~ m{^1\s*\;\s*\#}                 and next;
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

  return $code;
}

sub get_datetime_comment {
  my $datetime = strftime "%Y-%m-%d %H:%M:%S", localtime;
  "########## " . $datetime . " ##########\n\n";
}

1; # End of Roccaku::Generate_Code;
