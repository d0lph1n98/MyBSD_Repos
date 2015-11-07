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

class ExplorerCanvas
	def initialize(session)
		@session = session
		@da = Gtk::DrawingArea.new()
		@main = Gtk::ScrolledWindow.new(nil, nil)
		@main.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC)
		@vadj = @main.vadjustment
		@gdkwin = nil
		@static_gravities = 1
		@last_vscroll = 0
		@freeze = true
		@upper = 0
		@style = @session.main_window.style.copy
		@style.set_bg(Gtk::STATE_NORMAL, 0xffff, 0xffff, 0xffff)
		@font = @style.font

		diff = 2
		@icon_width = Reg.registry_data["icon_width"]
		@icon_height = Reg.registry_data["icon_height"]
		@font_ascent = @font.ascent
		@font_descent = @font.descent
		@font_height = @font_ascent + @font_descent
		@max_font_height = @font_height * 2
		@text_truncate = @font.string_width("developers-han")
		if @icon_width > @text_truncate
			@item_width = @icon_width + (diff*4)
		else
			@item_width = @text_truncate + (diff*4)
		end
		@item_height = diff + @icon_height + 1 + @max_font_height + @font_descent + diff
		@icon_x_leaf = (@item_width - @icon_width) / 2
		@icon_y_leaf = diff
		@text_y_leaf = diff + @icon_height + 1 + @font_ascent

		@width = 0
		@height = 0
		@selection = []
		@dir_db = @session.dir_db
		@dir_db_size = 0
		@icons_db = Reg.icons_db
		@ftype_db = Reg.ftype_db
		@max_col = 0
		@edge = 0
		@start_item = 0
		@last_item = 0
		@empty = true

		@gc_fg = nil
		@gc_bg = nil
		@gc_dash = nil
		@gc_line = nil
		@gc_black = nil
		@gc_white = nil
		@gc_icon = nil
		@gc_ex = nil

		@da.set_style(@style)
		@da.set_events(Gdk::BUTTON_PRESS_MASK|Gdk::BUTTON_RELEASE_MASK)
		@sig_realize_id = 0
		@sig_configure_id = 0
		@sig_expose_id = 0
		@sig_button_press_id = 0
		@sig_key_press_id = 0
		@sig_vadj_value_changed_id = 0
		@sig_realize_id = @da.signal_connect_after("realize") do
			@da.signal_disconnect(@sig_realize_id)
			setup_init()
			signal_connect_init()
		end
		@pt = []
		@draw_start = 0
		@draw_last = 0
		@buf = nil
		@sort_type = 0
		@scroll_percentage = 0.0
		@main.add(@da)
		@blocked = false
	end
	attr_reader :main, :da
	public
	def show
		@main.show_all
	end
	def handler_block
		if ! @blocked
			@blocked = true
			@da.signal_handler_block(@sig_configure_id)
			@da.signal_handler_block(@sig_expose_id)
			@da.signal_handler_block(@sig_button_press_id)
			@vadj.signal_handler_block(@sig_vadj_value_changed_id)
		end
	end
	def handler_unblock
		if @blocked
			@blocked = false
			@da.signal_handler_unblock(@sig_configure_id)
			@da.signal_handler_unblock(@sig_expose_id)
			@da.signal_handler_unblock(@sig_button_press_id)
			@vadj.signal_handler_unblock(@sig_vadj_value_changed_id)
		end
	end
	private
	def setup_init
		@gdkwin = @da.window
		@gdkwin.set_static_gravities(@static_gravities)
		@width, @height = @gdkwin.get_size
		@upper = @height
		@gc_fg = [@style.fg_gc(Gtk::STATE_NORMAL), @style.fg_gc(Gtk::STATE_SELECTED)]
		@gc_bg = [@style.bg_gc(Gtk::STATE_NORMAL), @style.bg_gc(Gtk::STATE_SELECTED)]
		@gc_black = @style.black_gc
		@gc_white = @style.white_gc
		@gc_ex = Gdk::GC.new(@gdkwin)
		@gc_ex.copy(@style.white_gc)
		@gc_ex.set_exposures(1)
		@gc_dash = Gdk::GC.new(@gdkwin)
		@gc_dash.set_dashes(0, [1, 1])
		@gc_dash.set_line_attributes(1, Gdk::LINE_ON_OFF_DASH, Gdk::CAP_BUTT, Gdk::JOIN_MITER)
		color = Gdk::Color.new(0xffff, 0xe38d, 0x9e79)
		cmap = Gdk::Colormap.get_system()
		cmap.alloc_color(color, true, true)
		@gc_dash.set_foreground(color)

		@gc_icon = Gdk::GC.new(@gdkwin)
		@gc_icon.set_fill(Gdk::STIPPLED)
		@gc_icon.set_stipple(Gdk::Bitmap.create_from_data(@gdkwin, "\001\002", 2, 2))
		@gc_icon.set_foreground(@style.bg(Gtk::STATE_SELECTED))
		@gc_icon.set_background(@style.bg(Gtk::STATE_SELECTED))

		@gc_line = [@gc_bg[0], @gc_dash]
		@vadj.step_increment = 5
		@vadj.page_increment = (@item_height * 0.5).to_i
		@vadj.page_size = @height
		@sig_vadj_value_changed_id = @vadj.signal_connect("value_changed") do
			canvas_vscroll(@vadj.value.to_i)
			true
		end
	end
	def signal_connect_init
			@sig_configure_id = @da.signal_connect("configure_event") do |w, ev|
				canvas_configure() unless @freeze
			end
			@sig_expose_id = @da.signal_connect("expose_event") do |w, ev|
				unless @freeze
					x, y, width, height = ev.area.x , ev.area.y, ev.area.width, ev.area.height
					if x == 0 && y == 0 && width >= @width && height >= @height
						@draw_start = @start_item
						@draw_last = @last_item
						canvas_expose_full()
					else
						start_line = (y + @last_vscroll) / @item_height
						last_line = (y + height - 1 + @last_vscroll) / @item_height
						start_col = x / @item_width
						last_col = (x + width - 1) / @item_width
						(start_line .. last_line).each do |y_s|
							(start_col .. last_col).each do |x_s|
								num = ( y_s * @max_col) + x_s
								if (@start_item .. @last_item) === num && (item = @dir_db[num])
									canvas_draw_single_item(item, false)
								end
							end
						end
					end
				end
			end
			@sig_button_press_id = @da.signal_connect("button_press_event") do |w, ev|
				canvas_button_press(ev) unless @freeze
				true
			end
	end
	def canvas_configure_item(item)
		if (item.entry_width = @font.string_width(item.entry)) > @text_truncate
			item.truncate = [["", 0], ["", 0]]
			line = 0
			item.entry.each_byte do |c|
				size = @font.char_width(c)
				if item.truncate[line][1]+size > @text_truncate
					if line > 0
						item.truncate[1][0][-3, 3] = "..."
						item.truncate[1][1] = @font.string_width(item.truncate[1][0])
						break
					end
					item.entry_width = item.truncate[0][1]
					line += 1
				end
				item.truncate[line][0] << c
				item.truncate[line][1] += size
			end
			item.entry_width = item.truncate[1][1] if item.truncate[1][1] > item.entry_width
			item.text_height = @max_font_height
		else
			item.text_height = @font_height
		end
		item.ftype.icons.each do |i|
			item.icons << @icons_db.get(i)
		end
		item.icons << @icons_db.get(2) if item.lsmode == 0120000
	end
	def canvas_draw_single_item(item, clear = false, win = @gdkwin)
		canvas_configure_item(item) unless item.entry_width
		icon_xpos = item.x + @icon_x_leaf
		icon_ypos = item.y + @icon_y_leaf - @last_vscroll
		text_ypos = item.y + @text_y_leaf - @last_vscroll
		text_box_xpos = item.x+((@item_width - item.entry_width)/2)
		idx = item.selected
		@gc_icon.set_clip_origin(icon_xpos, icon_ypos)
		item.icons.each do |pixmap, mask|
			@gc_icon.set_clip_mask(mask)
			win.draw_pixmap(@gc_icon, pixmap, 0, 0, icon_xpos, icon_ypos, -1, -1)
			if idx == 1
				win.draw_rectangle(@gc_icon, true, icon_xpos, icon_ypos, @icon_width, @icon_height)
			end
		end
		if clear || idx == 1
			win.draw_rectangle(
				@gc_bg[idx], true, text_box_xpos-2,
				text_ypos-@font_ascent, item.entry_width+4, item.text_height+@font_descent
			).draw_rectangle(
				@gc_line[idx], false, text_box_xpos-2,
				text_ypos-@font_ascent, item.entry_width+3, item.text_height+@font_descent-1)
		end
		if item.truncate
			win.draw_text(@font, @gc_fg[idx],
				item.x+((@item_width - item.truncate[0][1])/2), text_ypos, item.truncate[0][0]
			).draw_text(@font, @gc_fg[idx],
				item.x+((@item_width - item.truncate[1][1])/2), text_ypos+@font_height, item.truncate[1][0])
		else
			win.draw_text(@font, @gc_fg[idx],
				text_box_xpos, text_ypos, item.entry)
		end
	end
	def canvas_expose(win = @gdkwin)
		@start_item.upto(@last_item) do |index|
			if (item = @dir_db[index])
				canvas_draw_single_item(item, false, win) if (@draw_start .. @draw_last) === index
			end
		end
	end
	def canvas_expose_full
		@buf = Gdk::Pixmap.new(@gdkwin, @width, @height, -1)
		@buf.draw_rectangle(@gc_bg[0], true, 0, 0, @width, @height)
		canvas_expose(@buf)
		@gdkwin.draw_pixmap(@gc_bg[0], @buf, 0, 0, 0, 0, -1, -1)
		@buf = nil
		GC.start()
	end
	def canvas_replot
		x = 0
		y = 0
		for i in @dir_db
			if i
				i.x = x
				i.y = y
			end
			x += @item_width
			if x >= @edge
				x = 0
				y += @item_height
			end
		end
	end
	def canvas_vscroll(val)
		if (diff = val - @last_vscroll) != 0
			@start_item = val / @item_height * @max_col
