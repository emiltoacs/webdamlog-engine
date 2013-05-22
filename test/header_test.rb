# ####License####
#  File name header_test.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Jun 27, 2012
# 
#   Encoding - UTF-8
# ####License####
# Prefer webdamlog from local source tree to any version in RubyGems
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "."
# full relative path to specify that you want the current version in the project
# and not the gem
require 'wlbud'

#stdlib
require 'test/unit'
#lib
#if RUBY_VERSION < "1.9"
#  require 'ruby2ruby'
#  gem 'ParseTree'
#  require 'parse_tree_extensions'
#else
#  gem 'ruby_parser'
#  gem 'file-tail'
#  gem 'sourcify'
#  require 'sourcify'
#end
require 'pp'
require 'yaml'
#custom
require 'wlbud/wlextendsbud'

#begin
#  require 'debugger'
#  puts 'debugger loaded'
#rescue LoadError => e
#  begin
#    require 'ruby-debug'
#    puts 'ruby-debug loaded'
#  rescue LoadError => e
#    puts "debugger disabled"
#  end
#end

# Mixin with some code common to most of my tc_wl_* tests
#
module MixinTcWlTest

  #  # Callback method triggered when this module is invoked
  #  #
  #  def self.included(klass)
  #    # Override the initializer to add instance variable
  #    #
  #    klass.class_eval{
  #      attr_accessor :first_test
  #      def initialize(*a,&b)
  #        super(*a,&b)
  #        @@first_test=true
  #      end
  #    }
  #  end

  # self.included is a callback method triggered when this module is included.
  #
  # self reference MixinTcWlTest and klass is the module which include this one.
  #
  # + verbose allow to use the $test_verbose options when running tests
  # + BUD_DEBUG allow to use the $BUD_DEBUG options when running tests
  #
  def self.included othermod
    if ARGV.include?("verbose")
      $test_verbose = true
    end
    if ARGV.include?("BUD_DEBUG")
      $BUD_DEBUG = true
    end
  end

  # Create sub-sub-class of WLBud::WL to be instantiate to launch wl_peers
  #
  # The sub-class of WLBud::WL redefine the initialize method with two
  # additional parameters:
  # * program that should be the string representing the program in a webdamlog syntax
  # * filetowrite the file in which to write the program given program
  #
  # ===parameter
  # * +nb_of_test_pg+ number of peer to create, thus it create as many subclass
  #   as needed.
  # * +class_peer_name+ prefix for the name of newly created class
  # * +test_filename_var+ prefix for the name of the variable which will receive
  #   the name of the file created with the program
  #
  def create_wlpeers_classes(nb_of_test_pg, class_peer_name)
    (0..nb_of_test_pg-1).each do |i|
      klass = Class.new(WLBud::WL)
      self.class.class_eval "Inter#{class_peer_name}#{i} = klass"
      klass.send(:define_method, :initialize) do |peername,program,filetowrite,options|
        File.open(filetowrite,"w"){ |file| file.write program}
        super(peername, filetowrite, options)
      end
      # Create new anonymous subklass
      subklass = Class.new(klass)
      # Give a name to that subklass
      self.class.class_eval "#{class_peer_name}#{i} = subklass"
      # Store it in a class variable of the caller (such that the test method
      # that call this can access newly created class easily)
      # rubyconvert in 1.9 class_variable_set is no longer private
      self.class.send(:class_variable_set, "@@#{class_peer_name}#{i}", subklass )
    end
  end

  # Creates a valid filename with the name of that class
  #
  def create_name
    WLTools.friendly_filename("#{self.class.name}")
  end

  # Block until a message has been received on the inbound of the given wlpeer
  #
  # @param [Bud] wlpeer the instance of the Bud peer to wait for receiving message
  # @return [Boolean] true is something have been received
  #
  def wait_inbound(wlpeer)
    cpt = 0
    while wlpeer.inbound.empty?
      sleep 0.4
      cpt += 1
      if cpt>5
        return false
      end
    end
    return true
  end
end



