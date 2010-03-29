require 'win/gui/window'

class MyClass
extend Win::Gui::Window

fg_window = foreground_window
puts window_text(fg_window)
show_window(fg_window) unless minimized?(fg_window)
#...
end

p File.dirname(__FILE__),__FILE__, __LINE__
p __LINE__, File.open(__FILE__).lines.to_a[__LINE__-1]



