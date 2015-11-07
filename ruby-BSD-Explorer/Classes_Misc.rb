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

class << File
	def realpath(path)
		tmp = []
		path = expand_path(path, Dir.pwd) unless path[0,1] == "/"
		path.split('/').each do |x|
			next if x == "."
			next if x == ""
			if x == ".." then
				tmp.pop
			else
				t = "/"+join(tmp)
				tl = join(t, x)
				if test(?l, tl) then
					tmp = realpath(expand_path(readlink(tl), t)).split('/')
				else
					tmp.push(x)
				end
			end
		end
		("/"+join(tmp)).gsub(/\/+/, '/')
	end
	def escape(str)
		str.gsub(/\\/, '\&\&').gsub(/\$/, '\\$')
	end
	def clean(str)
		str.gsub(/\/+/, '/')
	end
	def mkfifo(path)
		["/bin", "/usr/bin"].each do |dir|
			mkfifo_exe = dir + "/mkfifo"
			if test(?f, mkfifo_exe) && test(?x, mkfifo_exe)
				system("#{mkfifo_exe} \"#{escape(path)}\"")
				return nil
			end
		end
		raise "Cannot found mkfifo executable."
	end
end

class ExplorerAddressBar < Gtk::HandleBox
	def initialize(session)
		@session = session
		@popdown_list = []
		super()
		border_width(4)
		hbox = Gtk::HBox.new(false, 0)
		label = Gtk::Label.new("Address:")
		@button = Gtk::Button.new()
		bhbox = Gtk::HBox.new(false, 0)
		bhbox.pack_start(Gtk::Pixmap.new(*Reg.core_icons_db.get(17)), false, false, 2)
		bhbox.pack_start(Gtk::Label.new("Go!"), false, false, 2)
		@button.add(bhbox)
		@combo = Gtk::Combo.new()
		@combo.disable_activate()
		@combo.entry.signal_connect("activate") do
			todir = @combo.entry.get_text.to_s
			if @session.chdir(todir)
				set_and_collect(@session.pwd)
			end
		end
		@button.signal_connect("clicked") do
			todir = @combo.entry.get_text.to_s
			if @session.chdir(todir)
				set_and_collect(@session.pwd)
			end
		end
		hbox.pack_start(label, false, false, 2)
		hbox.pack_start(@combo, true, true, 0)
		hbox.pack_start(@button, false, false, 2)
		add(hbox)
	end
	def set_entry(entry = @session.pwd)
		@combo.entry.set_text(entry.is_a?(String) ? entry : @session.pwd)
	end
	private
	def set_and_collect(entry)
		@popdown_list.unshift(entry)
		@popdown_list.uniq!
		@combo.set_popdown_strings(@popdown_list)
	end
end

class ExplorerMenuItem < Gtk::MenuItem
	@@style = nil
	def initialize(str = nil)
		super()
		if str
			@@style = Reg.popup_style unless @@style
			set_style(@@style)
			acl = Gtk::AccelLabel.new("#{str}")
			acl.set_style(@@style)
			acl.set_alignment(0.0, 0.5)
			set_style(@@style)
			add(acl)
			acl.set_accel_widget(self)
			acl.show
		end
		self
	end
end
