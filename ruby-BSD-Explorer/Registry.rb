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

class ExplorerRegistry
	def initialize
		@registry = {
			'left_info_main_title_font' => '-*-helvetica-bold-r-normal-*-*-180-*-*-*-*-*',
			'left_info_preview_title_font' => '-*-helvetica-bold-r-normal-*-*-120-*-*-*-*-*',
			'toolbar_show_icon' => true,
			'toolbar_show_label' => true,
			'image_preview' => true,
			'default_xterm' => "xterm",
			'default_apps' => [],
			'default_width' => 760,
			'default_height' => 450,
			'icon_width' => 34,
			'icon_height' => 34,
			'lazy_draw' => true,
			'sync_update' => true,
			'use_fs_cache' => false,
			'max_dir_cache' => 10,
			'left_info_enable' => true,
			'run_dialog_x_pos' => "default",
			'run_dialog_y_pos' => "default",
			'safe_file_deletion' => false,
			'apps_directory' => EXPLORER_BASE,
			'bookmarks' => [],
		}
	end
	def [](key)
		key = key.to_s.downcase
		@registry.has_key?(key) ? @registry[key] : nil
	end
	def []=(key, val)
		@registry[key] = val
	end
end
