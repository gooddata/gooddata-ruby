$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'logger'
require 'goodAPI/gdcresources'
require 'monkeyPatch'
require 'pp'
require 'irb'


module IRB
  def IRB.start2(bind, ap_path)
    IRB.setup(ap_path)
    irb = Irb.new(WorkSpace.new(bind))
    @CONF[:MAIN_CONTEXT] = irb.context
    trap("SIGINT") do
      irb.signal_handle
    end
    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

module GoodAPI
  VERSION = '0.0.1'
  
  def GoodAPI.main
    include GDC::Resources
    # SERVER_URI = 'https://secure.gooddata.com'

    headers = {
      'Accept' => "application/json",
      'Content-Type' => "application/json;charset=utf-8",
      'Connection'  => 'Keep-Alive'

    }

    # GoodAPI.accept(:json)
    # GoodAPI.base("https://secure.gooddata.com")
    Login.login('*****', '*****', {:headers => headers}) do |session|
      # a = Account.find(session.get_profile_id, {:headers => headers})
      puts "Logged in -> go for it"
      IRB::start2 binding, $STDIN
      puts "Logging out"
      # pp a.firstName
    end
  end
end