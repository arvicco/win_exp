require 'win/library'

module YourLibModule
  include Win::Library

  # Customizing even further: your own method extension in attached block
  function :GetWindowText, [ :ulong, :pointer, :int ], :int do |api, handle|
    buffer = FFI::MemoryPointer.new :char, 512
    buffer.put_string(0, "\x00" * 511)
    num_chars = api.call(handle, buffer, 512)
    num_chars == 0 ? nil : buffer.get_bytes(0, num_chars)
  end

  # Customizing method behavior: zeronil forces function to return nil instead of 0, rename renames method
  function :FindWindow, [:pointer, :pointer], :ulong, zeronil: true, rename: :my_find
end

include YourLibModule

handle = my_find(nil, 'cmd')          # find any shell window
puts handle, window_text(handle)      # print shell window handle and title