#			@last_item = ((val + @height) / @item_height * @max_col) + @max_col
			@last_item = ((val + @height - 1) / @item_height * @max_col) + @max_col
			@last_item = @dir_db_size if @last_item > @dir_db_size
			@last_item -= 1
			@scroll_percentage = 1.0 * val / (@upper - @height)
			@last_vscroll = val
			if diff > 0
#				puts "Scroll down?"
				amount = diff
				from_y = amount
				to_y = 0
				clear_y = @height - amount
				clear_y = 0 if clear_y < 0
				@draw_start = ((val + clear_y) / @item_height * @max_col)
				@draw_last = @last_item
			else
#				puts "Scroll up?"
				amount = - diff
				from_y = 0
				to_y = amount
				clear_y = 0
				@draw_start = @start_item
				@draw_last = ((val + amount)/ @item_height * @max_col) + @max_col - 1
			end
			if amount < @height
				@gdkwin.draw_pixmap(@gc_ex, @gdkwin, 0, from_y, 0, to_y, @width, @height - amount)
				clear_amount = amount
			else
				clear_amount = @height
			end
			@gdkwin.clear_area(0, clear_y, -1, clear_amount)
			canvas_expose()
			@da.scroll_flush()
		end
	end
	def canvas_count_size
		old_max_col = @max_col
		@width, @height = @gdkwin.get_size
		@max_col = @width / @item_width
		@max_col = 1 unless @max_col > 0
		@edge = @max_col * @item_width
