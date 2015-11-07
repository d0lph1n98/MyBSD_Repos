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
#        $MyBSD: src/gelojoh/ioutil.rb,v 1.1.1.1 2003/07/26 22:45:58 skywizard Exp $
#
# Date: Tue Jun  3 02:41:24 MYT 2003
#   OS: FreeBSD kasumi.MyBSD.org.my 4.7-RELEASE i386
#

if RUBY_PLATFORM =~ /(mingw|mswin)32/i
  module IOutil
    def nonblocking=(flag)
      false
    end
    def blocking=(flag)
      true
    end
    def nonblocking?
      false
    end
    def blocking?
      true
    end
  end
else
  require 'fcntl'

  module IOutil
    def nonblocking=(flag)
      fcntl(
        Fcntl::F_SETFL,
        (fcntl(Fcntl::F_GETFL, 0) & ~Fcntl::O_NONBLOCK)|(flag ? Fcntl::O_NONBLOCK : 0)
      )
    end
    def blocking=(flag)
      self.nonblocking = !flag
    end
    def nonblocking?
      (fcntl(Fcntl::F_GETFL, 0) & Fcntl::O_NONBLOCK) != 0
    end
    def blocking?
      !self.nonblocking?
    end
  end
end
