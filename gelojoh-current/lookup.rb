#!/usr/local/bin/ruby -w
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
#        $MyBSD: src/gelojoh/lookup.rb,v 1.2 2003/12/27 21:15:41 skywizard Exp $
#
# Date: Wed Jun  4 21:47:09 MYT 2003
#   OS: FreeBSD kasumi.MyBSD.org.my 4.7-RELEASE i386
#
#
#  Simple ipv4/ipv6 capability lookup.
#

require 'socket'

AF_V4 = Socket::AF_INET
if defined?(Socket::AF_INET6)
  AF_V6 = Socket::AF_INET6
else
  AF_V6 = nil
end

Socket.do_not_reverse_lookup = true

addr = Socket.getaddrinfo(
    ARGV[0] || "0.0.0.0", (ARGV[1] || 80).to_i,
    Socket::PF_UNSPEC, Socket::SOCK_STREAM,
    nil, Socket::AI_PASSIVE
)

v4 = []
v6 = []

addr.each do |strfamily, port, host, ip, family, bleh, blah|
  if family == AF_V4
    v4.push([host, ip])
  elsif family == AF_V6 && !AF_V6.nil?
    v6.push([host, ip])
  else
    print "Warning: Unknown family type #{strfamily} : #{family}\n"
  end
end

unless v4.empty?
  print "IPv4 Capability:\n"
  print "---------------\n"
  v4.each do |host, ip|
    if host == ip
      print "        IP: #{ip}\n"
    else
      print "  Hostname: #{host}\n"
      print "        IP: #{ip}\n"
    end
  end
end
unless v6.empty?
  print "\n" unless v4.empty?
  print "IPv6 Capability:\n"
  print "---------------\n"
  v6.each do |host, ip|
    if host == ip
      print "        IP: #{ip}\n"
    else
      print "  Hostname: #{host}\n"
      print "        IP: #{ip}\n"
    end
  end
end
