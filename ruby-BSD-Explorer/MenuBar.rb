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

class ExplorerMenuBar < Gtk::HandleBox
	def initialize(session)
		@session = session
		bar = Gtk::MenuBar.new()
			item = ExplorerMenuItem.new("File")
			sub_item = Gtk::Menu.new()
			item.set_submenu(sub_item)
			if $EXPLORER_SERVER
				sub_item_item = ExplorerMenuItem.new(" Run... ")
				sub_item_item.signal_connect("activate") do
					@session.ipc_send("-run", @session.pwd)
				end
				sub_item.append(sub_item_item)
			end
			sub_item_item = ExplorerMenuItem.new(" Open Terminal Emulator ")
			sub_item_item.signal_connect("activate") do
				system("cd \"#{File.escape(@session.pwd)}\" ; #{Reg.registry_data['default_xterm']} &")
			end
			sub_item.append(sub_item_item)
			sub_item_item = ExplorerMenuItem.new(" New Window ")
			sub_item_item.signal_connect("activate") do
				if $EXPLORER_SERVER
					@session.ipc_send(@session.pwd, @session.pwd)
				else
					system("\"#{Reg.exe}\" \"#{File.escape(@session.pwd)}\" &")
				end
			end
			sub_item.append(sub_item_item)
			sub_item_item = ExplorerMenuItem.new(" Close Window ")
			sub_item_item.signal_connect("activate") do
				@session.main_window.destroy
			end
			sub_item.append(sub_item_item)
		bar.append(item)
			item = ExplorerMenuItem.new("Bookmarks")
				sub_item = Gtk::Menu.new()
				bm = Reg.registry_data["bookmarks"]
				if bm.size > 0
					bm.each do |name, path|
						sub_item_item = ExplorerMenuItem.new(" "+name+" ")
						sub_item_item.signal_connect("activate") do
							@session.chdir(path)
						end
						sub_item.append(sub_item_item)
					end
				else
					sub_item_item = ExplorerMenuItem.new(" Empty ")
					sub_item_item.set_sensitive(false)
					sub_item.append(sub_item_item)
				end
			item.set_submenu(sub_item)
		bar.append(item)
			item = ExplorerMenuItem.new("Go")
				@my_computer = Gtk::Menu.new()
			item.set_submenu(@my_computer)
		bar.append(item)
			item = ExplorerMenuItem.new("Toolbar")
				sub_item = Gtk::Menu.new()
				[
					[" Icon/Text ", Gtk::TOOLBAR_BOTH, true, true],
					[" Icon only ", Gtk::TOOLBAR_ICONS, true, false],
					[" Text only ", Gtk::TOOLBAR_TEXT, false, true]
				].each do |i|
					sub_item_item = ExplorerMenuItem.new(i[0])
					sub_item_item.signal_connect("activate") do
						@session.toolbar.main.set_style(i[1])
						@session.toolbar.queue_resize
					end
					sub_item.append(sub_item_item)
				end
			item.set_submenu(sub_item)
		bar.append(item)
			item = ExplorerMenuItem.new("Help")
				sub_item = Gtk::Menu.new()
					sub_item_item = ExplorerMenuItem.new(" Show all icons ")
					sub_item_item.signal_connect("activate") do show_all_icons() end
				sub_item.append(sub_item_item)
					sub_item_item = ExplorerMenuItem.new(" Font Selection ")
					sub_item_item.signal_connect("activate") do show_font_sel_dialog() end
				sub_item.append(sub_item_item)
					sub_item_item = ExplorerMenuItem.new(" Dump Object ")
					sub_item_item.signal_connect("activate") do dump_object() end
				sub_item.append(sub_item_item)
				sub_item.append(ExplorerMenuItem.new())
					sub_item_item = ExplorerMenuItem.new(" About BSD Explorer ")
					sub_item_item.signal_connect("activate") do show_about() end
				sub_item.append(sub_item_item)
			item.set_submenu(sub_item)
		bar.append(item)
		hbox = Gtk::HBox.new(false, 0)
		hbox.pack_start(bar, true, true, 0)
		evb = Gtk::EventBox.new()
		evb.signal_connect("button_press_event") do show_about end
		banner = Gtk::Pixmap.new(*Reg.core_icons_db.get(15))
		evb.add(banner)
		hbox.pack_start(evb, false, false, 0)
		super()
		add(hbox)
	end
	def build_mycomputer
		@my_computer.children.each do |child| child.destroy end
		if Reg.fs.mount_point.size > 0
			Reg.fs.mount_point.each do |pt|
				item = ExplorerMenuItem.new(" #{pt[1]} (File System: #{pt[2]}) ")
				item.signal_connect("activate") do
					@session.chdir(pt[1])
				end
				item.show
				@my_computer.append(item)
			end
		else
			item = ExplorerMenuItem.new(" Empty ")
			item.set_sensitive(false)
			item.show
			@my_computer.append(item)
		end
	end
	private
	def show_all_icons
		window = Gtk::Window.new(Gtk::WINDOW_TOPLEVEL)
		window.set_title("Registered icons...")
		window.set_usize(500, 120)
		window.realize
		style = window.style.copy
		style.set_bg(Gtk::STATE_NORMAL, 0xffff, 0xffff, 0xffff)
		sw = Gtk::ScrolledWindow.new(nil, nil)
		ev = Gtk::EventBox.new()
		ev.set_style(style)
		hbox = Gtk::HBox.new(false, 0)
		Reg.icons_db.raw.each_with_index do |d, i|
			vb = Gtk::VBox.new(false, 0)
			if d != nil && d.is_a?(Array) && d.size == 2 && d[1]
				vb.pack_start(Gtk::Pixmap.new(*d[1]), false, false, 15)
			else
				vb.pack_start(Gtk::Label.new("Reserved"), false, false, 15)
			end
			vb.pack_start(Gtk::Label.new("#{i}"), false, false, 0)
			hbox.pack_start(vb, false, false, 10)
		end
		ev.add(hbox)
		sw.add_with_viewport(ev)
		sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		window.add(sw)
		window.show_all
	end
	def show_font_sel_dialog
		window = Gtk::FontSelectionDialog.new("Available Fonts...")
		window.set_modal(true)
		window.set_transient_for(@session.main_window)
		window.set_position(Gtk::WIN_POS_CENTER)
		window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
		window.set_policy(false, false, false)
		window.realize
		verbose = $VERBOSE
		$VERBOSE = nil
		window.ok_button.signal_connect("clicked") do window.destroy end
		window.cancel_button.signal_connect("clicked") do window.destroy end
		$VERBOSE = verbose
		window.show
	end
	def show_about
		systext = ""
		if RUBY_PLATFORM =~ /(net|open|free)bsd/i
			mem = ""
			["/sbin", "/usr/sbin"].each do |dir|
				if test(?x, dir+"/sysctl")
					mem = `#{dir}/sysctl -n hw.physmem`.chomp!
					break
				end
			end
			if mem =~ /^\d+$/
				systext = "Physical memory available to BSD Explorer:  #{(mem.to_i / 1024).to_s} KB\n"
			end
		end
		systext += "Ruby version #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM}" \
			+ "\nRuby Gtk version #{Gtk::BINDING_VERSION.join('.')}"
		
		window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
		window.set_modal(true)
		window.set_transient_for(@session.main_window)
		window.set_position(Gtk::WIN_POS_CENTER)
		window.set_policy(false, false, false)
		window.set_title("About BSD Explorer")
		window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
		window.realize

		icon1 = Gtk::Pixmap.new(*Reg.core_icons_db.get(16))
		icon2 = Gtk::Pixmap.new(*Reg.icons_db.get(13))
		label1 = Gtk::Label.new("MyBSD (R) BSD Explorer" \
			+ "\n(#{$EXPLORER_SERVER ? 'Server Mode' : 'Stand Alone Mode'})" \
			+ "\nVersion: #{EXPLORER_VERSION}" \
			+ "\nRelease: (#{EXPLORER_RELEASE}) #{EXPLORER_RELEASE_DATE}" \
			+ "\nCopyright (C) 2001-2002 MyBSD Enterprise")
		label1.jtype = Gtk::JUSTIFY_FILL
		label1.set_alignment(0, 0.5)
		label2 = Gtk::Label.new(systext)
		label2.jtype = Gtk::JUSTIFY_FILL
		label2.set_alignment(0, 0.5)
		hbut = Gtk::HButtonBox.new()
		hbut.set_layout(Gtk::BUTTONBOX_END)
		button = Gtk::Button.new("OK")
		button.signal_connect("clicked") do window.destroy end
		hbut.add(button)

		table = Gtk::Table.new(0, 0, false)
		window.add(table)

		table.attach(icon1, 0, 3, 0, 1) 
		table.attach(icon2, 0, 1, 1, 2)
		table.attach(label1, 1, 3, 1, 2, nil, nil, 10, 20)
		table.attach(Gtk::HSeparator.new(), 1, 3, 2, 3, nil, nil, 10, 0)
		table.attach(label2, 1, 3, 3, 4, nil, nil, 10, 5)
		table.attach(hbut, 2, 3, 4, 5, nil, nil, 5, 5)
		button.set_flags(Gtk::Widget::CAN_DEFAULT)
		button.grab_default

		window.show_all
	end
	def dump_object
		@session.command.explorer_show_info("Object Info:",
			"Total Object(s): #{GC.start ; ObjectSpace.each_object do end}")
	end
end
