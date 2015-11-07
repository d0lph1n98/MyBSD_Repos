#!/usr/bin/env ruby -w
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
#        $MyBSD: src/gelojoh/gelojoh.rb,v 1.22 2005/01/22 09:21:12 skywizard Exp $
#
# Date: Wed Jun  4 21:47:09 MYT 2003
#   OS: FreeBSD kasumi.MyBSD.org.my 4.7-RELEASE i386
#

GELOJOH_BASE_DIR = File.dirname(__FILE__)
$:.unshift(GELOJOH_BASE_DIR)
require 'socket'
require 'ioutil'
require 'core'
require 'confparser'
require 'cgi-lib'

Socket.do_not_reverse_lookup = true

IS_WIN32 = (RUBY_PLATFORM =~ /(mingw|mswin)32/i) ? true : false

# cheap/stupid/lame/wtf trick for win32
if IS_WIN32
  module Errno
    ECONNRESET = EINVAL unless defined?(ECONNRESET)
    ECONNABORTED = EINVAL unless defined?(ECONNABORTED)
    ENOTCONN = EINVAL unless defined?(ENOTCONN)
  end
end

module HttpError
  TITLE = {
    200 => "OK",
    206 => "Partial Content",
    301 => "Moved Permanently",
    302 => "Found",
    400 => "Bad Request",
    403 => "Forbidden",
    404 => "Not Found",
    413 => "Request URI Too Long",
    416 => "Requested Range Not Satisfiable",
    501 => "Method Not Implemented"
  }
  TITLE.default = "Unknown Error Code"
  class Base < StandardError
    HAS_BODY = true
    TERMINATE = false
    def has_body?
      self.class::HAS_BODY
    end
    def terminate?
      self.class::TERMINATE
    end
  end
  class OK < Base # 200
  end
  class PartialContent < Base # 206
  end
  class MovedPermanently < Base # 301
  end
  class Found < Base # 302
  end
  class BadRequest < Base # 400
    TERMINATE = true
  end
  class Forbidden < Base # 403
  end
  class NotFound < Base # 404
  end
  class RequestedRangeNotSatisfiable < Base # 416
    TERMINATE = true
    HAS_BODY = false
  end
  class RequestUriTooLong < Base
  end
  class MethodNotImplemented < Base # 501
    TERMINATE = true
  end
end

module HttpIO
  class StringBuffer
    def initialize(str)
      @buf = str
      @size = @buf.size()
    end
    def size
      @size
    end
    def closed?
      !@buf
    end
    def close
      raise IOError, "closed stream" unless @buf
      @buf = nil
    end
    def sysread(blk)
      raise IOError, "closed stream" unless @buf
      raise EOFError, "EOF reach" if @buf.empty?
      @buf.slice!(0, blk)
    end
    def binmode
      self
    end
    def chunked?
      true
    end
  end
  class FileBuffer
    def initialize(path, mode = "rb")
      @stat = File.stat(path)
      @size = @stat.size
      # XXX Bogus win32 handling exotic craps such as nul, com1, so on..
      raise Errno::ENOENT unless @stat.file? && @size > 0
      @fd = File.open(path, mode)
      @fd.binmode()
    end
    attr_reader :stat
    def size
      @size
    end
    def closed?
      @fd.closed?
    end
    def close
      @fd.close()
    end
    def sysread(blk)
      @fd.sysread(blk)
    end
    def sysseek(pos)
      if pos < 0
        @size = -pos
        @fd.sysseek(pos, IO::SEEK_END)
      else
        @size = @stat.size - pos
        @fd.sysseek(pos, IO::SEEK_SET)
      end
    end
    alias :seek :sysseek
    def chunked?
      false
    end
  end
  # XXX Directory Indexing still infancy
  class DirectoryBuffer
    TIME_FORMAT = '%b %d %Y %I:%M %p'
    L_NAME = 'Name'
    L_LAST_MODIFIED = 'Last Modified'
    L_SIZE = 'Size'
    MAX_FILENAME_SIZE = 32
    MAX_LAST_MODIFIED_SIZE = Time.now.strftime(TIME_FORMAT).size()
    MAX_SIZE_SIZE = 8
    NAME_OFFSET = 4 + ((MAX_FILENAME_SIZE - L_NAME.size()) / 2)
    LAST_MODIFIED_OFFSET = ((MAX_FILENAME_SIZE - L_NAME.size()) / 2) + 4 + ((MAX_LAST_MODIFIED_SIZE - L_LAST_MODIFIED.size()) / 2)
    SIZE_OFFSET = 2 + ((MAX_LAST_MODIFIED_SIZE - L_LAST_MODIFIED.size()) / 2) + 4 + ((MAX_SIZE_SIZE - L_SIZE.size()) / 2)
    GIGA_BYTES = 1024*1024*1024
    MEGA_BYTES = 1024*1024
    KILO_BYTES = 1024
    def initialize(path, url, footer = "<address>#{HttpServer::SERVER_STRING}</address>")
      @path = path
      @stat = File.stat(path)
      raise Errno::ENOTDIR unless @stat.directory?
      @entries = []
      Dir.foreach(@path) do |ent|
        next if ent =~ /^\.\.?$/
        @entries.push(ent)
      end
      @t_dir = []
      @t_file = []
      @buf = <<-EOF