#		@upper = (@dir_db_size / @max_col * @item_height) + (@dir_db_size % @max_col > 0 ? @item_height : 0)
		@upper = (@dir_db_size + @max_col - 1) / @max_col * @item_height

		@last_vscroll = (@upper > @height) ? (@scroll_percentage*(@upper-@height)).to_i : 0
		@start_item = @last_vscroll / @item_height * @max_col
#		@last_item = ((@last_vscroll + @height) / @item_height * @max_col) + @max_col
		@last_item = ((@last_vscroll + @height - 1) / @item_height * @max_col) + @max_col
		@last_item = @dir_db_size if @last_item > @dir_db_size
		@last_item -= 1
		@draw_start = @start_item
		@draw_last = @last_item
		if old_max_col != @max_col
			canvas_replot()
		end
	end
	def canvas_configure
		canvas_count_size()
		if  @vadj.upper.to_i != @upper || @vadj.page_size.to_i != @height || @vadj.value.to_i != @last_vscroll
			@vadj.upper = @upper
			@vadj.page_size = @height
			@vadj.value = @last_vscroll
			@vadj.page_increment = @height * 3 / 4
			@vadj.changed()
		end
	end
	def canvas_button_press(ev)
		button = ev.button
		time = ev.time
		xpos = ev.x.to_i
		ypos = ev.y.to_i
		event_type = ev.event_type
