package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use FindBin;
use File::Spec;
use File::Basename;
use lib qq($FindBin::Bin/../lib);

use Roccaku::Utils;

our $sudo = qq{};

our $temporary_working_base = q{/var/tmp};

sub run {
  my ($host, $command_argv) = @_;

  # It's mine...not remote!
  is_this_me($host) and return;

  my $temporary_working_dir = _gen_working_dir();
  my $path = exists $ENV{ROCCAKU_ROOT_PATH}
           ? $ENV{ROCCAKU_ROOT_PATH}
           : qq{$ENV{HOME}/roccaku};

  my $scp = "scp -r -q $path/ $host:$temporary_working_dir/";
  my $run = sprintf "ssh %s $sudo %s/bin/roccaku %s",
                     $host,
                     $temporary_working_dir,
                     ( join " ", @$command_argv, '--api' );
  my $rmd = "ssh $host rm -Rf $temporary_working_dir";

  my @cmds;
  push @cmds, ( qq{$scp}, qq{$run}, qq{$rmd} );
  push @cmds, ( qq{$scp}, qq{$run} );

  for my $cmd ( @cmds ) {
    local $?;
    system $cmd;
    my $r = $? == 0
          ? "ok"
          : "ERROR";

    logging "$r: $cmd", 1;
  }
}

sub _gen_working_dir {
  my $uuid = `uuidgen 2> /dev/null`;
  chomp $uuid;
  $uuid ||= strftime "%Y%m%d%H%M%S", localtime;
  sprintf "%s/.%s_%s", $temporary_working_base, ( basename __FILE__) , $uuid;
}

sub is_this_me {
  my ($host) = @_;

  my $server_info = server_info();
  for my $info (keys %$server_info) {
    my $value = $server_info->{$info};
    if (ref $value eq q{ARRAY}) {
      for my $v (@$value) {
        $v eq $host and return 1;
      }
    } else {
      $value eq $host and return 1;
    }
  }
  return 0;
}

1; # End of Roccaku::Say;
