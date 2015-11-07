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

class ExplorerCommand
	def initialize(session)
		@session = session
	end
	def explorer_open_with(item)
		window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
		window.set_title("Open With...")
		window.set_position(Gtk::WIN_POS_CENTER)
		window.border_width(5)
		window.set_modal(true)
		window.set_transient_for(@session.main_window)
		window.set_policy(false, false, false)
		window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
		window.realize
		vbox = Gtk::VBox.new(false, 0)
		hbox = Gtk::HBox.new(false, 0)
			table = Gtk::Table.new(0, 0, false)
			item.icons.reverse.each do |i|
				table.attach(Gtk::Pixmap.new(i[0], i[1]), 0, 1, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 10, 10)
			end
		hbox.pack_start(table, false, false, 0)
		label = Gtk::Label.new("Open this file using:")
		hbox.pack_start(label, false, false, 0)
		vbox.pack_start(hbox, false, false, 0)
		combo = Gtk::Combo.new()
		combo.disable_activate()
		apps = []
		if item.ftype.apps.is_a?(Array)
			apps += item.ftype.apps
		end
		apps += Reg.registry_data["default_apps"]
		apps.compact!
		apps.uniq!
		combo.set_popdown_strings(apps) if apps.size > 0
		combo.set_usize(350, -1)
		combo.entry.signal_connect("activate") do
			cmd = combo.entry.get_text
			window.destroy
			if cmd.is_a?(String) && cmd.length > 0
				explorer_open_file(cmd, item.entry)
			end
		end
		vbox.pack_start(combo, false, false, 0)
		hbbox = Gtk::HButtonBox.new()
		hbbox.set_layout(Gtk::BUTTONBOX_END)
		hbbox.set_spacing(5)
		button = Gtk::Button.new("OK")
		button.signal_connect("clicked") do
			cmd = combo.entry.get_text
			window.destroy
			if cmd.is_a?(String) && cmd.length > 0
				explorer_open_file(cmd, item.entry)
			end
		end
		hbbox.add(button)
		button = Gtk::Button.new("Cancel")
		button.signal_connect("clicked") do window.destroy end
		hbbox.add(button)
		button = Gtk::Button.new("Other...")
		button.signal_connect("clicked") do
			$VERBOSE = nil
			fsel = Gtk::FileSelection.new("Select file...")
			fsel.signal_connect("destroy") do fsel.destroy end
			fsel.set_policy(false, false, false)
			fsel.cancel_button.signal_connect("clicked") do fsel.destroy end
			fsel.ok_button.signal_connect("clicked") do
				combo.entry.set_text(fsel.get_filename)	if test(?f, fsel.get_filename)
				fsel.destroy
			end
			fsel.set_modal(true)
			fsel.set_transient_for(window)
			fsel.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
			fsel.show_all
			$VERBOSE = true
		end
		hbbox.add(button)
		vbox.pack_start(hbbox, false, false, 10)
		window.add(vbox)
		combo.entry.grab_focus
		window.show_all
	end
	def explorer_popup(item)
		is_dir = item.smode == 0040000
		is_pwd = is_dir && item.entry == "."
		has_apps = !is_dir && item.ftype.apps.is_a?(Array) && item.ftype.apps.size > 0
		file = File.join(@session.pwd, item.entry).gsub(/\/+/, '/')
		menu = Gtk::Menu.new()
		menu.signal_connect("selection-done") do menu.destroy end
			
		if is_dir || has_apps
			if is_pwd
				menuitem = ExplorerMenuItem.new("   Reload   ")
				menuitem.signal_connect("activate") do
					@session.chdir(item.entry)
				end
				menu.append(menuitem)
				menuitem = ExplorerMenuItem.new("   Refresh   ")
				menuitem.signal_connect("activate") do @session.canvas.canvas_refresh() end
				menu.append(menuitem)
				menuitem = ExplorerMenuItem.new("   Sort by...  ")
				sub_menu = Gtk::Menu.new()
				menuitem.set_submenu(sub_menu)
				menu.append(menuitem)
				menuitem = ExplorerMenuItem.new("   File Type   ")
				menuitem.signal_connect("activate") do
					@session.canvas.sort_type = 0
					@session.canvas.canvas_refresh(true)
				end
				sub_menu.append(menuitem)
				menuitem = ExplorerMenuItem.new("   Directory First    ")
				menuitem.signal_connect("activate") do
					@session.canvas.sort_type = 1
					@session.canvas.canvas_refresh(true)
				end
				sub_menu.append(menuitem)
				menuitem = ExplorerMenuItem.new("   Name   ")
				menuitem.signal_connect("activate") do
					@session.canvas.sort_type = 2
					@session.canvas.canvas_refresh(true)
				end
				sub_menu.append(menuitem)
			else
				menuitem = ExplorerMenuItem.new("   Open   ")
				menuitem.signal_connect("activate") do
					if is_dir
						@session.chdir(item.entry)
					else
						explorer_open_file(item.ftype.apps[0], item.entry)
					end
				end
				menu.append(menuitem)
			end
		end
	
		if !is_dir && test(?x, file)
			menuitem = ExplorerMenuItem.new("   Execute (DANGER!)   ")
			menuitem.signal_connect("activate") do
				system("cd \"#{File.dirname(file)}\" ; \"#{File.escape(file)}\" &")
			end
			menu.append(menuitem)
		end
		menuitem = ExplorerMenuItem.new("   Open With...   ")
		sub_menu = Gtk::Menu.new()
		menuitem.set_submenu(sub_menu)
		menu.append(menuitem)
			menuitem = ExplorerMenuItem.new("   Enter Command...   ")
			menuitem.signal_connect("activate") do explorer_open_with(item) end
			sub_menu.append(menuitem)
		if has_apps
			sub_menu.append(ExplorerMenuItem.new())
			item.ftype.apps.each do |i|
				menuitem = ExplorerMenuItem.new("   "+i+"   ")
				menuitem.signal_connect("activate") do
					explorer_open_file(i, item.entry)
				end
				sub_menu.append(menuitem)
			end
		end
		default_apps = Reg.registry_data["default_apps"]
		if default_apps.size > 0
			sub_menu.append(ExplorerMenuItem.new())
			default_apps.each do |i|
				menuitem = ExplorerMenuItem.new("   "+i+"   ")
				menuitem.signal_connect("activate") do
					explorer_open_file(i, item.entry)
				end
				sub_menu.append(menuitem)
			end
		end
	
		if is_dir
			menuitem = ExplorerMenuItem.new("   New Window   ")
			menuitem.signal_connect("activate") do
				todir = File.expand_path(item.entry, @session.pwd)
				if $EXPLORER_SERVER
					@session.ipc_send(todir, @session.pwd)
				else
					system("\"#{Reg.exe}\" \"#{File.escape(todir)}\" &")
				end
			end
			menu.append(menuitem)
			menuitem = ExplorerMenuItem.new("   Open Terminal Emulator   ")
			menuitem.signal_connect("activate") do
				system("cd \"#{File.escape(file)}\" ; #{Reg.registry_data['default_xterm']} &")
			end
			menu.append(menuitem)
		end
	
		menu.append(ExplorerMenuItem.new())
		menuitem = ExplorerMenuItem.new("   Send To   ")
		menu.append(menuitem)
		menu.append(ExplorerMenuItem.new())
		menuitem = ExplorerMenuItem.new("   Cut   ")
		menu.append(menuitem)
		menuitem = ExplorerMenuItem.new("   Copy   ")
		menu.append(menuitem)
		menu.append(ExplorerMenuItem.new())
		menuitem = ExplorerMenuItem.new("   Create Symlink   ")
		menu.append(menuitem)
		menuitem = ExplorerMenuItem.new("   Delete   ")
		menuitem.signal_connect("activate") do
			if is_pwd
				explorer_error("Cannot delete current working directory!")
			else
				explorer_delete_file(item)
			end
		end
		menu.append(menuitem)
		menuitem = ExplorerMenuItem.new("   Rename   ")
		menu.append(menuitem)
		menu.append(ExplorerMenuItem.new())
		if is_pwd
			menuitem = ExplorerMenuItem.new("   New   ")
			menu.append(menuitem)
			sub_menu = Gtk::Menu.new()
			menuitem.set_submenu(sub_menu)
			menuitem = ExplorerMenuItem.new("   Directory   ")
			menuitem.signal_connect("activate") do
				window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
				window.signal_connect("destroy") do window.destroy end
				window.set_position(Gtk::WIN_POS_CENTER)
				window.set_title("New Directory...")
				window.set_policy(false, false, false)
				window.set_modal(true)
				window.set_transient_for(@session.main_window)
				window.border_width(5)
				window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
				window.realize
				vbox = Gtk::VBox.new(false, 0)
				hbox = Gtk::HBox.new(false, 0)
				icon = Gtk::Pixmap.new(*Reg.icons_db.get(1))
				hbox.pack_start(icon, false, false, 5)
				label = Gtk::Label.new("Directory: ...").set_justify(Gtk::JUSTIFY_LEFT)
				hbox.pack_start(label, false, false, 5)
				vbox.pack_start(hbox, false, false, 5)
				entry = Gtk::Entry.new()
				entry.set_usize(350, -1)
				vbox.pack_start(entry, false, false, 5)
				hbbox = Gtk::HButtonBox.new()
				hbbox.set_spacing(5)
				hbbox.set_layout(Gtk::BUTTONBOX_END)
				button = Gtk::Button.new("Clear")
				button.signal_connect("clicked") do entry.set_text("") end
				hbbox.add(button)
				button = Gtk::Button.new("Ok")
				button.signal_connect("clicked") do
					newdir = entry.get_text
					window.destroy
					if newdir.length > 0
						if newdir[0].chr == "/"
							newdir = File.expand_path(newdir, "/")
						else
							newdir = File.expand_path(
								(@session.pwd + "/" + newdir).gsub(/\/+/, '/').sub(/\/$/, ''),
								@session.pwd
							)
						end
						begin
							Dir.mkdir(newdir)
							if File.dirname(newdir) == @session.pwd
								@session.dir_db.push(@session.item_seek(newdir, File.basename(newdir)))
								@session.canvas.canvas_refresh(true)
							end
						rescue
							explorer_error($!)
						end
					end
				end
				hbbox.add(button)
				button = Gtk::Button.new("Cancel")
				button.signal_connect("clicked") do window.destroy end
				hbbox.add(button)
				vbox.pack_start(hbbox, false, false, 5)
				window.add(vbox)
				entry.grab_focus
				window.show_all
			end
			sub_menu.append(menuitem)
			menuitem = ExplorerMenuItem.new("   File   ")
			sub_menu.append(menuitem)
			menu.append(ExplorerMenuItem.new())
		end
		menuitem = ExplorerMenuItem.new("   Properties   ")
		menu.append(menuitem)
		menu.show_all
	end
	def explorer_error(msg = "Unknown Error")
		window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
		window.set_policy(false, false, false)
		window.set_position(Gtk::WIN_POS_CENTER)
		window.border_width(5)
		window.set_title("Explorer Error:")
		window.set_modal(true)
		window.set_transient_for(@session.main_window)
		window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
		window.realize

		table = Gtk::Table.new(0, 0, false)
		table.attach(Gtk::Pixmap.new(*Reg.icons_db.get(16)),
			0, 1, 0, 1, nil, nil, 5, 5)
		table.attach(Gtk::Label.new(msg.to_s).set_justify(Gtk::JUSTIFY_FILL),
			1, 2, 0, 1, nil, nil, 5, 5)
		hbut = Gtk::HButtonBox.new()
		button = Gtk::Button.new("OK")
		button.set_flags(Gtk::Widget::CAN_DEFAULT)
		button.signal_connect("clicked") do window.destroy end
		hbut.add(button)
		table.attach(hbut, 0, 2, 1, 2, nil, nil, 5, 5)
		window.add(table)
		button.grab_default
		window.show_all
	end
	def explorer_yes_no(title = "Warning:", msg = "Are you sure?", icon_index = 15)
		ret = false
		window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
		window.signal_connect("destroy") do
			window.destroy
			yield if ret
		end
		window.set_policy(false, false, false)
		window.border_width(5)
		window.set_position(Gtk::WIN_POS_CENTER)
		window.set_modal(true)
		window.set_transient_for(@session.main_window)
		window.set_title(title)
		window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
		window.realize
	
		table = Gtk::Table.new(0, 0, false)
		table.attach(Gtk::Pixmap.new(*Reg.icons_db.get(icon_index)), 0, 1, 0, 1, nil, nil, 5, 5)
		label = Gtk::Label.new(msg)
		label.jtype = Gtk::JUSTIFY_FILL
		table.attach(
			label,
			1, 3, 0, 1, nil, nil, 5, 5)

		hbut = Gtk::HButtonBox.new()
		hbut.set_layout(Gtk::BUTTONBOX_END)
		hbut.set_spacing(1)
		button = Gtk::Button.new("OK")
		button.set_flags(Gtk::Widget::CAN_DEFAULT)
		button.signal_connect("clicked") do ret = true ; window.destroy end
		hbut.add(button)
		button = Gtk::Button.new("Cancel")
		button.set_flags(Gtk::Widget::CAN_DEFAULT)
		button.signal_connect("clicked") do window.destroy end
		hbut.add(button)
		table.attach(hbut, 1, 4, 1, 2, nil, nil, 5, 5)
	
		window.add(table)
		button.grab_default
		window.show_all
	end
	def explorer_delete_file(item)
		filename = item.entry.dup
		while @session.canvas.string_width(filename) > 160
			filename.gsub!(/....$/, '...')
		end
		explorer_yes_no("Confirm File Delete", "Are you sure you want to delete \"#{filename}\"?", 128) do
			explorer_yes_no("Last WARNING!", "WARNING: Fatal operation!\nProceed with file deletion?") do
				@session.canvas.canvas_remove_item(item)
			end
		end
	end
	def explorer_open_file(prog, file)
		openfile = File.expand_path(File.join(@session.pwd, file)).gsub(/\/+/, '/')
		begin
			if test(?l, openfile)
				realfile = File.realpath(openfile)
				is_l = true
			else
				realfile = openfile
				is_l = false
			end
			if !test(?e, realfile)
				if is_l
					raise "Broken symbolic link"
				else
					raise "File not exist"
				end
			elsif !test(?r, realfile)
				raise "Permission denied"
			elsif !(test(?f, realfile) || test(?d, realfile))
				raise "Not a regular file/directory"
			end
			prog_final = Reg.registry_data["apps_directory"] + "/" + prog
			prog_final = prog unless test(?x, prog_final)
			system("cd \"#{File.escape(@session.pwd)}\" ; #{prog_final} \"#{File.escape(openfile)}\" &")
		rescue
			explorer_error("#{$!} - \"#{file}\"")
		end
	end
	def explorer_show_info(title = "Info:", msg = "Info")
		window = Gtk::Window.new(Gtk::WINDOW_DIALOG)
		window.set_policy(false, false, false)
		window.set_position(Gtk::WIN_POS_CENTER)
		window.border_width(5)
		window.set_title(title)
		window.set_modal(true)
		window.set_transient_for(@session.main_window)
		window.set_wmclass("BSD_EXPLORER_DIALOG", "BSD_EXPLORER_DIALOG")
		window.realize

		table = Gtk::Table.new(0, 0, false)
		table.attach(Gtk::Pixmap.new(*Reg.icons_db.get(18)), 0, 1, 0, 1, nil, nil, 5, 5)
		table.attach(Gtk::Label.new(msg).set_justify(Gtk::JUSTIFY_FILL),
			1, 2, 0, 1, nil, nil, 5, 5)
		hbut = Gtk::HButtonBox.new()
		button = Gtk::Button.new("OK")
		button.set_flags(Gtk::Widget::CAN_DEFAULT)
		button.signal_connect("clicked") do window.destroy end
		hbut.add(button)
		table.attach(hbut, 0, 2, 1, 2, nil, nil, 5, 5)
		window.add(table)
		button.grab_default
		window.show_all
	end
end
