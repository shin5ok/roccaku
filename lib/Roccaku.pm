package Roccaku;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Roccaku - The great new Roccaku!

=head1 VERSION

Version 0.95

=cut

our $VERSION = '0.95';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Roccaku;

    my $foo = Roccaku->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

use Data::Dumper;
use Carp;
use FindBin;
use lib (qq($FindBin::Bin/../lib), qq($FindBin::Bin/../extlib));
use Roccaku::Utils;
use JSON::PP;

our $__GEN_SORT = 10;

local $SIG{INT} = sub { kill 15, 0 };

sub new {
  my ($class, $config_path, $option) = @_;

  if (not defined $config_path) {
    croak "config_path must be given";
  }

  my $obj = bless {
              test_only   => undef,
              api_mode    => undef,
              debug       => 0,
              run_objects => [],
              env         => undef,
              config_path => $config_path,
              argv        => +{},
            }, $class;

  {
    no strict 'refs';
    $obj->debug( $option->{debug}       );
    $obj->argv_parser( $option->{argv}  );
    $obj->api_mode( $option->{api_mode} );
  }

  $obj->parse;
  return $obj;

}

sub _template_render {
  my $self = shift;
  my $path = shift;

  my $data;
  if ($path ne q{DATA}) {
    open my $fh, "<", $path
      or croak "$path cannot open";
    $data = do { local $/; <$fh> };
  } else {
    no warnings;
    $data = do { local $/; <DATA>; };
  }

  my $argv = $self->argv;

  while (my ($key, $value) = each %$argv) {
    $data =~ s{%%$key%%}{$value}g;
  }

  return $data;
}

sub parse {
  my ($self) = @_;

  my $config;
  {
    local $@;
    eval {
      require YAML;
      $config = YAML::Load( $self->_template_render( $self->{config_path} ) );
    };
    if ($@ or ! defined $config) {
      local $@;
      eval {
        require YAML::Tiny;
        my $ref  = YAML::Tiny->read_string( $self->_template_render( $self->{config_path} ) );
        $config = $ref->[0];
      };
      if ($@ or ! defined $config) {
        croak "$self->{config_path} cannot be read($@)";
      }
    }
    if ($self->debug) {
      local $Data::Dumper::Terse = 1;
      warn "####### config from yaml ###################";
      warn Dumper $config                                ;
      warn "############################################";
    }
  }

  {
    require Roccaku::Env;
    no strict 'refs';
    $self->{env} = Roccaku::Env->new( $config->{env} );
  }

  {
    require Roccaku::Value;
    no strict 'refs';
    $self->{value} = Roccaku::Value->new( $config->{value} );
  }

  my %object_hash;
  while (my ($key, $x) = each %{$config->{run}}) {
    my @objects;
    for my $c (@$x) {
      my $hash_ref = +{};
      for my $name (keys %$c) {
        my $value = $c->{$name};
        my $module_name      = ucfirst $name;
        my $full_module_name = qq{Roccaku::Run::} . $module_name;

        {
          local $@;
          eval qq{use $full_module_name};
          if ($@) {
            croak "$full_module_name was load failure($@)";
          }
          $hash_ref->{$name} = $full_module_name->new( $value, { debug => $self->debug } );
        }
      }
      push @objects, $hash_ref;
    }
    $object_hash{$key} = \@objects;
  }

  $self->{run_objects} = \%object_hash;

  return $self;

}

