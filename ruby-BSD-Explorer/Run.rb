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


class ExplorerRun
	MAX_HISTORY = 25
	def initialize(xpos = nil, ypos = nil)
		@file = Reg.home + "/.tomoyo_explorer/run_history"
		@xpos = xpos
		@ypos = ypos
		@history = []
		@window = nil
		@xpos = 8 unless @xpos.is_a?(Integer)
		@ypos = Gdk.screen_height-(768-580) unless @ypos.is_a?(Integer)
		begin
			IO.foreach(@file) do |l|
				@history.push(l.chomp)
				@history.compact!
				@history.uniq!
				break if @history.size >= MAX_HISTORY
			end
		rescue
		end
	end
	def cleanup
		begin
			open(@file, "w") do |f|
				@history[0 .. MAX_HISTORY-1].each do |l|
					f.print("#{l}\n")
				end
			end
		rescue
		end
	end
	def run
		return nil if @window != nil
		@window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
		@window.signal_connect("destroy") do
			@window.destroy
			@window = nil
		end
		@window.set_title("Run")
		@window.set_policy(false, false, false)
		@window.border_width(5)
		@window.set_uposition(@xpos, @ypos)
		@window.set_wmclass("BSD_EXPLORER_RUN_DIALOG", "BSD_EXPLORER_DIALOG")
		@window.realize
		
		table = Gtk::Table.new(0, 0, false)
		
		icon = Gtk::Pixmap.new(*Reg.icons_db.get(21))
		
		label1 = Gtk::Label.new("Open:")
		label1.set_pattern("_")
		label1.jtype = Gtk::JUSTIFY_RIGHT|Gtk::JUSTIFY_FILL
		label2 = Gtk::Label.new("Type the name of a program, " +
			"folder, document, or Internet\nresource, " +
			"and BSD Explorer will open it for you.")
		label2.jtype = Gtk::JUSTIFY_LEFT|Gtk::JUSTIFY_FILL
		
		combo = Gtk::Combo.new()
		combo.disable_activate()
		combo.set_popdown_strings(@history) if @history.size > 0
		combo.entry.signal_connect("activate") do
			cmd = combo.entry.get_text
			@window.destroy
			run_cmd(cmd)
		end
		
		hbut = Gtk::HButtonBox.new()
		hbut.set_layout(Gtk::BUTTONBOX_END)
		hbut.set_spacing(3)
		button_ok = Gtk::Button.new("OK")
		button_ok.signal_connect("clicked") do
			cmd = combo.entry.get_text
			@window.destroy
			run_cmd(cmd)
		end
		hbut.add(button_ok)
		button_cancel = Gtk::Button.new("Cancel")
		button_cancel.signal_connect("clicked") do @window.destroy end
		hbut.add(button_cancel)
		button_browse = Gtk::Button.new()
		label = Gtk::Label.new("Browse...")
		label.set_pattern("_")
		button_browse.add(label)
		button_browse.signal_connect("clicked") do
			_verbose = $VERBOSE
			$VERBOSE = false
			fsel = Gtk::FileSelection.new("Select a file/program to execute:")
			fsel.set_position(Gtk::WIN_POS_MOUSE)
			fsel.signal_connect("destroy") do fsel.destroy end
			fsel.set_modal(true)
			fsel.set_transient_for(@window)
			fsel.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
			fsel.hide_fileop_buttons
			fsel.realize
			fsel.cancel_button.signal_connect("clicked") do fsel.destroy end
			fsel.ok_button.signal_connect("clicked") do
				cmd = fsel.get_filename
				if test(?f, cmd) && test(?x, cmd)
					combo.entry.set_text(cmd)
					fsel.destroy
				end
			end
			fsel.show_all
			$VERBOSE = _verbose
		end
		hbut.add(button_browse)
		
		
		table.attach(icon, 0, 1, 0, 1, nil, nil, 5, 5)
		table.attach(label1, 0, 1, 1, 2, nil, nil, 5, 5)
		table.attach(label2, 1, 2, 0, 1, nil, nil, 5, 5)
		table.attach(combo, 1, 2, 1, 2, nil, nil, 5, 5)
		table.attach(hbut, 1, 2, 2, 3, nil, nil, 5, 5)
		
		@window.add(table)
		combo.entry.grab_focus
		@window.show_all
	end
	private
	def run_cmd(cmd)
		if cmd.length > 0
			system("#{File.escape(cmd)} &")
			@history.unshift(cmd)
			@history.compact!
			@history.uniq!
			@history.pop if @history.size > MAX_HISTORY
		end
	end
end

if __FILE__ == $0
	require 'gtk'
	require 'gdk_pixbuf'
	st = Struct.new(:home, :icons_db)
	Reg = st.new(ENV["HOME"], nil)
	def File.escape(str)
		str.gsub(/\\/, '\&\&').gsub(/\$/, '\\$')
	end
	class Dummy
		def get(whatever)
			Gdk::Pixbuf.new(
				"/usr/local/share/tomoyo-explorer/icons/winxp/run.png"
			).render_pixmap_and_mask(128)
		end
	end
	class ExplorerRun
		attr_accessor :window
	end
	Reg.icons_db = Dummy.new()
	run = ExplorerRun.new()
	run.run()
	run.window.signal_connect("destroy") do Gtk.main_quit() end
	Gtk.main()
end
