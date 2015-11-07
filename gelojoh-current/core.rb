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
#        $MyBSD: src/gelojoh/core.rb,v 1.1.1.1 2003/07/26 22:45:58 skywizard Exp $
#
# Date: Mon May 12 01:47:37 MYT 2003
#   OS: FreeBSD kasumi.MyBSD.org.my 4.7-RELEASE i386
#

module Multiplex
  class Core < Array
    def poll(timeout = nil)
      fd_read = []
      fd_write = []
      s = nil
      delete_if do |s|
        if s.closed?
          true
        elsif expired(s)
          raise RuntimeError, "FD still opened after expired" unless s.closed?
          true
        else
          can_read = readable(s)
          can_write = writable(s)
          raise RuntimeError, "FD Deadlock" if can_read == can_write
          fd_read.push(s) if can_read
          fd_write.push(s) if can_write
          false
        end
      end
      r, w, = IO.select(fd_read, fd_write, nil, timeout)
      if r || w
        r ||= []
        w ||= []
        for s in r
          handle_read(s)
        end
        for s in w
          handle_write(s)
        end
        true
      else
        false
      end
    end
  end
end