<html>
  <head><title>Index of #{CGI.escapeHTML(url)}</title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Index of #{CGI.escapeHTML(url)}</h1>
<pre>
EOF
      @buf << '<font color="#0000ee">' << " "*NAME_OFFSET <<
          "<u>#{L_NAME}</u>" << " "*LAST_MODIFIED_OFFSET <<
          "<u>#{L_LAST_MODIFIED}</u>" << " "*SIZE_OFFSET <<
          "<u>#{L_SIZE}</u></font>" << "\n"
      @buf << <<-EOF
<hr size="1" width="100%" noshade>
<img src="/images/back.gif" border="0" width="24" height="24" alt="[DIR]"> <a href="#{(File.dirname(url) << "/").gsub(/\/+/, '/')}">Parent Directory</a>
EOF
      @tail = <<-EOF
</pre>
<hr size="1" width="100%" noshade>
#{footer}
</body>
</html>
EOF
      @ready = false
    end
    def close
      raise "Closed stream" unless @entries
      @entries = nil
    end
    def closed?
      !@entries
    end
    def sysread(blk)
      unless @ready
        unless @entries.empty?
          cnt = 25
          while (ent = @entries.pop()) && cnt > 0
            begin
              st = File.stat(File.join(@path, ent))
              can_read = st.readable?
              can_exec = st.executable?
              if st.directory? && can_read && can_exec
                @t_dir << [st, ent]
              elsif st.file? && st.size() > 0 && can_read
                @t_file << [st, ent]
              end
            rescue Errno::ENOENT, Errno::EACCES
            end
            cnt -= 1
          end
        end
        if @entries.empty?
          @t_dir.sort! do |x, y|
            y.last.casecmp(x.last)
          end
          @t_file.sort! do |x, y|
            y.last.casecmp(x.last)
          end
          @ready = true
        else
          raise Errno::EAGAIN
        end
      end
      if @buf.empty?
        raise EOFError, "EOF reach" unless @tail
        while @buf.size() < blk
          if @t_dir.empty? && @t_file.empty?
            raise RuntimeError, "Dir @fd reach EOF, but @tail is nil????" unless @tail
            @buf << @tail
            @tail = nil
            break
          else
            ent = @t_dir.pop()
            if ent
              st = ent.first
              ent = ent.last
              if ent.size() + 1 > MAX_FILENAME_SIZE
                fname = ent.slice(0, MAX_FILENAME_SIZE - 3) << "..>"
              else
                fname = "#{ent}/"
              end
              @buf << "<img src=\"/images/folder.gif\" border=\"0\" width=\"24\" height=\"24\" alt=\"[DIR]\"> <a href=\"#{CGI.escape(ent)}/\">#{CGI.escapeHTML(fname)}</a>" << " "*(MAX_FILENAME_SIZE - fname.size() + 4) << "#{st.mtime.strftime(TIME_FORMAT)}" << " "*(((MAX_SIZE_SIZE - 1) / 2) + 2 + 4) << "-\n"
            else
              ent = @t_file.pop()
              if ent
                st = ent.first
                ent = ent.last
                if ent.size() > MAX_FILENAME_SIZE
                  fname = ent.slice(0, MAX_FILENAME_SIZE - 3) << "..>"
                else
                  fname = ent
                end
                sz = st.size
                if sz >= GIGA_BYTES
                  sz = sprintf("%#{MAX_SIZE_SIZE - 3}.1f GB", sz.to_f/GIGA_BYTES)
                elsif sz >= MEGA_BYTES
                  sz = sprintf("%#{MAX_SIZE_SIZE - 3}.1f MB", sz.to_f/MEGA_BYTES)
                elsif sz >= 1024
                  sz = sprintf("%#{MAX_SIZE_SIZE - 3}.1f KB", sz.to_f/KILO_BYTES)
                else
                  sz = sprintf("%#{MAX_SIZE_SIZE - 3}d B ", sz)
                end
                @buf << "<img src=\"/images/binary.gif\" border=\"0\" width=\"24\" height=\"24\" alt=\"[   ]\"> <a href=\"#{CGI.escape(ent)}\">#{CGI.escapeHTML(fname)}</a>" << " "*(MAX_FILENAME_SIZE - fname.size() + 4) << "#{st.mtime.strftime(TIME_FORMAT)}    #{sz}\n"
              else
                raise RuntimeError, "@t_dir && @t_file empty?!?!??!"
              end
            end
          end
        end
      end
      @buf.slice!(0, blk)
    end
    def chunked?
      true
    end
  end