sub run {
  my $self   = shift;
  my $params = shift;

  my @results;
  my $fail_count = 0;

  my $flag = q{main};

  my $run_objects = $self->{run_objects};
  my $remote_r;
  if (defined $params->{host}) {
    # If defined host, run() method exec on remote host
    local $@;
    my $r;
    require Roccaku::Remote;
    eval {
      my $remote_params;
        %$remote_params = %$params;
        my $host         = delete $remote_params->{'host'};
        my $install_perl = delete $remote_params->{'install-perl'};
        warn Dumper { remote_params => $remote_params } if $self->debug;

      $remote_r = Roccaku::Remote::run(
                                        $host,
                                        $remote_params,
                                        {
                                          env          => $self->{env}->env_string,
                                          install_perl => $install_perl,
                                        }
                                      );
    };

    if ($@) {
      warn $@;
      croak "Remote exec aborted...";
    }

    $flag = q{local};
    {
      require Roccaku::Run::Say;
      $Roccaku::Run::Say::SAY_NUMBER = @{$remote_r->{results}};
    }
  }

  my $test_only = $self->test_only;

  $Roccaku::Run::Base::COMMAND_ENV   = $self->{env}->env_string;
  $Roccaku::Run::Base::COMMAND_VALUE = $self->{value}->value;

  for my $ref ( @{$run_objects->{$flag}} ) {
    my $result = +{ comment => q{}, fail => { must => [], do => [] } };
    my $comment;
    if (exists $ref->{say}) {
      my $say = $ref->{say};
      $comment = $say->run;
    } else {
      require Roccaku::Run::Say;
      $comment = Roccaku::Run::Say->new( "(Next process)" )->run;
    }
    $result->{comment} = $comment;

    my $is_skip;
    if (exists $ref->{skip_if}) {
      my $skip = $ref->{skip_if};
      $skip->run;

      if ($skip->fail > 0) {
        $is_skip = 1;
      }
    }

    if (exists $ref->{skip_if_not}) {
      my $skip = $ref->{skip_if_not};
      $skip->run;

      if ($skip->fail > 0) {
        $is_skip = 1;
      }
    }

    if (! $is_skip) {

      if (exists $ref->{must} or $ref->{must_not}) {
        my $must = $ref->{must} || $ref->{must_not};
        $must->run;
        $must->add_number;
        my $is_must = 1;
        if ((my @fails = $must->fail) > 0) {
          $is_must = 0;
          push @{$result->{fail}->{must}}, @fails;
          $fail_count += @fails;
        }

        if (not $is_must and exists $ref->{do} and not $self->test_only) {
          my $do = $ref->{do};
          $do->run;
          if (my @fails = $do->fail > 0) {
            push @{$result->{fail}->{do}}, @fails;
            $fail_count += @fails;
          }
        }
      }
    } else {
      warn "\tskipping...", "\n";

    }
    push @results, $result;
  }

  my $ok = 0;
  if ( $remote_r ) {
    if ($remote_r->{ok} and $fail_count == 0) {
      $ok = 1;
    }
  } else {
    $ok = 1 if $fail_count == 0;
  }

  require Roccaku::Result;
  return Roccaku::Result->new( +{ ok => $ok, results => \@results } );

}

sub api_mode {
  my ($self, $flag) = @_;
  if (@_ == 2) {
    $self->{api_mode} = $flag;
  }

  return $self->{api_mode};

}

sub test_only {
  my ($self, $flag) = @_;
  if (@_ == 2) {
    $self->{test_only} = $flag;
  }

  return $self->{test_only};

}

sub debug {
  my ($self, $flag) = @_;
  if (@_ == 2) {
    $self->{debug} = $flag;
  }

  return $self->{debug};

}

sub argv {
  my $self = shift;
  my $ref  = shift;

  if (defined $ref and ref $ref eq q{HASH}) {
    $self->{argv} = $ref;
  }

  {
    warn "## argv"            if $self->debug;
    warn Dumper $self->{argv} if $self->debug;
  }

  return $self->{argv};

}

sub argv_parser {
  my ($self, $argv) = @_;

  $argv or return;

  my %argv_hash;
  {
    for my $v (split /,/, $argv) {
      my ($key, $value) = $v =~ /([^\=]+)\s*\=\s*(.+)/;
      eval { $argv_hash{$key} = $value };
    }
  }

  $self->argv( \%argv_hash );

  return %argv_hash;

}

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 shin5ok.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Roccaku
