use strict;
use warnings;

package Roccaku::File;

=pod
 Roccaku::File::get_data( file_path, { as => 0|1, map => \%map });
=cut

sub get_data {
  goto \&_get_data;
}

sub _get_data {
  my $file   = shift;
  my $option = shift || {};
  if ($file =~ m{^([^:]+):(/.+)}) {
    require Roccaku::Env;
    my $env_path = Roccaku::Env::_get_wrapper_path();
    local $?;
    my @datas = qx{PATH=$env_path:$ENV{PATH} ssh $1 cat $2};
    {
      no strict 'refs';
      if ($option->{as}) {
        
      }
    }
    return qq{} if $? != 0;
    return join "", @datas;
  } else {
    open my $fh, "<", $file
      or return qq{};
    my @datas = <$fh>;
    return join "", @datas;
  }
}

1;
