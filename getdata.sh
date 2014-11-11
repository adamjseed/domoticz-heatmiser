#!/usr/bin/expect
set timeout 10
set ip [lindex $argv 0];
set port [lindex $argv 1];
log_file [lindex $argv 2];
spawn telnet $ip $port
expect "'^]'." 
sleep .1
send "{\"INFO\":0}\0\r"
expect "}]}"
send "\35"
expect "telnet>"
send "q\r"
interact

