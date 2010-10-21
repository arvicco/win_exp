require File.join(File.dirname(__FILE__), "spec_helper" )

describe 'Thread test' do
  it 'makes Threads possible' do
    threads = []
    5.times do |n|
      sleep rand
      threads << Thread.new(n) do |num|
        sleep rand
        print "In thread #{num}\n"
      end
      puts "Out of thread #{n}"
    end
    threads.each {|t| t.join}
  end
end