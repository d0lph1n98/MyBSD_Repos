#
# Copyright (c) 1999, 2000, 2001, 2002 Ariff Abdullah 
# 	(skywizard@MyBSD.org.my) All rights reserved.
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

class FSCache
	def initialize
		@max = Reg.registry_data["max_dir_cache"]
		@cache_list = {}
		@cache_array = []
	end
	def cached?(key, stat)
		@cache_list.has_key?(key) && @cache_list[key][0] == stat
	end
	def add(key, stat, val)
		force_add = true
		if @cache_list.has_key?(key)
			@cache_array.delete(key)
			if @cache_list[key][0] == stat
				force_add = false
			end
		else
			if @cache_array.size >= @max
				@cache_list.delete(@cache_array[0])
				@cache_array.shift
			end
		end
		@cache_array.push(key)
		if force_add
			add_val = []
			val.each do |item|
				add_val.push(item.dup)
				add_val[-1].selected = 0
			end
			@cache_list[key] = [stat, add_val]
		end
	end
	def valid_cached?(key, stat)
		if @cache_list.has_key?(key)
			fs = @cache_list[key]
			if fs[0] == stat
				ret = []
				fs[1].each do |item|
					ret.push(item.dup)
					ret[-1].selected = 0
				end
				ret
			else
				@cache_array.delete(key)
				@cache_list.delete(key)
				nil
			end
		else
			nil
		end
	end
	def dump
		print "Cache Size: ", @cache_array.size, "\n"
		print "Cached Directory:\n"
		@cache_array.each do |dir|
			print "\t", dir, "\n"
		end
	end
end
