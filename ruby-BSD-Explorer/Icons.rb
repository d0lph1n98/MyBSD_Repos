#
# Copyright (c) 1999, 2000, 2001 Ariff Abdullah 
# 	(skywizard@MyBSD.org.my). All rights reserved.
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
#	$MyBSD$
#	$FreeBSD$
#

class ExplorerIcons
	def initialize(path = File.join(EXPLORER_BASE, 'icons'), type = "gif", width = nil, height = nil)
		@prefix = path
		@default_type = type
		@width = width
		@height = height
		@icons = []
	end
	def add(file)
		if file.is_a?(Array)
			file.each do |x|
				add(x)
			end
		else
			if file !~ /^(\.\.?\/|\/)/
				file = @prefix+"/"+file
			end
			file = file+"."+@default_type unless test(?f, file)
			st = nil
			begin
				st = [Gdk::Pixbuf.new(file)]
			rescue
				print "Warning: Failed to load #{file}: #{$!}\n"
			end
			if st
				st.push(st[0].scale(
					(@width.is_a?(Integer) && @width > 0) ? @width : st[0].get_width,
					(@height.is_a?(Integer) && @height > 0) ? @height : st[0].get_height
				).render_pixmap_and_mask(128))
			end
			@icons.push(st)
		end
	end
	def get(index = 0)
		@icons[(index.is_a?(Integer) && @icons[index]) ? index : 0][1]
	end
	def get_with_size(index = 0, x = @width, y = @height)
		index = 0 unless index.is_a?(Integer) && @icons[index]
		pb = @icons[index][0]
		pb.scale(
			x.is_a?(Integer) ? x : pb.get_width,
			y.is_a?(Integer) ? y : pb.get_height
		).render_pixmap_and_mask(128)
	end
	def last
		@icons.size - 1
	end
	def raw
		@icons
	end
end
