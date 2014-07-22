# This file contains the two class of objects composing the WLPacket. WLPacket
# is the basic type of data used to exchange informations between peers so it
# contains sets of facts and rules along with all the metadata used for
# communications.
module WLBud

  # This class define the structure of the packet to send on the communication
  # channel
  class WLPacket

    attr_accessor :dest, :data

    # The default constructor parameter dest : should be the URL ipv4:port of
    # the peer to reach TODO remove identifier if useless (not sure for now)
    def initialize(dest, peerName, srcTimeStamp, data={:facts=>{},:facts_to_delete=>{}, :rules=>[],:declarations=>[]})
      # #URL with [ipv4:port]
      valid_ip_address_regex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]):[0-9]+$/
      valid_hostname_regex = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9]):[0-9]+$/
      raise WLErrorTyping, "Trying to create a packet with first field dest which should be a IP but found:'#{dest.to_s}' for peerName:#{peerName} and data:#{data.inspect}" unless ( dest.is_a?(String) and !(valid_ip_address_regex.match(dest.to_s)).nil? or !(valid_hostname_regex.match(dest.to_s)).nil? )
      @dest=dest
      # #data is an array of 4 fields
      @data= WLPacketData.new(peerName, srcTimeStamp, data)
    end

    public    
    # Write this wlpacket objects as a nesting of hashes and arrays: [@dest,[@peer_name.to_s,@src_time_stamp.to_s,{:facts=>@facts,:rules=>@rules,:declarations=>@declarations}]]
    #
    def serialize_for_channel
      return [@dest,@data.serialize_for_channel]
    end

    # Build a WlPacket objects from a nesting of hashes and arrays
    #
    # ===return
    # a new WLPacket object
    #
    def self.deserialize_from_channel(array)
      raise WLErrorTyping,"expected data should have 2 items not nil" unless array.length==2 and array.each { |item| not item.nil? }
      data_array = array[1]
      raise WLErrorTyping,"expected payload must have at least a peername and srcTimeStamp" unless data_array.length==3 and array.first(2).each { |item| not item.nil? }
      payload = Hash.transform_keys_to_symbols(data_array[2],1)
      return WLPacket.new(array[0], data_array[0], data_array[1], payload)
    end

    # Build a WlPacket objects from a nesting of hashes and arrays and order
    # their content to allow easy comparison
    #
    # ===return
    # a new WLPacket object
    #
    def self.deserialize_from_channel_sorted(array)
      raise WLErrorTyping,"expected data should have 2 items not nil" unless array.length==2 and array.each { |item| not item.nil? }
      data_array = array[1]
      raise WLErrorTyping,"expected payload must have at least a peername and srcTimeStamp" unless data_array.length==3 and array.first(2).each { |item| not item.nil? }
      payload = Hash.transform_keys_to_symbols(data_array[2],1)
      packet = WLPacket.new(array[0], data_array[0], data_array[1], payload)
      packet.data.get_data_sorted!
      return packet
    end
  end

  # This class define the structure of the data in the packet to send on the
  # communication channel used in WLPacket
  class WLPacketData

    attr_reader :peer_name, :src_time_stamp
    attr_accessor :facts, :rules, :declarations, :facts_to_delete

    # the default constructor
    def initialize(peername, srcTimeStamp, payload={:facts=>{}, :facts_to_delete=>{}, :rules=>[],:declarations=>[]})
            
      # the peer which send the message: String
      raise WLErrorTyping, "peer name should be a string" unless peername.is_a?(String)
      @peer_name = peername
      # the timeStamp when the source peer send the message: Integer
      @src_time_stamp = srcTimeStamp.to_i

      raise WLErrorTyping, "Payload should be a Hash #{payload} " unless payload.is_a?(Hash)
      # TODO type check could be more elaborated here it is just hash or array
      # or nil.
      raise WLErrorTyping, "Lacking facts entry in packet #{payload} " unless payload.key?(:facts)
      raise WLErrorTyping, "Incorret data type for facts #{payload[:facts].class}" unless (payload[:facts].is_a?(Hash) or payload[:facts].nil?)
      # Should follow the given structure !{name of relation => [[tuple],
      # [tuple], [tuple]]}
      @facts = payload[:facts] || {}
      raise WLErrorTyping, "Lacking facts_to_delete entry in packet #{payload} " unless payload.key?(:facts_to_delete)
      raise WLErrorTyping, "Incorret data type for facts : #{payload[:facts_to_delete].class}" unless (payload[:facts_to_delete].is_a?(Hash) or payload[:facts_to_delete].nil?)
      # Should follow the given structure !{name of relation => [[tuple],
      # [tuple], [tuple]]}
      @facts_to_delete = payload[:facts_to_delete] || {}
      raise WLErrorTyping, "Lacking rules entry in packet #{payload} " unless payload.key?(:rules)
      raise WLErrorTyping, "Incorret data type for rules : #{payload[:rules].class}" unless (payload[:rules].is_a?(Array) or payload[:rules].nil?)
      # !@attribute [Array] of rules
      @rules = payload[:rules] || []
      raise WLErrorTyping, "Lacking declarations entry in packet #{payload} " unless payload.key?(:declarations)
      raise WLErrorTyping, "Incorret data type for declaration of new collection : #{payload[:declarations].class}" unless (payload[:declarations].is_a?(Array) or payload[:declarations].nil?)
      # !@attributes [Array] of collection declarations
      @declarations = payload[:declarations] || []
    end

    public

    class << self      
    
      # The specific builder for WLPackets from message payload when reading a
      #  WLChannel
      #  ===return
      #  a WLPacketData object
      def read_from_channel(array, debug=false)
        puts "read_from_channel, array is nil" if debug and array.nil?
        wlpacketdata = WLPacketData.new(array[0], array[1], array[2])
        if debug
          puts "BEGIN Read from channel: "
          puts wlpacketdata.pretty_print
          puts "END Read from channel"
        end
        return wlpacketdata
      end

      # Valid fact structure is Hash with relation name as key and array of
      # tuple as value.
      def valid_hash_of_facts hash
        if hash.is_a? Hash
          return true, "valid empty hash" if hash.empty?
          hash.each_pair { |k,v|
            return false, "keys in the hash should be String" unless k.is_a? String or k.is_a? Symbol
            return false, "values in the hash should be Array" unless v.is_a? Array
          }
          return true, "valid hash of facts to insert"
        else
          return false, "try to test a hash of fact that is not a hash"
        end        
      end
      
    end # end self

    def serialize_for_channel
      return [@peer_name.to_s,@src_time_stamp.to_s,get_data]
    end

    # Return the hash with facts, rules and declaration
    #
    def get_data
      return {:facts=>@facts,:rules=>@rules,:declarations=>@declarations,:facts_to_delete=>@facts_to_delete}
    end

    # Return the hash with facts, rules and declaration with their values sorted
    #
    def get_data_sorted
      return {:facts=>@facts.each_pair { |k,v| v.sort },
        :facts_to_delete=>@facts_to_delete.each_pair { |k,v| v.sort },
        :rules=>@rules.sort,
        :declarations=>@declarations.sort}
    end

    # Return the hash with facts, rules and declaration with their values sorted
    # in-place
    #
    def get_data_sorted!
      @declarations.sort!
      @rules.sort!
      @facts.each_pair { |k,v| v.sort! }
      @facts_to_delete.each_pair { |k,v| v.sort! }
      return get_data
    end

    # Return the metadata in the packet @peer_name, @src_time_stamp
    #
    def print_meta_data
      return @peer_name.to_s + ' at tick ' + @src_time_stamp.to_s
    end

    def pretty_print
      # collection added
      puts "#{self.declarations.size} collections to add:" unless self.declarations.nil?
      puts "#{self.declarations}"
      # facts added
      unless self.facts.nil?
        puts "#{self.facts.size} relations to update:" 
        self.facts.each do |rel|
          puts "#{rel.first} updated with"
          puts "#{rel[1]}"
        end
      end
      # facts to delete
      unless self.facts_to_delete.nil?
        puts "#{self.facts_to_delete.size} relations with deletions:"
        self.facts_to_delete.each do |rel|
          puts "#{rel.first} removed"
          puts "#{rel[1]}"
        end
      end
      # rules added
      puts "#{self.rules.size} rules to add:" unless self.rules.nil?
      puts "#{self.rules.inspect}"
    end

    # return the string representation of the content of the fields of this
    # object
    #
    def to_s
      return @peer_name.to_s + ' : ' + @src_time_stamp.to_s + ' : ' + get_data.inspect
    end
    # === return
    # an integer between 0 and 3 which is the number of non nil or empty data
    # field among facts, rules and declarations
    #
    def length
      res=0
      res+=1 unless @facts.nil? or @facts.empty?
      res+=1 unless @facts_to_delete.nil? or @facts_to_delete.empty?
      res+=1 unless @rules.nil? or @rules.empty?
      res+=1 unless @declarations.nil? or @declarations.empty?
      return res
    end
  end
end