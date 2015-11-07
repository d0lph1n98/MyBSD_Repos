require 'mkmf'

#rubygtk_dir = "/mnt/UFS/ruby-gnome-0.26/gtk"
#rubygtk_dir = ARGV[0] if ARGV[0]
#unless FileTest.exist?(rubygtk_dir)
#  raise "Directory #{rubygtk_dir} not found.  Please specify Ruby/Gtk source dir."
#end
gtklib_dir = []
`gtk-config --libs`.split(' ').each do |e|
  if e=~ /^-L/ then
    gtklib_dir.push(e)
  end
end

#$CFLAGS = "-I#{rubygtk_dir}/src " + `gtk-config --cflags`.chomp
$CFLAGS = "-I. " + `gtk-config --cflags`.chomp
$LDFLAGS = `gtk-config --libs`.chomp

create_makefile('gtk_fix')
