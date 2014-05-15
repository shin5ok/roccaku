package Roccaku::Remote;

use 5.006;
use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use Carp;
use FindBin;
use File::Spec;
use File::Basename;
use lib (qq($FindBin::Bin/../lib), qq($FindBin::Bin/../extlib));
use JSON::PP;

use Roccaku::Utils;

our $sudo = qq{};

our $temporary_working_base = q{/var/tmp};

sub run {
  my ($host, $params, $option) = @_;

  if (not defined $host) {
    croak "host not defined";
  }

  my $env          = $option->{env};
  my $install_perl = $option->{install_perl};

  can_do_remote( $host );

  # It's mine...not remote!
  # is_this_me($host) and return +{};
  is_this_me($host) and croak "This host is me";

  my $temporary_working_dir = _gen_working_dir();

  my $config_path  = "$temporary_working_dir/config.yaml";
  my $store_path   = sprintf "$temporary_working_dir/%s", config->{result_name};
  my $command_args = _build_args( $params, {
                                             "config-path" => $config_path,
                                             "is-remote"   => 1,
                                             "store-path"  => $store_path,
                                            } );
  logging $command_args, undef;

  my $path = exists $ENV{ROCCAKU_ROOT_PATH}
           ? $ENV{ROCCAKU_ROOT_PATH}
           : qq{$ENV{HOME}/roccaku};

  # !!!!! for now, temporary code !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  local $| = 1;
  my $scp1 = "scp -r -q $path/ $host:$temporary_working_dir/";
  my $scp2 = "scp -r -q $params->{'config-path'} ${host}:$config_path";
  my $run  = sprintf qq{ssh %s %s %s/bin/roccaku %s},
                     $host,
                     $env,
                     $temporary_working_dir,
                     $command_args;
  my $json = sprintf "ssh %s $sudo cat %s/%s",
                     $host,
                     $temporary_working_dir,
                     config->{result_name};
  my $rmd  = "ssh $host rm -Rf $temporary_working_dir";

  # 近いうちに、can_do_remote() に入れる
  {
    my $do_try = 1;
    do {
      # require a perl
      local $?;
      my $version = qx{ssh $host perl -v};
      if ($? != 0) {
        $do_try = 0;
        if (defined $install_perl) {
          my $pre = sprintf "ssh %s %s '%s'", $host, $env, $install_perl;
          warn "\tTry installing perl", "\n";
          system $pre . " > /dev/null";
        }
        croak "perl interpreter is not found.\nRoccaku require a perl, You have to install perl.";
      } else {
        last;
      }
    } while ($do_try);
  }

  system $scp1;
  system $scp2;
  system $run;
  my $output = qx{$json};
  system $rmd;
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  return decode_json $output;

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

sub _build_args {
  my $hash_ref = shift;
  my $argv     = shift || {};

  my $command_args = "";
  my %cp_hash_ref = %$hash_ref;
  %cp_hash_ref = (%cp_hash_ref, %$argv);
  while (my ($k, $v) = each %cp_hash_ref) {
    $command_args .= sprintf "--%s %s ",
                             $k,
                             defined $v
                             ? $v
                             : qq{};
  }

  return $command_args;

}

sub can_do_remote {
  require Roccaku::Remote::SSH;
  goto \&Roccaku::Remote::SSH::run;
}

1; # End of Roccaku::Say;
