#encoding: utf-8
require 'ffi'

module FFI::Library
    def callback(*args)
      raise ArgumentError, "wrong number of arguments" if args.length < 2 || args.length > 3
      name, params, ret = if args.length == 3
        args
      else
        [ nil, args[0], args[1] ]
      end

      options = Hash.new
      options[:convention] = defined?(@ffi_convention) ? @ffi_convention : :default
      options[:enums] = @ffi_enums if defined?(@ffi_enums)
      cb = FFI::CallbackInfo.new(find_type(ret), params.map { |e| find_type(e) }, options)

      # Add to the symbol -> type map (unless there was no name)
      unless name.nil?
        @ffi_callbacks = Hash.new unless defined?(@ffi_callbacks)
        @ffi_callbacks[name] = cb
      end

      cb
    end
end


module Win

  extend FFI::Library
  ffi_lib 'user32'
  ffi_convention :stdcall
  # BOOL CALLBACK EnumWindowProc(HWND hwnd, LPARAM lParam)
  callback :enum_callback, [ :pointer, :long ], :bool
  # BOOL WINAPI EnumDesktopWindows(HDESK hDesktop, WNDENUMPROC lpfn, LPARAM lParam)
  attach_function :enum_desktop_windows, :EnumDesktopWindows, [ :pointer, :enum_callback, :long ], :bool
  # int GetWindowTextA(HWND hWnd, LPTSTR lpString, int nMaxCount)
  attach_function :get_window_text, :GetWindowTextA, [ :pointer, :pointer, :int ], :int
end

win_count = 0
title = FFI::MemoryPointer.new :char, 512
Win::EnumWindowCallback = Proc.new do |wnd, param|
  title.clear
  Win.get_window_text(wnd, title, title.size)
  puts "[%03i] Found '%s'" % [ win_count += 1, title.get_string(0) ]
  true
end

if not Win.enum_desktop_windows(nil, Win::EnumWindowCallback, 0)
  puts 'Unable to enumerate current desktop\'s top-level windows'
end


p "Success!"
exit 0

module Win
extend FFI::Library
  ffi_lib 'user32'
  ffi_convention :stdcall

# Procedure that calls api function expecting EnumWindowsProc callback. If runtime block is given
  return_enum = lambda do |api, *args, &block|
    namespace.enforce_count( args, api.prototype, -1)
    handles = []
    Win::Block = Proc.new do |wnd, param|
    end #block || proc {|handle, message| p 'Wooo' } #handles << handle; true }
    callback_key = api.prototype.find {|k, v| k.to_s =~ /callback/}
    args[api.prototype.find_index(callback_key), 0] = Win::Block # Insert callback into appropriate place of args Array
    p api.prototype, args
    api.call *args
    handles
    0
  end

# This is an application-defined callback function that receives top-level window handles as a result of a call
# to the EnumWindows or EnumDesktopWindows function.
#
# Syntax: BOOL CALLBACK EnumWindowsProc( HWND hwnd, LPARAM lParam );
  callback :enum_callback, [:pointer, :long ], :bool

##
# The EnumWindows function enumerates all top-level windows on the screen by passing the handle to
#   each window, in turn, to an application-defined callback function. EnumWindows continues until
#   the last top-level window is enumerated or the callback function returns FALSE.
  attach_function'EnumWindows', [:enum_callback, :long], :bool
  
end

Win.EnumWindows(proc{}, 13)











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
