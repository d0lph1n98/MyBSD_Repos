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

class ExplorerInfoCanvas
	MAX_WIDTH = 190
	MAX_HEIGHT = 450
	def initialize(session)
		@session = session
		style = @session.main_window.style.copy
		style.set_bg(Gtk::STATE_NORMAL, 0xffff, 0xffff, 0xffff)
		@da = Gtk::DrawingArea.new()
		@da.set_style(style)
		@main = Gtk::ScrolledWindow.new(nil, nil)
		@main.set_usize(MAX_WIDTH+20, -1)
		@main.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
		@main.add_with_viewport(@da)
		@main.children[0].set_shadow_type(0)
		@gc = nil
		@black_gc = nil
		@back_pixmap = nil
		@normal_font = style.font
		@bold_main_title_font = Reg.fonts[0]
		@bold_normal_font = Reg.fonts[1]
		@basic_image = [
			[Reg.core_icons_db.get(13), 0, 0],
			[Reg.core_icons_db.get(14), 0, 80],
		]
		@font_height = @normal_font.ascent + @normal_font.descent
		@basic_icon = []
		@all_text = []
		@main_title = ""
		@basic_title = ""
		@default_basic_title = "Select an item to view its description."
		@preview = nil
		@current_file_stat = nil
		@enable =  Reg.registry_data["left_info_enable"]
		@da.signal_connect("realize") do |w| w.window.set_static_gravities(1) end
	end
	attr_reader :main
	def update(cleanup = false)
		if @enable
			max_x , max_y = MAX_WIDTH, MAX_HEIGHT
			if cleanup
				@basic_title = @default_basic_title
				@current_file_stat = nil
				@all_text.clear
				width = @normal_font.string_width(@basic_title) + 6
				max_x = width if width > max_x
			end
			width = @bold_main_title_font.string_width(@main_title) + 6
			max_x = width if width > max_x
			unless @current_file_stat == nil
				@basic_title = @current_file_stat.entry
				width = @bold_normal_font.string_width(@basic_title) + 6
				max_x = width if width > max_x
			end
			@all_text.each do |l|
				width = @normal_font.string_width(l) + 6
				max_x = width if width > max_x
			end
			max_y = (@all_text.size*@font_height)+115+(@preview == nil ? 0 : @preview[3]+15)
			@da.size(max_x, max_y)
		end
	end
	def show_all
		if @enable
			@da.signal_connect("configure_event") do |w, ev|
				setup(w, ev)
				true
			end
			@da.signal_connect("expose_event") do |w, ev|
				x = ev.area.x
				y = ev.area.y
				width = ev.area.width
				height = ev.area.height
				w.window.draw_pixmap(@gc, @back_pixmap, x, y, x, y, width+2, height+2)
				true
			end
			@main.show_all
		end
	end
	alias show show_all
	def show_stat(item)
		if @enable && (@current_file_stat == nil || @current_file_stat != item)
			@current_file_stat = item
			file = File.join(@session.pwd, item.entry)
			begin
				@all_text.clear
				@all_text.push(item.ftype.info)
				stat = File.lstat(file)
				if stat.mode & 0170000 == 0120000
					@all_text.push("Symbolic link to:", "#{File.readlink(file)}")
				end
				@all_text.push("")
				@all_text.push("Modified:",
					stat.mtime.strftime("%m/%d/%y %I:%M %p").sub(/ 0(\d:\d+) /, ' \1 '), "")
				size = stat.size
				if size < 1024
					@all_text.push(format("Size: %d Bytes", size))
				elsif size < 1024*1024
					@all_text.push(format("Size: %.1f KB", size.to_f/1024))
				else
					@all_text.push(format("Size: %.1f MB", size.to_f/1024/1024))
				end
