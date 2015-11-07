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

class ExplorerFileType
	ExplorerFtype = Struct.new(:key, :info, :apps, :icons)
	def initialize
		@ftype = {}
		@regex = []
		@unknown = ExplorerFtype.new(nil, "Unknown File Type", [], [0])
		@directory = ExplorerFtype.new(nil, "Directory", nil, [1])
		@home_directory = ExplorerFtype.new(nil, "Home Directory for \"#{Reg.user}\"", nil, [1, 14])
		@root_directory = ExplorerFtype.new(nil, "Root Directory", nil, [13])
		@partition_directory = ExplorerFtype.new(nil, "Partition", nil, [8])
		@network_directory = ExplorerFtype.new(nil, "Network", nil, [9])
		@mfs_directory = ExplorerFtype.new(nil, "Memory File System", nil, [10])
		@vnode_directory = ExplorerFtype.new(nil, "Virtual Node Device", nil, [10])
		@floppy_directory = ExplorerFtype.new(nil, "Floppy Disk", nil, [11])
		@cdrom_directory = ExplorerFtype.new(nil, "CD-ROM", nil, [12])
		@block_device = ExplorerFtype.new(nil, "Block Device", nil, [4])
		@character_device = ExplorerFtype.new(nil, "Character Device", nil, [5])
		@named_pipe = ExplorerFtype.new(nil, "Named Pipe (FIFO)", nil, [6])
		@socket = ExplorerFtype.new(nil, "Unix Socket", nil, [7])
		@home = Reg.home
		@re = /.+\.([^\.]+)$/i
		stat = File.stat("/")
		@root_dev_ino = [stat.dev, stat.ino]
		stat = File.stat(@home)
		@home_dev_ino = [stat.dev, stat.ino]
		stat = nil
	end
	def add(ext, info = nil, apps = nil, icons = 0)
		if ext.is_a?(Array)
			ext.each do |x|
				add(x, info, apps, icons)
			end
		else
			st = ExplorerFtype.new
			st.key = ext.to_s.upcase
			st.info = info
			st.apps = apps.is_a?(Array) ? apps : [apps]
			st.apps.compact!
			st.apps.uniq!
			icons = [icons] unless icons.is_a?(Array)
			icons.compact!
			icons.uniq!
			st.icons = []
			icons.each do |i|
				st.icons.push(i) if i.is_a?(Integer)
			end
			st.icons.compact!
			st.icons.uniq!
			st.icons = [0] unless st.icons.size > 0
			@ftype[st.key] = st
		end
	end
	def has_type?(ext)
		@ftype.has_key?(ext.upcase)
	end
	def get(ext)
		ext = ext.to_s.upcase
		if @ftype.has_key?(ext)
			@ftype[ext]
		else
			@unknown
		end
	end
	def get_ftype(obj)
		ext = nil
		prefix = nil
		suffix = nil
		ftype = nil
		strong_prefix = false
#		@regex.each do |x|
		for x in @regex
			if x[2] =~ obj
				prefix = x[0].upcase
				strong_prefix = x[1]
				if strong_prefix
					return @ftype[prefix], @ftype[prefix].key
				end
				break
			end
		end
		if @re =~ obj
			suffix = $1.upcase
		end
		use_prefix = @ftype[prefix]
		use_suffix = @ftype[suffix]
		if use_suffix
			ext = use_suffix.key
			ftype = use_suffix
		elsif use_prefix
			ext = use_prefix.key
			ftype = use_prefix
		else
			ext = suffix
		end

		if ext && ftype
			return ftype, ext
		else
			return @unknown, ext
		end
	end
	def get_dtype(st_dev, st_ino)
		if st_dev == @root_dev_ino[0] && st_ino == @root_dev_ino[1]
			return @root_directory
		elsif st_dev == @home_dev_ino[0] && st_ino == @home_dev_ino[1]
			return @home_directory
		else
			Reg.fs.mount_point.each do |pt|
				if st_dev == pt[3] && st_ino == pt[4]
					if pt[2] == "procfs"
						return @directory
					elsif pt[2] == "cd9660"
						return @cdrom_directory
					elsif pt[2] == "nfs" || pt[2] == "smbfs"
						return @network_directory
					elsif pt[2] == "mfs"
						return @mfs_directory
					elsif pt[0] =~ /^\/dev\/r?vn\d.*/
						return @vnode_directory
					elsif pt[0] =~ /^\/dev\/[rw]?fd\d+.*/
						return @floppy_directory
					else
						return @partition_directory
					end
					break
				end
			end
			return @directory
		end
	end
	def add_regex(add)
		@regex.push(add) if add.is_a?(Array) && add.size == 3
	end
	attr_reader :unknown, :block_device, :character_device, :named_pipe, :socket
	attr_reader :directory, :home_directory, :root_directory
end
