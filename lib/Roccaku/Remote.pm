package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use File::Find;
use File::Basename;
use FindBin;
use lib qq($FindBin::Bin/../lib);

our $code = qq{};

sub run {
  my ($self) = @_;

  $code ||= get_datetime_comment();

  my $lib_path = dirname ( File::Spec->rel2abs( __FILE__ ) );
  find( \&generating_code, "$lib_path/../" );

  $code .= "1;\n";

}

sub generating_code {
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

sub get_datetime_comment {
  my $datetime = strftime "%Y-%m-%d %H:%M:%S", localtime;
  "########## " . $datetime . " ##########\n\n";
}

1; # End of Roccaku::Remote;
