module Erlectricity
class Receiver
  
  attr_accessor :port
  attr_accessor :parent
  attr_accessor :matchers
  
  RECEIVE_LOOP = Object.new
  NO_MATCH = Object.new
  
  def initialize(port, parent=nil, &block)
    @port = port
    @parent = parent
    @matchers = []
    block.call self if block
  end
  
  def process(arg)
    matcher = @matchers.find{|r| r.matches? arg}

    if(matcher)      
      port.restore_skipped
      matcher.run arg
    else
      NO_MATCH
    end
  end
  
  def when(args, &block)
    condition = Condition.for(args)
    @matchers << Matcher.new(self, condition, block)
  end
  
  def run
    
    loop do
      msg = port.receive
      return if msg.nil?
      
      case result = process(msg)
      when RECEIVE_LOOP then next
      when NO_MATCH
        port.skipped << msg
        next
      else
        break result
      end
    end
  end
  
  def receive(&block)
    Receiver.new(port, self, &block).run
  end

  def receive_loop
    RECEIVE_LOOP
  end
  
  def send!(*term)
    term = term.first if term.length == 1
    port.send(term)
  end
end
end


module Kernel
  def receive(input=STDIN, output=STDOUT, &block)
    Erlectricity::Receiver.new(Erlectricity::Port.new(input, output), nil, &block).run
  end
end