#		num = (@max_col*((ypos/@item_height)+(@vadj.value/@item_height)).to_i)+((xpos/@item_width)+(0/@item_width)).to_i
		at_col = xpos / @item_width
		at_line = (ypos + @last_vscroll) / @item_height
		num = (at_line * @max_col) + at_col
		found = false
		item = @dir_db[num]
		if item && num < @dir_db_size && item.x && item.y
			xdif = item.x + @icon_x_leaf + @icon_width - xpos
			ydif = item.y + @icon_y_leaf + @icon_height - ypos - @last_vscroll
			if xdif > 1.0 && xdif <= @icon_width + 1 && ydif > 0.0 && ydif <= @icon_height + 1
				found = true
			end
			unless found
				xdif = item.x + ((@item_width - item.entry_width)/2) + item.entry_width - xpos
				ydif = item.y + @text_y_leaf + item.text_height - @font_height - ypos - @last_vscroll
				if xdif >= 1.0 && xdif <= item.entry_width + 1 && ydif > 1.0 && ydif <= item.text_height + 1
					found = true
				end
			end
			if found
				@pt << num
				if event_type == Gdk::BUTTON2_PRESS &&
					@pt.size > 2 && @pt[-1] == @pt[-2] && @pt[-2] == @pt[-3]
					double_click = true
				else
					double_click = false
				end
				@pt.shift if @pt.size > 2
				@selection.compact!
				@selection.uniq!
				@selection.each do |key|
					next if key == num
					if (delete_item = @dir_db[key])
						delete_item.selected = 0
						if (@start_item .. @last_item) === key
							canvas_draw_single_item(delete_item, true)
						end
					end
				end
				@selection.delete_if do |key|
					key != num
				end
				if button == 1
					if double_click
						if item.smode == 0040000
							@session.chdir(item.entry)
						else
							if item.selected == 0
								item.selected = 1
								canvas_draw_single_item(item, true)
								@selection << num
								@selection.compact!
								@selection.uniq!
							end
							apps = item.ftype.apps
							if apps.is_a?(Array) && apps.size > 0
								@session.command.explorer_open_file(apps[0], item.entry)
							else
								@session.command.explorer_open_with(item)
							end
						end
					else
						if item.selected == 1 && event_type == Gdk::BUTTON_PRESS
							item.selected = 0
							canvas_draw_single_item(item, true)
							@selection.delete(num)
						else
							item.selected = 1
							canvas_draw_single_item(item, true)
							@session.info_canvas.show_stat(item)
							@selection << num
							@selection.compact!
							@selection.uniq!
						end
					end
				elsif button == 3
					item.selected = 1
					canvas_draw_single_item(item, true)
					@session.command.explorer_popup(item).popup(nil, nil, nil, button, time)
					@session.info_canvas.show_stat(item) unless @selection[-1] == num
					@selection << num
					@selection.compact!
					@selection.uniq!
				end
			end
		end
		unless found
			@pt.clear
			@session.info_canvas.remove_stat
			@selection.compact!
			@selection.uniq!
			@selection.each do |key|
				if (item = @dir_db[key])
					item.selected = 0
					if (@start_item .. @last_item) === key
						canvas_draw_single_item(item, true)
					end
				end
			end
			@selection.clear
			if button == 3
				@session.command.explorer_popup(@session.item_pwd).popup(nil, nil, nil, button, time)
			end
		end
	end
	public
	def canvas_reinit_pre
		handler_block()
		@freeze = true
		@gdkwin.clear()
		@selection.each do |i|
			if (item = @dir_db[i])
				item.selected = 0
			end
		end
		@dir_db_size = 0
		@max_col = 0
		@selection.clear
		@pt.clear
		@session.toolbar.update_stack
		@session.status_label.set_text("")
		@session.addressbar.set_entry()
		@session.info_canvas.reset("")
		@session.main_window.set_title("Explorer: #{@session.pwd} (Scanning...)")
		@vadj.upper = 0.0
		@vadj.value = 0.0
		@vadj.page_size = 0.0
		@vadj.page_increment = 0.0
		@vadj.changed()
	end
	def canvas_reinit_post
		sort_items()
		@dir_db_size = @dir_db.size
		@last_vscroll = 0
		@scroll_percentage = 0.0
		@session.menubar.build_mycomputer()
		@session.status_label.set_text("#{@dir_db_size} Item(s)  Interval: #{@session.duration} second(s)")
		@session.main_window.set_title("Explorer: #{@session.pwd}")
		@gdkwin.clear()
		@session.info_canvas.update_after_chdir()
		@freeze = false
		@session.toolbar_stop = false
		@session.toolbar.chdir_post()
		@da.queue_resize
		handler_unblock()
		pos = 0
		@session.idle_id = Gtk.idle_add do
			if @session.idle_id == 0
				false
			elsif pos < @dir_db_size
				item = @dir_db[pos]
				canvas_configure_item(item) unless item.entry_width
				pos += 1
				true
			else
				Gtk.idle_remove(@session.idle_id)
				@session.idle_id = 0
				false
			end
		end
	end
	def canvas_remove_item(item)
		begin
			raise "Directory deletion not implemented yet!" if item.smode == 0040000
			raise "File deletion is prohibited.\nReason: Safe File Deletion currently DISABLED" \
				unless Reg.registry_data["safe_file_deletion"]
			File.unlink(item.path)
			@dir_db[@selection[-1]] = nil
			@selection.clear
			canvas_refresh(false)
		rescue
			@session.command.explorer_error($!)
		end
	end
	def canvas_refresh(need_sort = false)
		@freeze = true
		@gdkwin.clear()
		@pt.clear
		@dir_db.compact!
		if need_sort
			sort_items()
			canvas_replot()
		end
		@dir_db_size = @dir_db.size
		canvas_configure()
		canvas_expose_full()
		@freeze = false
	end
	def sort_items
