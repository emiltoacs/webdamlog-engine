# Bud methods overridden in Webdamlog
module Bud

  # Add the rule from which the push element has been created
  class PushElement

    def initialize(name_in, bud_instance, collection_name=nil, given_schema=nil, defer_schema=false, &blk)
      super(name_in, bud_instance, given_schema, defer_schema)
      @blk = blk
      @outputs = Set.new
      @pendings = Set.new
      @deletes = Set.new
      @delete_keys = Set.new
      @wired_by = []
      @elem_name = name_in
      @found_delta = false
      @collection_name = collection_name
      @invalidated = true
      @rescan = true
      # ### WLBud:Begin adding to Bud
      @orig_rule_id = bud_instance.current_eval_rule_id
      raise WLBud::WLError, "a PushElement has not received its rule_id of provenance" unless @orig_rule_id
    end

  end
  
end