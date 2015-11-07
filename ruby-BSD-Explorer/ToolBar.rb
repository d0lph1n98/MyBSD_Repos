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

class ExplorerToolBar < Gtk::HandleBox
	def initialize(session)
		@session = session
		@main = Gtk::Toolbar.new(Gtk::ORIENTATION_HORIZONTAL, Gtk::TOOLBAR_BOTH)
		@main.border_width(4)
		@main.set_button_relief(Gtk::RELIEF_NONE)
		@main.set_space_style(Gtk::Toolbar::SPACE_LINE)
		[
			["Back", "Back to previous location", 0, 0],
			["Forward", "Forward to next location", 1, 1],
			["Up", "Up to higher level", 2, 2],
			nil,
			["Home", "Home directory", 3, 3],
			["Reload", "Reload current directory", 4, 4],
			["Stop", "Stop current operaion", 5, 5],
			nil,
			["Cut", "Cut current selected object", 6, 6],
			["Copy", "Copy current selected object", 7, 7],
			["Paste", "Paste object from clipboard", 8, 8],
			nil,
			["Undo", "Undo last action", 9, 9],
			nil,
			["Delete", "Delete current selected object", 10, 10],
			["Properties", "File properties", 11, 11],
			nil,
			["View", "Change view mode", 12, 12],
		].each do |i|
			if i == nil
				@main.append_space
			else
				@main.append_item(i[0], i[1], nil, Gtk::Pixmap.new(*Reg.core_icons_db.get(i[2])), nil) do |w|
					w.set_sensitive(false)
					do_func(i[3])
				end
			end
		end
		@child = @main.children
		[0, 1, 2].each do |c| @child[c].set_sensitive(false) end
		@back_stack = []
		@forward_stack = []
		@back_or_forward = false
		super()
		add(@main)
	end
	attr_reader :main
	def update_stack
		topath = @session.pwd
		if @back_or_forward
			@back_or_forward = false
		else
			@forward_stack.clear
		end
		if @back_stack.size == 0 || (@back_stack.size > 0 && topath != @back_stack[0])
			@back_stack.unshift(topath)
		end
		@child[5].set_sensitive(true)
	end
	def chdir_post
		@child[0].set_sensitive((@back_stack.size > 1))
		@child[1].set_sensitive((@forward_stack.size > 0))
		@child[2].set_sensitive((@session.pwd != "/"))
		@child[3].set_sensitive(true)
		@child[4].set_sensitive(true)
		@child[5].set_sensitive(false)
	end
	private
	def do_func(num)
		pwd = @session.pwd
		case num
			when 0
				if @back_stack.size > 1
					@back_or_forward = true
					@back_stack.shift
					todir = @back_stack[0]
					@forward_stack.unshift(pwd)
					@session.chdir(todir)
				end
			when 1
				if @forward_stack.size > 0
					@back_or_forward = true
					todir = @forward_stack[0]
					@forward_stack.shift
					@session.chdir(todir)
				end
			when 2
				unless pwd == "/"
					todir = File.dirname(@session.pwd)
					@session.chdir(todir)
				end
			when 3
				@session.chdir(Reg.home)
			when 4
				@back_or_forward = true
				@session.chdir(@session.pwd)
			when 5
				@session.toolbar_stop = true
			else
				@session.command.explorer_error("Current operation not implemented yet.\nReason: I'm too lazy, want to help?")
				@child[num].set_sensitive(true)
		end
	end
end