#		$= = true
		case @sort_type
			when 0
				sort_by_type()
			when 1
				sort_dir_first()
			else
				sort_by_name()
		end
#		$= = false
	end
	def string_width(str)
		@font.string_width(str)
	end
	def char_width(chr)
		@font.char_width(chr)
	end
	private
	def sort_dir_first
		@dir_db.sort! do |a, b|
			amode, bmode = a.smode, b.smode
			if amode == 0040000 && bmode == 0040000
				a.entry.casecmp(b.entry)
			elsif amode == 0040000
				-1
			elsif bmode == 0040000
				1
			else
				a.entry.casecmp(b.entry)
			end
		end
	end
	def sort_by_type
		@dir_db.sort! do |a, b|
			ast = a.f_stat
			bst = b.f_stat
			if ast.file? && bst.file?
				if a.ext == b.ext
					a.entry.casecmp(b.entry)
				elsif !a.ext
					1
				elsif !b.ext
					-1
				else
					a.ext <=> b.ext
				end
			elsif a.smode == b.smode
				a.entry.casecmp(b.entry)
			elsif ast.directory?
				-1
			elsif bst.directory?
				1
			elsif ast.file?
				-1
			elsif bst.file?
				1
			elsif ast.blockdev?
				-1
			elsif bst.blockdev?
				1
			elsif ast.chardev?
				-1
			elsif bst.chardev?
				1
			elsif ast.pipe?
				-1
			elsif bst.pipe?
				1
			elsif ast.socket?
				-1
			elsif bst.socket?
				1
			else
				0
			end
		end
	end
	def sort_by_name
		@dir_db.sort! do |a, b|
#			a.entry <=> b.entry
			a.entry.casecmp(b.entry)
		end
	end
	public
	def canvas_destroy
		@gc_ex.destroy
		@gc_dash.destroy
		@gc_icon.destroy
	end
	attr_accessor :sort_type
end
