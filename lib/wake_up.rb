require 'win/gui/input'

class MouseMover
  extend Win::Gui::Input

  def self.move_mouse_randomly
    x, y = get_cursor_pos
    x1, y1 = x+rand(3)-1, y+rand(3)-1
    mouse_event(Win::Gui::Input::MOUSEEVENTF_ABSOLUTE, x1, y1, 0, 0)
    puts "Cursor positon set to #{x1}, #{y1}"
  end
end

loop do
  MouseMover.move_mouse_randomly
  sleep 240
end