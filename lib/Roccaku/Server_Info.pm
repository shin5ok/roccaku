package Roccaku::Server_Info;

use 5.006;
use strict;
use warnings FATAL => 'all';

use FindBin;
use Carp;
use Data::Dumper;
use Sys::Hostname;

our $cache;
our $info = {};

sub new {
  my ($class, $server) = @_;
  bless {
    server => $server || hostname,
  }, $class;
}

sub gather {
  my ($self) = @_;
  return $self->_gather_info;
}

sub info {
  my $self = shift;
  if (! exists $cache->{$self->{server}}) {
    $cache->{$self->{server}} = $self->gather;
  }
  return $cache->{$self->{server}};
}

sub _gather_info {
  +{
    hostname => hostname,
    network  => _get_network(),
  }
}

# eth0      Link encap:Ethernet  HWaddr 00:16:3E:18:01:0B
#           inet addr:10.113.24.11  Bcast:10.113.24.255  Mask:255.255.255.0
#           inet6 addr: fe80::216:3eff:fe18:10b/64 Scope:Link
#           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
#           RX packets:41682800 errors:0 dropped:0 overruns:0 frame:0
#           TX packets:27826164 errors:0 dropped:0 overruns:0 carrier:0
#           collisions:0 txqueuelen:1000
#           RX bytes:4359055303 (4.0 GiB)  TX bytes:282217399422 (262.8 GiB)
# 
# eth1      Link encap:Ethernet  HWaddr 00:16:3E:18:11:0B
#           inet addr:10.114.24.11  Bcast:10.114.24.255  Mask:255.255.255.0
#           inet6 addr: fe80::216:3eff:fe18:110b/64 Scope:Link
#           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
#           RX packets:253456871 errors:0 dropped:0 overruns:0 frame:0
#           TX packets:68605340 errors:0 dropped:0 overruns:0 carrier:0
#           collisions:0 txqueuelen:1000
#           RX bytes:309409200125 (288.1 GiB)  TX bytes:11095323970 (10.3 GiB)

sub _get_network {
  my @ifconfigs = `/sbin/ifconfig -a`;
  my $index = 0;
  my %network;
  my ($name, $ip, $mask, $ip6);
  for my $if ( @ifconfigs ) {
    if ($if =~ m{^(\S+)}) {
      if ($1 ne q{lo}) {
        $name = $1;
      }
    }

    if ($name) {
    
      if ($if =~ /
                   inet\s+addr:\s*(\S+)\s+
                   Bcast:\s*\S+\s+
                   Mask:\s*(\S+)
                 /xoms) {
        $ip   = $1;
        $mask = $2;
        next;
      }

      if ($if =~ /
                   inet6\s+addr:\s*(\S+)
                 /xoms) {
        $ip6 = $1;
        next;
      }

      if ($if =~ /^\s*\n/) {
        $network{$name} = {
                             index => $index,
                             name  => $name,
                             ipv4  => {
                                        ip   => $ip,
                                        mask => $mask,
                                      },
                             ipv6  => {
                                        ip => $ip6
                                      },
                            };
        $index++;
        ($name, $ip, $mask, $ip6) = (undef, undef, undef, undef);
      }
    }
  }
  return \%network;
}

1; # End of Roccaku::Server_Info;
