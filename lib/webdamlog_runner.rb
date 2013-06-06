# #!/usr/bin/env ruby

# Interface to use the webdamlog engine from an external application such as a
# rail application

require_relative 'wlbud'
require_relative 'wlbud/wlerror'

module WLRunner
  include WLBud

  public

  # Create a new webdamlog engine object ready to be run
  def self.create (username, pg_file, port, options={})
    klass = WLEnginePool.create username, port
    obj = klass.new(username, pg_file, {:port => port, :rule_dir => options[:rule_dir]})
    obj.extend WLRunner
    return obj
  end

  def delete
    self.stop if self.running_async
    WLEnginePool.delete self
  end

  def run_engine
    run_bg
  end

  def add_peer peername, ip, port
    self.wl_program.add_peer peername, ip, port
  end

  # add collection with declaration as a string or WLRule object
  def add_collection wl_relation
    self.add_collection(wl_relation)
  end

  # add new facts with declarations Hash, WLFacts or String representing a
  # webdamlog facts in a program
  def add_fact facts
    self.add_facts facts
  end

  def add_rule
    
  end

  private

  class WLEnginePool
    class << self
      def create username, port
        @engines ||= {}
        ano_klass = Class.new WLBud::WL        
        klass = Object.const_set(create_new_class_name(username, port), ano_klass)
        @engines[klass.object_id] = klass
        return klass
      end
      
      # Remove WLRunner from the pool
      def delete obj
        raise(WLBud::WLErrorRunner, "try to delete from the pool of engine an object that is not a webdamlog engine") unless obj.is_a? WLRunner
        obj.stop if obj.running_async
        const = @engines[obj.object_id]
        @engines.delete(obj.object_id)
        Object.remove_const const.to_sym unless const.nil? or !Object.const_defined?(const.to_sym)
      end

      def create_new_class_name username, port
        return "ClassWLEngineOf#{username}On#{port}".split('_').collect!{ |w| w.capitalize }.join
      end
    end
  end # end class WLEnginePool

end

