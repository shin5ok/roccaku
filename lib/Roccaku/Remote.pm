package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use File::Find;
use FindBin;
use lib qq($FindBin::Bin/../lib);

our $code = qq{};

sub run {
  my ($self) = @_;

  my $lib_path = qq($FindBin::Bin/../lib);
  find( \&compiling_code, $lib_path );

  warn $code;

}

sub compiling_code {
  my $f = $File::Find::name;
  (-f $f and $f =~ /\.pm$/) or return;
  open my $fh, "<", $f
    or return;
  while (my $line = <$fh>) {
    $line =~ m{^1\s*\;\s*\#} and next;
    $line =~ m{\s?(?:use|require)\s+Roccaku} and next;
    $line =~ s{Roccaku}{Roccaku_x}g;
    $code .= $line;
  }
  $code .= "\n";
  close $fh;
  return;
}

1; # End of Roccaku::Remote;
