# Bud methods overridden in Webdamlog
module Bud
  # Add the rule from which the push element has been created
  class PushElement

    attr_reader :orig_rule_id, :collection_name

    # add provenance tracking
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
      if @bud_instance.kind_of? WLBud::WL and @bud_instance.provenance
        @orig_rule_id = bud_instance.current_eval_rule_id
        raise WLBud::WLError, "a PushElement has not received its rule_id of provenance" unless @orig_rule_id
      end
    end

    # Create new proof tree when a tuple is pushed into a collection
    def push_out(item, do_block=true)
      if @bud_instance.kind_of? WLBud::WL and @bud_instance.provenance
        source = item
      end

      if do_block && @blk
        item = item.to_a if @blk.arity > 1
        item = @blk.call item
        return if item.nil?
      end

      @outputs.each do |ou|
        if ou.class <= Bud::PushElement
          ou.insert(item, self)
        elsif ou.class <= Bud::BudCollection
          if @bud_instance.kind_of? WLBud::WL and @bud_instance.provenance
            # hacky, remove group predicate from provenance tracking. It is not
            # in Webdamlog but this it is used in provenance optimizations. 
            unless self.is_a? Bud::PushGroup
              inferred = item
              @bud_instance.provenance_graph.add_new_proof @orig_rule_id, source, inferred
            end
          end
          ou.do_insert(item, ou.new_delta)
        elsif ou.class <= Bud::LatticeWrapper
          ou.insert(item, self)
        else
          raise Bud::Error, "unexpected output target: #{ou.class}"
        end
      end

      # for the following, o is a BudCollection
      @deletes.each{|o| o.pending_delete([item])}
      @delete_keys.each{|o| o.pending_delete_keys([item])}

      # o is a LatticeWrapper or a BudCollection
      @pendings.each do |o|
        if o.class <= Bud::LatticeWrapper
          o <+ item
        else
          # TODO insert here provenance tracking
          if @bud_instance.kind_of? WLBud::WL and @bud_instance.provenance
            # hacky, remove group predicate from provenance tracking. It is not
            # in Webdamlog but this it is used in provenance optimizations.
            unless self.is_a? Bud::PushGroup
              inferred = item
              @bud_instance.provenance_graph.add_new_proof @orig_rule_id, source, inferred
            end
          end
          o.pending_merge([item])
        end
      end
    end


    # Remove the object id from the name to perform test and display the push
    # element for stdout
    def self.sanitize_push_elem_name push_elt
      if push_elt.is_a? Bud::PushElement
        res = push_elt.tabname.to_s
        # remove Scanner or PushSHJoin object number
        if res.gsub!(/:[0-9]*/,'')
          return res
          # remove Project object number
        elsif res.gsub!(/project[0-9]*/,"project#{push_elt.schema}")
          return res
          # remove nothing
        else
          return res
        end
      else
        raise WLBud::WLError, "Wrong type of parameter push_elems is a #{push_elt.class}"
      end
    end
    # Instance method version of previous class method
    def sanitize_push_elem_name
      PushElement.sanitize_push_elem_name self
    end

  end
end