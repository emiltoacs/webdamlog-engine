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
    options[:port] = port
    # FIXME Hacky way to get the rules and collections from bootstrap program
    klass.module_eval { attr_accessor :bootstrap_program}
    klass.module_eval { attr_accessor :bootstrap_collections}
    klass.module_eval { attr_accessor :bootstrap_rules}
    obj = klass.new(username, pg_file, options)
    #Loading twice the file from io. could find another way but need clear interface from wl_bud
    obj.bootstrap_program = pg_file ? open(pg_file).readlines.join("").split(";").map {|stmt| "#{stmt};"} : []
    obj.bootstrap_collections = obj.bootstrap_program ? obj.bootstrap_program.select {|stmt| stmt.lstrip()[0..9]=='collection' } : []
    obj.bootstrap_rules = obj.bootstrap_program ? obj.bootstrap_program.select {|stmt| stmt.lstrip()[0..3]=='rule' } : []
    obj.extend WLRunner
    return obj
  end

  # Stop and delete the webdamlog engine
  def delete
    self.stop if self.running_async
    WLEnginePool.delete self.class
  end

  # Start the webdamlog engine as an event machine task
  def run_engine
    run_bg
  end

  # TODO should be called in callback when adding contact
  #
  # @return [String,String] peername, address as added in webdamlog
  def update_add_peer peername, ip, port
    return self.wl_program.add_peer peername, ip, port
  end

  # add collection with declaration as a string or WLRule object
  def update_add_collection wl_relation
    name, schema = ""
    sync_do do
      name, schema = self.add_collection(wl_relation)
    end
    return name, schema
  end

  # Add new facts with declarations Hash, WLFacts or String representing a
  # webdamlog fact in a program
  #
  # @return [Hash, Hash] valid and error, valid is a list of facts that have
  # been successfully inserted, err is a list of facts that has not been insert
  # due to error in the format !{["relation_name", [tuple]] => "error message"}
  def update_add_fact facts
    fct, err = {}
    sync_do do
      begin
        fct, err = self.add_facts facts
      rescue WLError => e
        err = e
      end
    end
    return fct, err
  end

  # XXX customize return value if needed
  # @raise [WLError] if something goes wrong
  def update_add_rule rule
    rule_id, rule_string = nil
    sync_do do
      rule_id, rule_string = self.add_rule rule
    end
    return rule_id, rule_string
  end

  # Helpers to check syntax of webdamlog program
  #
  # @return [Array] array of WLBud::WLVocabulary or WLErrorGrammarParsing
  def parse pg
    return "" if pg.nil?
    file = StringIO.new(pg)
    line = file.readlines
    ret = []
    begin
      ret = self.wl_program.parse_lines line, false
    rescue WLError => err
      ret << err
    end
    return ret
  end

  # @return [Array] with in this order: array of peers, array of collection and
  # hash of rules
  def snapshot_full_state
    [ snapshot_peers, snapshot_collections, snapshot_rules ]
  end

  # @return [Array] list of peers declared in wdl
  def snapshot_peers
    peers = []
    sync_do do
      peers = self.wl_program.wlpeers
    end
    return peers.map { |name,address| "#{name} #{address}" }
  end

  # @return [Array] list of String of collection declared in wdl
  def snapshot_collections
    coll = []
    sync_do do
      coll = self.wl_program.wlcollections
    end
    return coll.map { |name,wlrule| wlrule.show_wdl_format }
  end

  # @return [Array] list of facts in that relation relname is supposed to be the name in webdamlog
  def snapshot_facts relname
    coll = []
    sync_do do
      coll self.tables[relname].map{ |t| Hash[t.each_pair.to_a] }
    end
    return coll
  end

  # @return [Array] list of relation name as declared in webdamlog
  def snapshot_relname
    list_rel = []
    sync_do do
      self.app_tables.map { |item| item.tabname }.sort
    end
    return list_rel
  end

  # return [Hash] !{id=>rule} id is the wdl internal id for rules and rule is the string parsed and exectued by the wdl engine
  def snapshot_rules
    res = {}
    rule_map = {}
    sync_do do
      rule_map = self.wl_program.rule_mapping
    end
    rule_map.each { |id,rules| res[id]=rules.first.show_wdl_format if rules.first.is_a? WLBud::WLRule }
    return res
  end

  # @return [Hash] the hash of all the pending delegations and clear it
    def flush_delegations
      flush = {}
      sync_do {
        flush = @pending_delegations.dup
        @pending_delegations.clear
      }
      flush
    end

  private

  class WLEnginePool
    class << self

      attr_reader :engines

      # Create the new class to instantiate to be a webdamlog engine
      def create username, port
        @engines ||= {}
        ano_klass = Class.new WLBud::WL
        klass_name = create_new_class_name(username, port)
        klass = Object.const_set(klass_name, ano_klass)
        @engines[klass.object_id] = [klass_name, klass]
        return klass
      end
      
      # Remove WLRunner from the pool
      def delete obj
        raise(WLBud::WLErrorRunner, "try to delete from the pool the class of an engine which is not a Class object type") unless obj.is_a? Class
        klass_name, klass = @engines[obj.object_id]
        @engines.delete(obj.object_id)
        Object.send(:remove_const, klass_name) unless klass_name.nil? or !Object.const_defined?(klass_name)
      end

      def create_new_class_name username, port
        return "ClassWLEngineOf#{username}On#{port}".split('_').collect!{ |w| w.capitalize }.join.to_sym
      end
    end
  end # end class WLEnginePool

end

