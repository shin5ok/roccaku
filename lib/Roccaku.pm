package Roccaku;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Roccaku - The great new Roccaku!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


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
use YAML;
use Carp;

sub new {
  my ($class, $config_path, $option) = @_;

  if (not defined $config_path) {
    croak "config_path must be given";
  }

  my $obj = bless {
              test_only   => undef,
              debug       => 0,
              run_objects => [],
              config_path => $config_path,
            }, $class;

  {
    no strict 'refs';
    $obj->debug( $option->{debug} );
  }

  $obj->parse;
  return $obj;

}

sub parse {
  my ($self) = @_;

  my $config;
  local $@;
  eval {
    $config = YAML::LoadFile( $self->{config_path} );
    warn Dumper $config if $self->debug;
  };
  if ($@) {
    croak "$self->{config_path} cannot be read($@)";
  }

  my @objects;
  for my $c ( @$config ) {
    my ($name, $value) = each %$c;
    my $module_name      = ucfirst $name;
    my $full_module_name = qq{Roccaku::Run::} . $module_name;
    {
      local $@;
      eval qq{use $full_module_name};
      if ($@) {
        croak "$full_module_name was load failure($@)";
      }
    }
    push @objects, $full_module_name->new( $value );
  }

  warn Dumper \@objects if $self->debug;

  $self->{run_objects} = \@objects;
  return $self;
}

sub run {

}

sub test_only {
  my ($self, $flag) = @_;
  if (@_ == 2) {
    $self->{debug} = $flag;
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
