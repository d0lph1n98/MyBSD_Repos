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
#        $MyBSD: src/gelojoh/confparser.rb,v 1.7 2004/05/20 17:21:06 skywizard Exp $
#
# Date: Sun Jun 29 01:01:54 MYT 2003
#   OS: FreeBSD kasumi.MyBSD.org.my 4.7-RELEASE i386
#

require 'socket'

class HttpVhost
  def initialize(host)
    @host = host
  end
  attr_accessor :host, :path, :docindex, :servertag
end

def cleanup_str(str)
  str.strip!
  if /^\"(.+)\"$/ =~ str
    str.replace($1)
  elsif /^'(.+)'$/ =~ str
    str.replace($1)
  end
  str
end

def gelojoh_conf_parse(file)
  ret = {
    :listen => [],
    :docroot => nil,
    :docindex => {
      :ipv4 => [],
      :ipv6 => []
    },
    :aliases => [],
    :mime_file => nil,
    :max_client => 50,
    :max_listen => 25,
    :keep_alive_timeout => 15,
    :keep_alive_max => 100,
    :vhosts => {},
    :runas => 'nobody',
    :servertag => nil,
    :ssl_cert => nil,
    :ssl_key => nil,
    :logfile => nil,
    :pidfile => nil,
    :daemon => false,
    :blocksize => 1 << 12
  }
  in_vhost = nil
  defhost = HttpVhost.new('localhost')
  File.foreach(file) do |line|
    next if line =~ /^\s*\#/
    line.sub!(/\#.*$/, '')
    line.strip!
    next if line.empty?
    case line
      when /^Listen(SSL)?\s+(.+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        use_ssl = $1 ? true : false
        ary = $2.split(/\//)
        raise ArgumentError, "Line error: Listen : #{line}" unless ary.size() < 4
        addr, port, family = ary
        addr.strip! if addr
        port.strip! if port
        family.strip! if family
        case addr
          when /^\d+\.\d+\.\d+\.\d+$/
            port ||= "80"
            family ||= "ipv4"
            raise ArgumentError, "Invalid port" unless port =~ /^\d+$/
            raise ArgumentError, "Family type not match (should be IPv4)" unless family =~ /^ipv4$/i
          when /:/
            raise ArgumentError, "IPv6 stack not implemented on this platform" unless defined?(Socket::AF_INET6)
            port ||= "80"
            family ||= "ipv6"
            raise ArgumentError, "Invalid port" unless port =~ /^\d+$/
            raise ArgumentError, "Family type not match (should be IPv6)" unless family =~ /^ipv6$/i
          when /^\d+$/
            family = port || "ALL"
            port = addr
            addr = nil
            raise ArgumentError, "Invalid port" unless port =~ /^\d+$/
            raise ArgumentError, "Family type unknown \"#{family}\"" unless family =~ /^ipv4|ipv6|all$/i
          when /\w/
            port ||= "80"
            family ||= "ALL"
            raise ArgumentError, "Invalid port" unless port =~ /^\d+$/
            raise ArgumentError, "Family type unknown \"#{family}\"" unless family =~ /^ipv4|ipv6|all$/i
        else
          raise ArgumentError, "Error parsing Listen directive \"#{line}\""
        end
        ret[:listen].push(:addr => (addr ? addr.strip() : addr), :port => port.strip.to_i, :family => family.strip.downcase.to_sym(), :ssl => use_ssl)
      when /^DocumentRoot\s+(.+)$/i
        STDERR.puts "WARNING: Directory \"#{$1}\" not exist!" unless File.directory?($1)
        if in_vhost
          in_vhost.path = $1.strip()
        else
          ret[:docroot] = $1.strip()
        end
      when /^Alias\s+(.+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        path_alias, path_target = $1.strip.split(/\s+/, 2)
        raise ArgumentError, "Error parsing Alias directive \"#{line}\"" unless path_alias && path_target
        ret[:aliases].push([path_alias, path_target])
      when /^DocumentIndex(4|6)?\s+(.+)$/i
        family = $1
        data = $2.strip.split(/\s+/)
        if in_vhost
          if in_vhost.docindex
            docindex = in_vhost.docindex
          else
            docindex = {
              :ipv4 => [],
              :ipv6 => []
            }
            in_vhost.docindex = docindex
          end
        else
          docindex = ret[:docindex]
        end
        if family
          docindex[(family == "6" ? :ipv6 : :ipv4)] = data
        else
          docindex[:ipv4] = docindex[:ipv6] = data
        end
      when /^MimeTypes\s+(.+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        ret[:mime_file] = cleanup_str($1)
      when /^KeepAliveTimeout\s+(\d+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        ret[:keep_alive_timeout] = $1.to_i
      when /^KeepAliveMax\s+(\d+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        ret[:keep_alive_max] = $1.to_i
      when /^MaxClient\s+(\d+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        ret[:max_client] = $1.to_i
      when /^MaxListen\s+(\d+)$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        ret[:max_listen] = $1.to_i
      when /^Host\s+(.+)$/i
        defhost.host = $1
      when /^Vhost\s+([^\s]+)\s+(.+)/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        host = $1.dup()
        path = $2.dup()
        [host, path].each do |ent|
          cleanup_str(ent)
        end
        if /:/ =~ host
          # XXX IPv6 explicit vhost
          host.replace("[#{host}]")
        end
        in_vhost = HttpVhost.new(host)
        in_vhost.path = path
        ret[:vhosts][host.upcase()] = in_vhost
        in_vhost = nil
      when /^<Vhost ([^>]+)>\s*$/i
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        in_vhost = HttpVhost.new(cleanup_str($1))
      when /^<\/Vhost>\s*$/i
        if in_vhost
          in_vhost.host.split(/\s+/).each do |vh|
            vhost = in_vhost.dup()
            vhost.host = vh
            ret[:vhosts][vh.upcase()] = vhost
          end
          in_vhost = nil
        else
          raise ArgumentError, "Unmatched '</Vhost>'"
        end
      when /^RunAs\s+(.+)$/
        raise ArgumentError, "Invalid Vhost directive: #{line}" if in_vhost
        ret[:runas] = cleanup_str($1)
      when /^ServerTag\s+(.+)$/i
        tag = cleanup_str($1)
        if in_vhost
          in_vhost.servertag = tag
        else
          ret[:servertag] = tag
        end
      when /^SSLCertificate\s+(.+)$/i
        ret[:ssl_cert] = cleanup_str($1)
      when /^SSLKey\s+(.+)$/i
        ret[:ssl_key] = cleanup_str($1)
      when /^LogFile\s+(.+)$/i
        ret[:logfile] = cleanup_str($1)
      when /^PidFile\s+(.+)$/i
        ret[:pidfile] = cleanup_str($1)
      when /^Daemon\s+(.+)$/
        case $1.upcase()
          when 'Y', 'YES', 'TRUE', 'ON', 'ENABLE'
            ret[:daemon] = true
        end
      when /^BlockSize\s+((\-\s*)?\d+(\s*<<\s*\d+)?)$/i
        ret[:blocksize] = $3 ? eval($1) : $1.to_i
    else
      raise ArgumentError, "Unknown/Invalid directive: #{line}"
    end
  end
  raise ArgumentError, "Unmatched '</Vhost>'" if in_vhost
  defhost.path = ret[:docroot]
  defhost.docindex = ret[:docindex]
  defhost.servertag = ret[:servertag]
  ret[:vhosts].default = defhost
  ret
end

if __FILE__ == $0
  printed = false
  gelojoh_conf_parse(ARGV[0] || "gelojoh.conf.sample").each do |key, val|
    puts "" if printed
    puts key
    print "-"*key.to_s.size(), "\n"
    p val
    printed = true
  end
end
