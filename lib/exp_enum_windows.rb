#encoding: utf-8
require 'win_gui'

# When using API functions returning ANSI strings (get_window_text), force_encoding('cp1251') and encode('cp866', :undef => :replace) to display correctly
# When using API functions returning "wide" Unicode strings (get_window_text_w), force_encoding('utf-16LE') and encode('cp866', :undef => :replace) to display correctly

include WinGui

@child_handles = []
#app = launch_test_app
#keystroke(VK_ALT, 'F'.ord)

print_callback = lambda do |handle, message|
  name = get_window_text(handle) || ''
  class_name = get_class_name(handle)
  thread, process = get_window_thread_process_id(handle) 
  puts "#{message}  #{process}  #{thread}  #{handle}  #{class_name.rstrip} #{name.force_encoding('cp1251').
          encode('cp866', :undef => :replace).rstrip}"
  @child_handles << handle if message == 'CHILD'
  true
end

@windows = []
@num = 0
map_callback = lambda do |handle, message|
  name = get_window_text_w(handle)
  class_name = get_class_name(handle)
  thread, process = get_window_thread_process_id(handle) 
  @windows << { :message => message, :process => process, :thread => thread, :handle => handle,
                :klass => class_name.rstrip, :name => name}#.encode('cp866', :undef => :replace).rstrip}
  @num +=1
  true
end

puts "Top-level Windows:"
enum_windows 'TOP', &print_callback

#puts
#puts "Note Windows:"
#print_callback[app.handle, 'NOTE']
#enum_child_windows app.handle, 'CHILD', &print_callback
#@child_handles.each do |handle|
#  enum_child_windows handle, 'CHILD', &print_callback
#end

enum_windows 'TOP', &map_callback
puts
puts "Sorted Windows:"
puts @windows.sort_by{|w| [w[:process], w[:thread], w[:handle]]}.map{|w|w.values.join('  ')}
puts "Total #{@num} Windows"
