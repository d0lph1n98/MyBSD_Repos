#!/bin/sh
#
# vim:sw=2 ts=8:et sta
#
#
# Copyright (c) 1999, 2000, 2001, 2002, 2003 Ariff Abdullah 
#        (skywizard@MyBSD.org.my) All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#        $MyBSD: src/gelojoh/gelojoh.sh,v 1.2 2004/05/16 14:17:35 skywizard Exp $
#
# Date: Sat Jun 28 12:15:13 MYT 2003
#   OS: FreeBSD TOMOYO.MyBSD.ORG.MY 4.6.2-RELEASE i386
#
# Sample rc.d startup script
#

#
# EDIT! EDIT! EDIT!
#
gelojoh="/usr/local/gelojoh/gelojoh.rb"
conf="/usr/local/gelojoh/gelojoh.conf"
pidf="/var/run/gelojoh.pid"
ruby="/usr/local/bin/ruby18"

if [ `/usr/bin/id -u` != 0 ]; then
  echo "Sorry, must run as root."
  exit 1
fi

case "$1" in
  start)
    if [ -f "$pidf" ]; then
      echo 'Gelojoh already running?'
      exit 1
    fi
    "$ruby" -w "$gelojoh" "$conf"
    echo -n ' Gelojoh'
    ;;
  stop)
    if [ ! -f "$pidf" ]; then
      echo 'Gelojoh not running?'
      exit 1
    fi
    kill -15 `cat "$pidf"` > /dev/null 2>&1
    rm -f "$pidf"
    echo -n ' Gelojoh'
    ;;
  restart|reload)
    $0 stop > /dev/null 2>&1
    sleep 1
    $0 start
    ;;
  *)
    echo "Usage: ${0##*/} <start|stop|restart|reload>"
    exit 1
    ;;
esac

exit 0
