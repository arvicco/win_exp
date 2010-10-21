module Events
  class SubscriberTypeError < TypeError
  end

  # TODO: Mutexes to synchronize @subscribers update ?
  # http://github.com/snuxoll/ruby-event/blob/master/lib/ruby-event/event.rb
  class Event

    attr_reader :name, :subscribers

    def initialize(name)
      @name = name
      @subscribers = {}
    end

    # You can subscribe anything callable to the event, such as lambda/proc,
    # method(:method_name), attached block or a custom Handler. The only requirements,
    # it should respond to a #call and accept arguments given to Event#fire.
    #
    # Please keep in mind, if you attach a block to #subscribe without a name, you won't
    # be able to unsubscribe it later. However, if you give #subscribe a name and attached block,
    # you'll be able to unsubscribe using this name
    #
    # :call-seq:
    #   event.subscribe( proc{|*args| "Subscriber 1"}, method(:method_name)) {|*args| "Unnamed subscriber block" }
    #   event.subscribe("subscription_name") {|*args| "Named subscriber block" }
    #   event += method(:method_name)  # C# compatible syntax, just without useless "delegates"
    #
    def subscribe(*subscribers, &block)
      if block and subscribers.size = 1 and not subscribers.first.respond_to? :call
        # Arguments must be subscription block and its given name
        @subscribers[subscriber] = block
      else
        # Arguments must be a list of subscribers
        (subscribers + [block]).flatten.compact.each do |subscriber|
          if subscriber.respond_to? :call
            @subscribers[subscriber] = subscriber
          else
            raise Events::SubscriberTypeError.new "Handler #{subscriber.inspect} does not respond to #call"
          end
        end
      end
      self # This allows syntax like: my_event += subscriber
    end

    alias_method :+, :subscribe

    def unsubscribe(*subscribers)
      (subscribers).flatten.compact.each do |subscriber|
        @subscribers.delete(subscriber) if @subscribers[subscriber]
      end
      self # This allows syntax like: my_event -= subscriber
    end

    alias_method :-, :unsubscribe
    alias_method :remove, :unsubscribe

    def fire(*args)
      @subscribers.each do |key, subscriber|
        subscriber.call *args
      end
    end

    alias_method :call, :fire

    def clear
      @subscribers.clear
    end

    def == (other)
      case other
        when Event
          super
        when nil
          @subscribers.empty?
        else
          false
      end
    end
  end

  def events
    @events ||= {}
  end

  # Once included into a class/module, gives this module .event macros for declaring events
  def self.included(host)

    host.instance_exec do
      def event (name)
        define_method name do |*args, &block|
          events[name] ||= Event.new(name)
          if args != []
            events[name].fire(*args)
          else
            if block
              events[name].subscribe &block
            else
              events[name]
            end
          end
        end

        define_method "#{name}=" do |event|
          if event.kind_of? Event
            events[name] = event
          else
            raise Events::SubscriberTypeError.new "Attempted assignment #{event.inspect} is not an Event"
          end
        end
      end
    end

  end
end

# This is a reproduction of "The Second Change Event Example" from:
# http://www.akadia.com/services/dotnet_delegates_and_events.html
#
module SecondChangeEvent

#  /* ======================= Event Publisher =============================== */
#  // Our subject -- it is this class that other classes
#  // will observe. This class publishes one event:
#  // SecondChange. The observers subscribe to that event.
  class Clock
    include Events

    # // The delegate named SecondChangeHandler, which will encapsulate
    # // any method that takes a clock object and a TimeInfoEventArgs
    # // object as the parameter and returns no value. It's the
    # // delegate the subscribers must implement.
    # ???? Seems like the delegates add nothing but "type/signature safety", let's skip them
    #delegate SecondChangeHandler(clock, timeInformation) #!!!!! Delegate declaration

    #// The event we publish
#    event SecondChangeHandler SecondChange #!!!!! Event declaration
    event :SecondChange #!!!!! Event declaration


#    #// The method which fires the Event
#    def OnSecondChange(clock, dt)
#      #// Check if there are any Subscribers
#      if (SecondChange() != nil)
#        #// Call the Event
#        SecondChange(clock, dt) #!!!!!!!!!!!!!!!!! What is it?
#      end
#    end

    #// Set the clock running, it will raise an event for each new second
    def Run()
      loop do
        sleep 1
        #// Get the current time
        dt = Time.now

        #// If the second has changed
        #// notify the subscribers
        if (dt.sec != @sec)
          #// If anyone has subscribed, notify them
          SecondChange(self, dt)
        end

        #// update the state
        @sec = dt.sec
      end
    end

    p self.instance_methods- Object.instance_methods
  end

#  /* ======================= Event Subscribers =============================== */

#    // An observer. DisplayClock subscribes to the
#    // clock's events. The job of DisplayClock is
#    // to display the current time
  class DisplayClock
    # // Given a clock, subscribe to its SecondChangeHandler event
    def Subscribe(theClock)
      theClock.SecondChange += method :TimeHasChanged
    end

    #// The method that implements the delegated functionality
    def TimeHasChanged(theClock, ti)
      puts "Current Time: #{ti.hour}:#{ti.min}:#{ti.sec}"
    end
  end

  #// A second subscriber whose job is to write to a file
  class LogClock

    def Subscribe(theClock)
      theClock.SecondChange +=  method :WriteLogEntry # subscribing with a Method name
    end

    #// This method should write to a file
    #// we write to the console to see the effect
    #// this object keeps no state
    def WriteLogEntry(theClock, ti)
      puts "Logging to file: #{ti.hour}:#{ti.min}:#{ti.sec}"
      # Code that logs to file goes here...
    end
  end

#   /* ======================= Test Application =============================== */
#
#   // Test Application which implements the
#   // Clock Notifier - Subscriber Sample
#   public class Test
#      public static void Main()

  # // Create a new clock
  theClock = Clock.new

  #// Create the display and tell it to
  #// subscribe to the clock just created
  dc = DisplayClock.new
  dc.Subscribe(theClock)

  #// Create a Log object and tell it
  #// to subscribe to the clock
  lc = LogClock.new
  lc.Subscribe(theClock)

  #// Get the clock started
  theClock.Run
end