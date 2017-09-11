#!/usr/bin/expect

set timeout 20
set password [lindex $argv 0]
spawn /usr/sbin/realm join  -U join_ad@DOMAIN.COM server.com --verbose
expect "DOMAIN.COM:"
send "$password\r";
interact
