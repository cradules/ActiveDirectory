#!/usr/bin/expect

set timeout 20
set password [lindex $argv 0]
spawn /usr/bin/kinit join-ad@DOMAIN.COM
expect "DOMAIN.COM"
send "$password\r";
interact