# XXX
#=begin
				@all_text.push("")
				@all_text.push("Attributes:")
				begin
					owner = Etc.getpwuid(stat.uid).name
				rescue
					owner = stat.uid.to_s
				end
				begin
					group = Etc.getgrgid(stat.gid).name
				rescue
					group = stat.gid.to_s
				end
				@all_text.push("   Owner: #{owner}", "   Group: #{group}")
				@all_text.push("   Mode: "+format("%04o", stat.mode).sub(/.*([\d]{4})$/, '\1'))
#=end
				if Reg.registry_data["image_preview"] && item.entry =~ /\.(jpe?g|tiff?|bmp|xpm|gif|ppm|png|xbm|ico)$/i
					Gtk.update()
					begin
						pb = Gdk::Pixbuf.new(file)
						p_w, p_h = pb.get_width, pb.get_height
						if p_w > 165
							scale = 165.0/p_w
							p_w = 165
							p_h *= scale
							p_h = 1 unless p_h >= 1.0
						end
						if p_w >= 1.0 && p_h >= 1.0
							@preview = pb.scale(p_w, p_h).render_pixmap_and_mask(128)
							@preview.push(p_w, p_h)
						else
							@preview = nil
						end
					rescue
#						func = self.to_s.sub(/.*?<([^:]+?):.*/, '\1') + " : " + "show_stat()"
#						puts "#{func} : #{$!}"
						@preview = nil
					end
				else
					@preview = nil
				end
			rescue
				@all_text.clear
				@current_file_stat = nil
				@preview = nil
				@all_text.push("", "Error:", "#{$!}")
			end
			update
		end
	end
	def remove_stat
		if @enable
			@preview = nil if @preview
			@current_file_stat = nil if @current_file_stat
			update(true)
		end
	end
	def update_after_chdir
		if @enable
			@main_title = File.basename(@session.pwd)
			@main_title = "My Computer" if @main_title == ""
			@basic_icon.clear
			@preview = nil
			@session.item_pwd.icons.each do |i|
				@basic_icon.push([i, 15, 13])
			end
			update(true)
		end
	end
	def reset(str = "Reset...")
		if @enable
			@current_file_stat = nil
			@main_title = ""
			@basic_title = str.to_s
			@all_text.clear
			@basic_icon.clear
			@preview = nil
			@da.size(0, 0)
		end
	end
	private
	def setup(w, ev)
		width, height = w.window.get_size
		@gc = w.style.white_gc if @gc == nil
		@black_gc = w.style.black_gc if @black_gc == nil
		@back_pixmap = Gdk::Pixmap.new(w.window, width, height, -1)
		@back_pixmap.draw_rectangle(@gc, true, 0, 0, width, height)

		@basic_image.each do |i|
			@gc.set_clip_origin(i[1], i[2])
			@gc.set_clip_mask(i[0][1])
			@back_pixmap.draw_pixmap(@gc, i[0][0], 0, 0, i[1], i[2], -1, -1)
		end
		@basic_icon.each do |i|
			@gc.set_clip_origin(i[1], i[2])
			@gc.set_clip_mask(i[0][1])
			@back_pixmap.draw_pixmap(@gc, i[0][0], 0, 0, i[1], i[2], -1, -1)
		end

		@gc.set_clip_mask(nil)
		@gc.set_clip_origin(0, 0)
		@back_pixmap.draw_text(@bold_main_title_font, @black_gc, 5, 70, @main_title)
		@back_pixmap.draw_text(
			@current_file_stat == nil ? @normal_font : @bold_normal_font, @black_gc, 5, 100, @basic_title)
		y = 115
		@all_text.each do |l|
			@back_pixmap.draw_text(
				@normal_font, @black_gc, 5, y, l)
			y += @font_height
		end
		if @preview != nil
			@gc.set_clip_origin(5, y)
			@gc.set_clip_mask(@preview[1])
			@back_pixmap.draw_pixmap(@gc, @preview[0], 0, 0, 5, y, -1, -1)
			@gc.set_clip_mask(nil)
			@gc.set_clip_origin(0, 0)
		end
		GC.start()
	end
end

