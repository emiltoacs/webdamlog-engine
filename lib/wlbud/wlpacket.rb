#  File name wlpacket.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Jules Testard <jules[dot]testard[@]mail[dot]mcgill[dot]ca>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - 30 juin 2011
#
#   Encoding - UTF-8
#
#   This file contains the two class of objects composing the WLPacket.
#   WLPacket is the basic type of data used to exchange informations between peers so it contains sets of facts and rules along with all the metadata used for communications.
#
#
module WLBud

  # This class define the structure of the packet to send on the communication
  # channel
  class WLPacket

    attr_accessor :dest, :data

    # The default constructor parameter dest : should be the URL ipv4:port of
    # the peer to reach TODO remove identifier if useless (not sure for now)
    def initialize(dest, peerName, srcTimeStamp, data={'facts'=>{},'rules'=>[],'declarations'=>[]})
      # #URL with [ipv4:port]
      valid_ip_address_regex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]):[0-9]+$/
      valid_hostname_regex = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9]):[0-9]+$/
      raise WLErrorTyping, "Trying to create a packet with first field dest which should be a IP but found:'#{dest.to_s}' for peerName:#{peerName} and data:#{data.inspect}" unless ( dest.is_a?(String) and !(valid_ip_address_regex.match(dest.to_s)).nil? or !(valid_hostname_regex.match(dest.to_s)).nil? )
      @dest=dest
      # #data is an array of 4 fields
      @data= WLPacketData.new(peerName, srcTimeStamp, data)
    end

    public    
    # Write this wlpacket objects as a nesting of hashes and arrays
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
      return WLPacket.new(array[0], data_array[0], data_array[1], data_array[2])
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
      packet = WLPacket.new(array[0], data_array[0], data_array[1], data_array[2])
      packet.data.get_data_sorted!
      return packet
    end
  end

  # This class define the structure of the data in the packet to send on the
  # communication channel used in WLPacket
  class WLPacketData

    attr_reader :peer_name, :src_time_stamp
    attr_accessor :facts, :rules, :declarations

    # the default constructor
    def initialize(peername, srcTimeStamp, payload={'facts'=>{},'rules'=>[],'declarations'=>[]})
            
      # the peer which send the message: String
      raise WLErrorTyping, "peer name should be a string" unless peername.is_a?(String)
      @peer_name = peername
      # #the timeStamp when the source peer send the message: Integer
      @src_time_stamp = srcTimeStamp.to_i

      # TODO type check could be more elaborated here it is just hash or array
      # or nil
      raise WLErrorTyping, "Lacking facts entry in packet " unless payload.key?('facts')
      raise WLErrorTyping, "Incorret data type for facts : #{payload['facts'].class}" unless (payload['facts'].is_a?(Hash) or payload['facts'].nil?)
      # Should follow the given structure !{name of relation => [[tuple],
      # [tuple], [tuple]]} TODO add flag for add or remove
      @facts = payload['facts']
      raise WLErrorTyping, "Lacking rules entry in packet " unless payload.key?('rules')
      raise WLErrorTyping, "Incorret data type for rules : #{payload['rules'].class}" unless (payload['rules'].is_a?(Array) or payload['rules'].nil?)
      # !@attribute [Array] of rules
      @rules = payload['rules']
      raise WLErrorTyping, "Lacking declarations entry in packet " unless payload.key?('declarations')
      raise WLErrorTyping, "Incorret data type for declaration of new collection : #{payload['declarations'].class}" unless (payload['declarations'].is_a?(Array) or payload['declarations'].nil?)      
      # !@attributes [Array] of collection declarations
      @declarations = payload['declarations']
    end

    public

    class << self      
    
      # The specific builder for WLPackets from message payload when reading a
      # WLChannel
      # ===return
      # a WLPacketData object
      #
      def read_from_channel(array, debug=false)
        # #raise WLErrorTyping.new("I received a packet with wrong structure
        # maybe payload != 1 length:" + array.length.to_s + " content:" +
        # array.inspect.to_s) unless (array.length==1) #puts "Warning! length of
        # payloads different from 1!" unless debug and (array.length==1)
        packet = array[0]
        puts "packet is nil" if debug and packet.nil?
        if debug
          puts "inspect packet received"
          puts packet.inspect
        end
        return WLPacketData.new(packet[0], packet[1], packet[2])
      end

      # Valid fact structure is Hash with relation name as key and array of
      # tuple as value.
      def valid_hash_of_facts hash
        if hash.is_a? Hash
          return true, "valid empty hash" if hash.empty?
          hash.each_pair { |k,v|
            return false, "keys in the hash should be String" unless k.is_a? String
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
      return {'facts'=>@facts,'rules'=>@rules,'declarations'=>@declarations}
    end

    # Return the hash with facts, rules and declaration with their values sorted
    #
    def get_data_sorted
      return {'facts'=>@facts.each_pair { |k,v| v.sort },
        'rules'=>@rules.sort,
        'declarations'=>@declarations.sort}
    end

    # Return the hash with facts, rules and declaration with their values sorted
    # in-place
    #
    def get_data_sorted!
      @declarations.sort!
      @rules.sort!
      @facts.each_pair { |k,v| v.sort! }
      return get_data
    end

    # Return the metadata in the packet @peer_name, @src_time_stamp
    #
    def print_meta_data
      return @peer_name.to_s + ' : ' + @src_time_stamp.to_s
    end

    # #return the string representation of the content of the fields of this
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
      res+=1 unless @rules.nil? or @rules.empty?
      res+=1 unless @declarations.nil? or @declarations.empty?
      return res
    end
  end
end