end

class HttpServer < Multiplex::Core
  module HttpServerIO
    include IOutil
    attr_accessor :nameinfo, :family
    attr_accessor :is_ssl
    def is_server?
      true
    end
  end
  module HttpClientIO
    include IOutil
    attr_accessor :inbuf, :outbuf
    attr_accessor :current_time, :keep_alive, :keep_alive_counter
    attr_accessor :fd
    attr_accessor :method, :http_version, :header, :chunk_transfer
    attr_accessor :target, :safe_target, :request, :request_uri, :real_target, :query_string
    attr_accessor :server_addr, :client_addr
    attr_accessor :servertag, :docindex
    attr_accessor :family, :vhost
    attr_accessor :is_ssl
    def is_server?
      false
    end
  end
  BLOCKSIZE = 1 << 12 # 4096
  SERVER_NAME = "Gelojoh"
  SERVER_VERSION = "1.3"
  SERVER_VERSION << " IPv4/IPv6" if defined?(Socket::AF_INET6) && Socket::AF_INET != Socket::AF_INET6
  SERVER_RELDATE = "2005-01-22 IN_PROGRESS"
  SERVER_STRING = "#{SERVER_NAME} #{SERVER_VERSION} #{SERVER_RELDATE} / Ruby #{RUBY_VERSION} (#{RUBY_PLATFORM})"
  HEADER_MAX = 4096
  REQUEST_URI_MAX = 512
  MIME_TYPES = {}
  MIME_TYPES.default = "text/plain"
  if IS_WIN32
    LOG_TIME_FORMAT = "%d/%b/%Y [%#I:%M:%S %p] %z"
  else
    LOG_TIME_FORMAT = "%d/%b/%Y [%l:%M:%S %p] %z"
  end
  def initialize(config)
    # XXX
    @logfd = nil
    @need_update_timer = true
    @srv_conf = config
    @max_listen = @srv_conf[:max_listen]
    @ssl = nil
    @ssl_err = Errno::EINVAL
    @srv_conf[:listen].each do |conflisten|
      addr = conflisten[:addr]
      port = conflisten[:port]
      use_ssl = conflisten[:ssl]
      case conflisten[:family]
        when :ipv4
          socks = Socket.getaddrinfo(
            addr, port,
            Socket::AF_INET, Socket::SOCK_STREAM,
            nil, Socket::AI_PASSIVE
          )
          raise RuntimeError, "getaddrinfo() failed" if socks.empty?
          socks.each do |familystr, getport, hostname, getaddr, family, socktype, proto|
            setup_server_socket(getaddr, getport, family, socktype, proto, use_ssl)
          end
        when :ipv6
          if defined?(Socket::AF_INET6) && Socket::AF_INET6 != Socket::AF_INET
            socks = Socket.getaddrinfo(
              addr, port,
              Socket::AF_INET6, Socket::SOCK_STREAM,
              nil, Socket::AI_PASSIVE
            )
            raise RuntimeError, "getaddrinfo() failed" if socks.empty?
            socks.each do |familystr, getport, hostname, getaddr, family, socktype, proto|
              setup_server_socket(getaddr, getport, family, socktype, proto, use_ssl)
            end
          end
        when :all
          socks = Socket.getaddrinfo(
            addr, port,
            Socket::PF_UNSPEC, Socket::SOCK_STREAM,
            nil, Socket::AI_PASSIVE
          )
          raise RuntimeError, "getaddrinfo() failed" if socks.empty?
          socks.each do |familystr, getport, hostname, getaddr, family, socktype, proto|
            setup_server_socket(getaddr, getport, family, socktype, proto, use_ssl)
          end
      else
        raise ArgumentError, "Unknown family type"
      end
    end
    @server_size = size()
    @server_current_time = Time.now()
    @keep_alive_timeout = @srv_conf[:keep_alive_timeout]
    @keep_alive_max = @srv_conf[:keep_alive_max]
    @docroot = File.expand_path(config[:docroot])
    @docindex = @srv_conf[:docindex]
    @max_client = @srv_conf[:max_client]
    @max_clients_reach = 0
    @vhosts = @srv_conf[:vhosts]
    @aliases = {}
    @servertag = @srv_conf[:servertag] || SERVER_STRING
    @srv_conf[:aliases].each do |path_alias, path_target|
      set_alias(path_alias, path_target)
    end
    @srv_conf[:mime_file] ||= File.join(GELOJOH_BASE_DIR, 'mime.types')
    @blocksize = @srv_conf[:blocksize]
    @blocksize = BLOCKSIZE if !@blocksize.is_a?(Integer) || @blocksize < 1 ||
        @blocksize > (1 << 16)
    self.mime_types = @srv_conf[:mime_file]
    self.default_mime_types = "text/plain"
    self
  end
  def setup_server_socket(addr, port, family, socktype, proto = Socket::IPPROTO_TCP, use_ssl = false)
    if use_ssl && !@ssl
      begin
        require 'openssl'
      rescue LoadError
        log('WARNING: SSL not supported!')
        return false
      end
      key = @srv_conf[:ssl_key]
      cert = @srv_conf[:ssl_cert]
      if key && cert &&
          File.file?(key) && File.file?(cert) &&
          File.readable?(cert) && File.readable?(cert)
        key = OpenSSL::PKey::RSA.new(File.read(key))
        cert = OpenSSL::X509::Certificate.new(File.read(cert))
      else
        log('WARNING: SSL Key not found, auto generate...')
        key = OpenSSL::PKey::RSA.new(512){ STDOUT.print '.' }
        STDOUT.puts
        log('WARNING: SSL Certificate not found, auto generate...')
        # inspired from ruby-openssl sample
        cert = OpenSSL::X509::Certificate.new()
        cert.version = 2
        cert.serial = 0
        name = OpenSSL::X509::Name.new(
          [
            ['C', 'MY'], ['ST', 'Salur Kumbahan'],
            ['L', 'Longkang'], ['O','L337 Longkang'],
            ['OU', 'Taik'], ['CN','L337 Longkang'],
            ['emailAddress', 'kingLongkang@longkang.karam.my']
          ]
        )
        cert.subject = name
        cert.issuer = name
        cert.not_before = Time.now()
        cert.not_after = Time.now() + 3600
        cert.public_key = key.public_key
        ef = OpenSSL::X509::ExtensionFactory.new(nil, cert)
        cert.extensions = [
          ef.create_extension("basicConstraints","CA:FALSE"),
          ef.create_extension("subjectKeyIdentifier","hash"),
          ef.create_extension("extendedKeyUsage","serverAuth"),
          ef.create_extension("keyUsage",
                              "keyEncipherment,dataEncipherment,digitalSignature")
        ]
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension("authorityKeyIdentifier",
                                               "keyid:always,issuer:always"))
        cert.sign(key, OpenSSL::Digest::SHA1.new())
      end
      @ssl = {
        :cert => cert,
        :key => key
      }
      ctx = OpenSSL::SSL::SSLContext.new()
      ctx.cert = @ssl[:cert]
      ctx.key = @ssl[:key]
      @ssl[:ctx] = ctx
      @ssl_err = OpenSSL::SSL::SSLError
    end
    server_fd = TCPServer.new(addr, port)
    if use_ssl
      server_fd = OpenSSL::SSL::SSLServer.new(server_fd, @ssl[:ctx])
    end
    server_fd.extend(HttpServerIO)
    server_fd.is_ssl = use_ssl
    server_fd.nonblocking = true
    server_fd.to_io.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
    server_fd.to_io.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    server_fd.to_io.listen(@max_listen)
    server_fd.to_io.binmode()
    server_fd.nameinfo = Socket.getnameinfo(
      server_fd.to_io.getsockname, Socket::NI_NUMERICHOST|Socket::NI_NUMERICSERV
    )
    server_fd.family = family
    push(server_fd)
  end
  attr_accessor :keep_alive_timeout, :keep_alive_max
  attr_accessor :max_client
  def generate_footer(tag, s)
    if s.vhost
      "<address>#{CGI.escapeHTML(tag)} at #{CGI.escapeHTML(s.vhost)} Port #{CGI.escapeHTML(s.server_addr[1])}#{s.is_ssl ? ' (SSL)' : ''}</address>"
    else
      "<address>#{CGI.escapeHTML(tag)} at #{CGI.escapeHTML(s.server_addr.join(' Port '))}#{s.is_ssl ? ' (SSL)' : ''}</address>"
    end
  end
  def announce
    log("#{@servertag} Started...")
    unless IS_WIN32
      log("== Running as \"#{@srv_conf[:runas]}\" ==")
    end
    each() do |s|
      if s.is_server?
        log("Listening On #{s.nameinfo.join(' Port ')}#{s.is_ssl ? ' (SSL)' : ''}")
      end
    end
  end
  def mime_types=(file)
    MIME_TYPES.clear()
    File.foreach(file) do |line|
      next if line =~ /^\s*\#/
      line.strip!
      mime_type, exts = line.split(/\s+/, 2)
      next unless mime_type && exts
      exts.split(/\s+/).each do |ext|
        MIME_TYPES["." << ext.upcase()] = mime_type
      end
    end
  end
  def set_alias(path_alias, path_real)
    clean_alias = path_alias.dup()
    clean_alias.sub!(/^\/+/, '')
    clean_alias.sub!(/\/+$/, '')
    if clean_alias =~ /\//
      log("Warning: '#{path_alias}' contain '/' , skipping...")
    else
      @aliases[clean_alias] = path_real.dup()
    end
  end
  def default_mime_types=(type)
    MIME_TYPES.default = type
  end
  def update_timer
    if @need_update_timer
      @need_update_timer = false
      @server_current_time = Time.now()
    end
  end
  def expired(s)
    @need_update_timer = true
    if s.is_server?
      false
    else
      if @server_current_time - s.current_time > @keep_alive_timeout
        s.fd.close() unless !s.fd || s.fd.closed?
        s.close() unless s.closed?
        true
      else
        false
      end
    end
  end
  def readable(s)
    if s.is_server?
      true
    else
      s.outbuf.empty? && (!s.fd || s.fd.closed?)
    end
  end
  def writable(s)
    if s.is_server?
      false
    else
      !s.outbuf.empty? || (s.fd && !s.fd.closed?)
    end
  end
  def handle_read(s)
    update_timer()
    if s.is_server?
      total_fd = total_clients() + 1
      cl = nil
      begin
        cl = s.accept()
        if (total_fd - 1) < @max_client
          cl.extend(HttpClientIO)
          cl.is_ssl = s.is_ssl
          cl.nonblocking = true
          cl.to_io.setsockopt(
              Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
          )
          cl.server_addr = Socket.getnameinfo(cl.to_io.getsockname, Socket::NI_NUMERICHOST|Socket::NI_NUMERICSERV)
          cl.client_addr = Socket.getnameinfo(cl.to_io.getpeername, Socket::NI_NUMERICHOST|Socket::NI_NUMERICSERV)
          cl.inbuf = ""
          cl.outbuf = ""
          cl.current_time = @server_current_time
          cl.keep_alive = true
          cl.fd = nil
          cl.keep_alive_counter = @keep_alive_max
          cl.method = nil
          cl.http_version = 1
          cl.chunk_transfer = false
          cl.header = {}
          cl.header.default = ""
          cl.target = nil
          cl.safe_target = nil
          cl.real_target = nil
          cl.query_string = nil
          cl.request = nil
          cl.request_uri = nil
          cl.to_io.binmode()
          cl.docindex = @docindex
          cl.servertag = @servertag
          cl.vhost = nil
          cl.family = s.family
          @max_clients_reach = total_fd if total_fd > @max_clients_reach
          push(cl)
        else
          cl.close() unless cl.closed?
        end
      rescue Errno::ECONNABORTED, Errno::ENOTCONN, Errno::ECONNRESET, @ssl_err
        cl.close() if cl && !cl.closed?
        log("ERROR: #{$!.class} : #{$!.message}")
      end
    else
      raise RuntimeError, "Stalled fd" unless !s.fd || s.fd.closed?
      s.current_time = @server_current_time
      begin
        raise EOFError if s.inbuf.size() > HEADER_MAX
        s.inbuf << s.sysread(@blocksize)
        if s.inbuf =~ /^(.*?\r?\n\r?\n)/m
          begin
            header = $1
            s.inbuf.replace("") # Temporary measure, enough for GET/HEAD
            header.strip!
            header = header.split(/\s*\r?\n\s*/)
            header.reverse!
            unless header.pop() =~ /^((.+?)\s+((.+?)(\?(.*?))?)\s+HTTP\/1\.(0|1))$/i
              raise HttpError::BadRequest
            end
            s.request = $1
            s.method = $2
            s.request_uri = $3
            s.query_string = $6
            s.http_version = $7.to_i
            s.target = CGI.unescape($4.gsub(/\+/, '%2B'))
            case s.method
              when "GET"
              when "HEAD"
            else
              raise HttpError::MethodNotImplemented
            end
            raise HttpError::RequestUriTooLong if s.request_uri.size() > REQUEST_URI_MAX
            s.keep_alive = (s.http_version == 1)
            s.header.clear()
            header.each do |ent|
              key, val = ent.split(/:/, 2)
              if key && val
                key.upcase!
                val.strip!
                s.header[key] = val
              else
                raise HttpError::BadRequest
              end
            end
            if /^http:\/\/([^\/]*)/i =~ s.target
              rhost = $1
              s.target.sub!(/^http:\/\/[^\/]*/i, '')
              s.target.replace('/') if s.target.empty?
            else
              rhost = s.header['HOST']
            end
            if rhost && rhost.size() > 0
              if /^\[(.+?)\]/ =~ rhost
                rhost = $1
              else
                rhost = rhost.dup()
                rhost.sub!(/:\d+$/, '')
              end
              s.vhost = rhost.dup()
            else
              s.vhost = nil
            end
            raise HttpError::BadRequest unless s.target =~ /^\//
            begin
              s.safe_target = get_safe_target(s.target, "/")
            rescue ArgumentError
              raise HttpError::BadRequest
            end
            s.safe_target << "/" if s.target =~ /\/$/
            s.safe_target.gsub!(/\/+/, '/')
            raise HttpError::MovedPermanently unless s.target == s.safe_target
            s.real_target = get_real_target(s)
            mime_type = nil
            if s.target =~ /\/$/
              doc_index = nil
              get_docindex(s).each do |idx|
                if File.file?("#{s.real_target}#{idx}")
                  doc_index = idx
                  s.target << idx
                  s.safe_target << idx
                  s.real_target << idx
                  break
                else
                  doc_index = nil
                end
              end
              if doc_index
                s.fd = HttpIO::FileBuffer.new(s.real_target)
                mime_type = MIME_TYPES[File.extname(s.real_target).upcase]
              else
                s.fd = HttpIO::DirectoryBuffer.new(s.real_target, s.target, generate_footer(s.servertag, s))
                mime_type = "text/html"
              end
            else
              if File.directory?(s.real_target)
                s.safe_target << "/"
                raise HttpError::MovedPermanently
              end
              s.fd = HttpIO::FileBuffer.new(s.real_target)
              mime_type = MIME_TYPES[File.extname(s.real_target).upcase]
            end
            if s.fd.is_a?(HttpIO::FileBuffer)
              case s.header["RANGE"]
                when /^bytes=(\d+)\-$/i
                  offset = $1.to_i
                  if offset > -1 && offset < s.fd.size()
                    s.fd.seek(offset)
                    raise HttpError::PartialContent
                  else
                    raise HttpError::RequestedRangeNotSatisfiable
                  end
                when /^bytes=\-(\d+)$/i
                  offset = $1.to_i
                  if offset == 0
                    raise HttpError::RequestedRangeNotSatisfiable
                  elsif offset < s.fd.size()
                    s.fd.seek(-offset)
                  end
                  raise HttpError::PartialContent
              end
            end
            build_reply(s, 200, mime_type)
          rescue HttpError::PartialContent
            build_reply(s, 206, mime_type)
          rescue HttpError::MovedPermanently
            build_reply(s, 301)
          rescue HttpError::BadRequest
            s.method = s.target = "-"
            s.keep_alive = false
            build_reply(s, 400)
          rescue Errno::EACCES
            build_reply(s, 403)
          rescue Errno::ENOENT, Errno::ENOTDIR
            build_reply(s, 404)
          rescue Errno::ENAMETOOLONG, Errno::EINVAL, HttpError::RequestUriTooLong
            build_reply(s, 413)
          rescue HttpError::RequestedRangeNotSatisfiable
            build_reply(s, 416, mime_type)
          rescue HttpError::MethodNotImplemented
            s.keep_alive = false
            build_reply(s, 501)
          end
        end
      rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL, @ssl_err
        s.fd.close() unless !s.fd || s.fd.closed?
        s.close() unless s.closed?
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      end
    end
  end
  def handle_write(s)
    update_timer()
    s.current_time = @server_current_time
    begin
      if s.fd
        begin
          sz = s.outbuf.size()
          if sz < @blocksize
            if s.chunk_transfer
              buf = s.fd.sysread(@blocksize - sz)
              s.outbuf << format("%x\r\n", buf.size()) << buf << "\r\n"
            else
              s.outbuf << s.fd.sysread(@blocksize - sz)
            end
          end
        rescue EOFError
          s.outbuf << "0\r\n\r\n" if s.chunk_transfer
          s.fd.close() unless s.fd.closed?
          s.fd = nil
        end
      end
      s.outbuf.slice!(0, s.syswrite(s.outbuf.slice(0, @blocksize))) unless s.outbuf.empty?
      raise EOFError unless !s.outbuf.empty? || s.fd || s.keep_alive
    rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL, @ssl_err
      s.fd.close() unless !s.fd || s.fd.closed?
      s.close() unless s.closed?
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
    end
  end
  if defined?(Socket::AF_INET6) && Socket::AF_INET6 != Socket::AF_INET
    def get_docindex(s)
      if s.family == Socket::AF_INET6
        s.docindex[:ipv6]
      else
        s.docindex[:ipv4]
      end
    end
  else
    def get_docindex(s)
      s.docindex[:ipv4]
    end
  end
  def stat
    log("#{@server_current_time} / Total Clients: #{total_clients()} (Max: #{@max_clients_reach})")
  end
  def total_clients
    size() - @server_size
  end
  if IS_WIN32
    def get_safe_target(target, rel)
      File.expand_path(target, rel).sub(/^[a-zA-Z]:/, '')
    end
  else
    def get_safe_target(target, rel)
      File.expand_path(target, rel)
    end
  end
  def get_real_target_from_vhosts(s)
    vh = @vhosts["#{s.vhost}".upcase()]
    s.servertag = vh.servertag || @servertag
    s.docindex = vh.docindex || @docindex
    s.vhost = vh.host
    File.join(vh.path || @docroot, s.safe_target)
  end
  def get_real_target_from_aliases(s)
    vhost_ret = get_real_target_from_vhosts(s)
    target = s.safe_target
    if target =~ /^\/([^\/]+)\/(.*)$/
      if (target_alias = @aliases[$1])
        File.join(target_alias, $2 || "")
      else
        vhost_ret
      end
    else
      vhost_ret
    end
  end
  if IS_WIN32
    def get_real_target(s)
      # XXX This is crap, win9x _fullpath is broken
      # winnt and derivatives seems fine, but win9x
      # either take long delay before bailing out,
      # or simply return false, which involved function
      # rb_w32_stat or win32_stat or whatever
      ret = get_real_target_from_aliases(s) || File.join(@docroot, s.safe_target)
      ret.sub!(/\/+$/, '/')
      ret.sub!(/^([a-zA-Z]:\/)\/+(.*)$/, '\1\2')
      ret
    end
  else
    def get_real_target(s)
      get_real_target_from_aliases(s) || File.join(@docroot, s.safe_target)
    end
  end
  def build_reply(s, status = 200, mime_type = "text/html")
    raise RuntimeError, "Client outbuf not empty" unless s.outbuf.empty?
    addheader = ""
    partial_error = false
    s.keep_alive_counter -= 1
    if !s.keep_alive ||
        s.http_version == 0 ||
        s.keep_alive_counter < 1 ||
        (s.header["CONNECTION"].upcase() == "CLOSE")
      s.keep_alive = false
      addheader << "Connection: close\r\n"
    end
    if s.keep_alive && s.header["CONNECTION"].upcase() == "KEEP-ALIVE"
      addheader << "Connection: Keep-Alive\r\n"
      addheader << "Keep-Alive: timeout=#{@keep_alive_timeout}, max=#{s.keep_alive_counter + 1}\r\n"
    end
    case status
      when 200
        true
      when 206
        sz = s.fd.size()
        rsz = s.fd.stat.size
        addheader << "Content-Range: bytes #{rsz - sz}-#{rsz - 1}/#{rsz}\r\n"
      when 301
        addheader << "Location: #{s.safe_target}\r\n"
        s.fd = HttpIO::StringBuffer.new(<<-EOF
<html>
  <head><title>301 Moved Permanently</title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Moved Permanently</h1>
    The document has moved <a href="#{s.safe_target}">here</a>.
    <hr size="1" width="100%" noshade>
    #{generate_footer(s.servertag, s)}
  </body>
</html>
EOF
        )
      when 400
        s.fd = HttpIO::StringBuffer.new(<<-EOF
<html>
  <head><title>400 Bad Request</title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Bad Request</h1>
    Your browser sent a request that this server could not understand.
    <hr size="1" width="100%" noshade>
    #{generate_footer(s.servertag, s)}
  </body>
</html>
EOF
        )
      when 403
        s.fd = HttpIO::StringBuffer.new(<<-EOF
<html>
  <head><title>403 Forbidden</title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Forbidden</h1>
    You don't have permission to access #{CGI.escapeHTML(s.target)} in this server.
    <hr size="1" width="100%" noshade>
    #{generate_footer(s.servertag, s)}
  </body>
</html>
EOF
        )
      when 404
        s.fd = HttpIO::StringBuffer.new(<<-EOF
<html>
  <head><title>404 Not found</title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Not Found</h1>
    The requested URL #{CGI.escapeHTML(s.target)} was not found on this server.
    <hr size="1" width="100%" noshade>
    #{generate_footer(s.servertag, s)}
  </body>
</html>
EOF
        )
      when 413
        s.fd = HttpIO::StringBuffer.new(<<-EOF
<html>
  <head><title>413 Request URI Too Long</title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Request URI Too Long</h1>
    The requested URI #{s.request_uri} was too long.
    <hr size="1" width="100%" noshade>
    #{generate_footer(s.servertag, s)}
  </body>
</html>
EOF
        )
      when 416
        partial_error = true
      when 501
        s.fd = HttpIO::StringBuffer.new(<<-EOF
<html>
  <head><title>501 Method Not Implemented/title></head>
  <body color="#000000" bgcolor="#ffffff">
    <h1>Method Not Implemented</h1>
    Invalid method for HTTP/1.#{s.http_version}.
    <hr size="1" width="100%" noshade>
    #{generate_footer(s.servertag, s)}
  </body>
</html>
EOF
        )
    else
      raise RuntimeError, "Unknown status code #{status}"
    end
    rfcdate = CGI.rfc1123_date(@server_current_time)
    s.outbuf << "HTTP/1.1 #{status} #{HttpError::TITLE[status]}\r\n"
    s.outbuf << "Date: #{rfcdate}\r\n"
    s.outbuf << "Server: #{s.servertag}\r\n"
    s.outbuf << "Last-Modified: #{CGI.rfc1123_date(s.fd.stat.mtime)}\r\n" if s.fd.is_a?(HttpIO::FileBuffer)
    s.outbuf << addheader unless addheader.empty?
    if partial_error
      s.outbuf << "Accept-Ranges: bytes\r\n"
      s.outbuf << "Content-Length: 0\r\n"
      s.outbuf << "Content-Range: bytes */#{s.fd.size()}\r\n"
      s.fd.close()
      s.fd = nil
    else
      if s.fd.chunked?
        if s.method != "HEAD" && s.http_version == 1
          s.chunk_transfer = true
          s.outbuf << "Transfer-Encoding: chunked\r\n"
        else
          s.chunk_transfer = false
        end
      else
        s.chunk_transfer = false
        s.outbuf << "Accept-Ranges: bytes\r\n"
        s.outbuf << "Content-Length: #{s.fd.size()}\r\n"
      end
    end
    s.outbuf << "Content-Type: #{mime_type}\r\n"
    s.outbuf << "\r\n"
    if s.fd && s.method == "HEAD"
      s.fd.close() unless s.fd.closed?
      s.fd = nil
    end
    log("#{s.client_addr.first()} - #{@server_current_time.strftime(LOG_TIME_FORMAT)} - [#{s.vhost}#{s.is_ssl ? '/SSL' : ''}] \"#{s.request}\" #{status} - #{s.header['USER-AGENT'] || ''} - [Total:#{total_clients()}/Max:#{@max_clients_reach}]")
  end
  def log(msg)
    STDERR.puts msg
  end
  def run
    unless IS_WIN32
      # Unix platform can drop privilege
      require 'etc'
      begin
        pw = Etc.getpwnam(@srv_conf[:runas])
      rescue ArgumentError
        log("User '#{conf[:runas]}' Not Exist!! Fix your 'RunAs' directive!")
        exit(1)
      end
      if @srv_conf[:daemon]
        exit!(0) if fork()
        Process.setsid()
        exit!(0) if fork()
      end
      begin
        # write pid file
        File.open(@srv_conf[:pidfile], 'wb') do |fd|
          fd.puts $$
        end
      rescue TypeError, Errno::ENOENT, Errno::EACCES, Errno::EINVAL
      end
      begin
        @logfd = File.open(@srv_conf[:logfile], 'ab')
      rescue TypeError, Errno::ENOENT, Errno::EACCES, Errno::EINVAL
        @logfd = nil
      end
      if @logfd
        STDIN.reopen('/dev/null', 'r+')
        STDOUT.reopen(@logfd)
        STDERR.reopen(STDOUT)
      end
      %w[SIGTERM SIGQUIT SIGKILL SIGINT SIGHUP SIGABRT].each do |sig|
        trap(sig) do
          log('Server shutting down!')
          each do |fd|
            begin
              fd.close()
            rescue
            end
          end
          begin
            @logfd.close() if @logfd
          rescue
          end
          exit(0)
        end
      end
      # drop privilege
      Process.egid = Process.gid = pw.gid
      Process.euid = Process.uid = pw.uid
    end
    announce()
    timeout = nil
    while true
      @server_current_time = Time.now()
      if poll(timeout) || total_clients() > 0
        timeout = 1
      else
        timeout = nil
        GC.start()
      end
    end
  end
end

if __FILE__ == $0
  ENV.clear() unless IS_WIN32
  conf = gelojoh_conf_parse(ARGV[0] || File.join(File.dirname(__FILE__), "gelojoh.conf"))
  srv = HttpServer.new(conf)
  srv.run()
end
