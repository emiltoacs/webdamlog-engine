# WLChannel is a special class derived from the BudChannel class, but specially
# designed to received data packet by packet instead of receiving it as a
# continuous stream. This is done in accordance with the semantics of WebdamLog.
module WLBud
  include Bud
  
  # The WLchannel is especially designed to send packets of data that arrive
  # safely all at the same timestamp.
  class WLChannel < Bud::BudChannel

    public
    
    # Read input on the channel and build list of {WLPacketData}
    # @return [Array] array of {WLPacketData}
    def read_channel(debug=false)
      return [] if self.empty?
      list_of_packet_value = []
      self.each do |raw_string|
        # XXX ugly but easy, maybe a parsing in the spirit of json(mess with
        # hash since it expect ':' instead of '=>') or tt could be done here        
        chan_packet = raw_string
        # PENDING For some strange reason, the payloads method did not work, so I used
        # this instead.
        data = chan_packet.to_a[1]
        payload = Hash.transform_keys_to_symbols(data[2],1)
        data = [data[0], data[1], payload]
        list_of_packet_value << WLPacketData.read_from_channel(data, debug)
      end
      return list_of_packet_value
    end
      
    private
    
    # Prints the content of the received packet. Print a lot more details about
    # data if second argument print_data is true
    def print_packet (packet_value, print_data=false)
      puts "rbuffer: I received a packet of size " + packet_value.get_data.size.to_s
      + " content:" + packet_value.get_data.inspect
      if print_data then 
        packet_value.get_data.each_pair { |k,t|
          t[0].each { |v|
            puts("#{packet_value[1]}\t\t#{packet_value[0]}\t\t#{k.to_s}\t\t#{v.inspect}\t\t#{packet_value[2]}")
          }
        }
      end
    end
  end
 
  # TODO: remove it maybe deprecated
#  class BudCollection
#    def clear
#      self.init_buffers
#    end
#  end
  
  # declare a WL channel.  default schema <tt>[:address, :val] => []</tt>
  # register new collection wlchannel just like it is done in
  # state.rb file from bud
  def wlchannel(name, schema=nil, loopback=false)    
    define_collection(name)
    #this is here where I've just added WLChannel.new instead of BudChannel
    @tables[name] = WLBud::WLChannel.new(name, self, schema, loopback)
    @channels[name] = @tables[name]
  end
end
