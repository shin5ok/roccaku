#Roccaku
###サーバテスト、設定ツール
超シンプル、プログラミングの知識なしで利用できます  
Chef、ansible、serverspec が難しいひと向け
###必要な知識、スキル
- シェルコマンド（戻り値）
- YAML（基礎）
のみ
###利用に必要なもの
- Perl5.8以上  
  標準モジュールのみ

###利用例
- テストモード
$ sudo roccaku -c ./basic-server.yml --host webserver001 --test-only   
- テスト & 設定モード
$ sudo roccaku -c ./basic-server.yml --host webserver001
basic-server.yml(設定サンプル)

```
---
env:
LANG: C
PATH: /sbin:/usr/sbin:/bin:/usr/bin
http_proxy: http://192.168.232.11:3128

run:
  main:
    - must:
       file:
         path: /etc/sysconfig/network
         pattern:
           - "^HOSTNAME\=%%HOSTNAME%%"
      say: hostname config check
      do:
        file:
          path: /etc/sysconfig/network
          rewrite:
            replace:
              pre_pattern: "^HOSTNAME\=.*"
              post_string: "HOSTNAME=%%HOSTNAME%%\n"

    - must:
        - rpm -qa | grep postfix
      do:
        - yum -y install postfix
      say: postfix installed

    - must:
        - ps ax | grep postfix/master | grep -v grep
      do:
        - service postfix start
      say: postfix running

    - must: chkconfig --list | grep 3:on | grep postfix
      do: chkconfig postfix on
      say: postfix is ready to start

    - must:
        file:
          path: /etc/postfix/main.cf
          pattern:
            - "^relayhost\s*\=\s*\[192\.168\.232\.10\]\n"
      do:
        file:
          path: /etc/postfix/main.cf
          rewrite:
            - add: "relayhost = [192.168.232.10]\n"
              after: '^setgid_group'
              before: '^readme_directory'
      say: postfix main.cf is configured for relayhost

    - must:
        file:
          path: /etc/postfix/main.cf
          pattern:
            - "^transport_maps"
      do:
        file:
          path: /etc/postfix/main.cf
          rewrite:
            - add: "transport_maps = hash:/etc/postfix/transport\n"
              before: '^html_directory'
      say: postfix main.cf is configured for transport

    - must: rpm -qa | grep munin-node | grep -v grep
      do: yum -y install munin-node
      say: munin-node installed

    - must: test -f /etc/cron.d/ntpdate
      say: ntp cron setup
      do:
        file:
          path: /etc/cron.d/ntpdate
          create:
            group: root
            owner: root
            mode: 0644
          rewrite:
            add: "*/10 * * * * root /usr/sbin/ntpdate -s 192.168.232.10 && /sbin/clock -w\n"

    - must: test -x /usr/sbin/ntpdate
      do:
        - yum -y install ntp
        - ntpdate -s 192.168.232.10
      say: ntpdate installed

    - must:
        file:
          path: /etc/munin/munin-node.conf
          pattern:
            - "^cidr_allow\s+192\.168\.0\.0/16$"
      do:
        - file:
            path: /etc/munin/munin-node.conf
            rewrite:
              add: "cidr_allow 192.168.0.0/16\n"
              before: "^#\scidr_allow"
        - command: /etc/init.d/munin-node restart
      say: munin-node.conf cidr_allow

    - say: selinux check
      must:
        - grep '^SELINUX=disabled' /etc/selinux/config
        # - getenforce | grep -i ^disabled
      do:
        file:
          path: /etc/selinux/config
          rewrite:
            replace:
              pre_pattern: "^SELINUX=enforcing"
              post_string: "SELINUX=disabled\n"

    - say: kernel parameter config
      must:
        file:
          path: /etc/sysctl.conf
          pattern:
            - "^vm\.swappiness\s*\=\s*10$"
      do:
        file:
          path: /etc/sysctl.conf
          rewrite:
            - add: "vm.swappiness = 10\n"
        command: sysctl -a

    - say: kernel parameter runtime
      must: sysctl -p | grep '^vm\.swappiness \= 10'

    - say: routing check conf
      must:
        file:
          path: /etc/sysconfig/network
          pattern: "^GATEWAY\=192.168.23[32].1"
      do:
        file:
          path: /etc/sysconfig/network
          rewrite:
            replace:
              pre_pattern: "^GATEWAY\=.*"
              post_string: "GATEWAY=192.168.232.1\n"
            add: "GATEWAY=192.168.232.1"

    - say: routing check runtime
      must: netstat -rn | grep ^0.0.0.0 | grep ' 192\.168\.23[32]\.1 '

    - say: user check
      must:
        - grep ^kawano       /etc/passwd

    - say: home directory check
      skip:
        - command: grep ^kawano: /etc/passwd
      must:
        - test -d /home/kawano
      do:
        - cp -a /etc/skel /home/kawano      ; chown -R kawano.admin_group /home/kawano

    - say: group check
      must:
        - 'grep ^admin_group: /etc/group'

      do:
        - command: /usr/sbin/groupadd -g 101 admin_group

    - say: perl modules
      must:
        command: /usr/bin/perl -MIPC::Cmd -e 1
      do:
        command: yum -y install perl-IPC-Cmd

    - say: aliases check
      must:
        - db_dump -p /etc/aliases.db | grep '^ root'
        - db_dump -p /etc/aliases.db | grep '^ managed\-system\@example.com'
      do:
        - file:
            path: /etc/aliases
            rewrite:
              remove: "^root:"
              add: "root: managed-system@example.com\n"
        - command: newaliases

    - say: rsyslog.conf check
      must:
        file:
          path: /etc/rsyslog.conf
          pattern: "^local0\.\*.+/murakumo_node_api\.log"
      do:
        - file:
            path: /etc/rsyslog.conf
            rewrite:
              add: "local0.*     /var/log/murakumo_node_api.log\n"
              before: "^local7\."
        - command: /etc/init.d/rsyslog restart

    - say: iptables check
      must_not:
        - /sbin/iptables -nL | grep ^REJECT | grep -v grep
        - /sbin/iptables -nL | grep ^ACCEPT | grep -v grep
      do:
        - chkconfig --del iptables
        - rm -f /etc/libvirt/qemu/networks/autostart/default.xml
        - service libvirtd restart
        - service iptables stop

    - say: resolv conf
      must:
        file: 
          path: /etc/resolv.conf
          pattern:
            - "^nameserver\s+192\.168\.232\.12$"
            - "^nameserver\s+192\.168\.232\.13$"
      do:
        - file:
            create:
              mode: 0664
              owner: root
              group: sys
            path: /etc/resolv.conf
            rewrite:
              - add: "nameserver 192.168.232.12\n"
              - add: "nameserver 192.168.232.13\n"

  local:
    - say: local check dummy
      must:
        - command: true
      do:
        - command: true
```