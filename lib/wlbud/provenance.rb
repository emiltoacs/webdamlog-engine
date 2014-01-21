module WLBud


  class ProvenanceGraph

    attr_accessor :traces
    
    def initialize
      # Store the RuleTrace objects generating provenance graph nodes
      @traces = {}
    end

    def consolidate
      @traces.each_value{|trace| trace.consolidate }

    end

    def add_new_push_elem bud_push_elem
      if @traces.key? bud_push_elem.orig_rule_id
        @traces[bud_push_elem.orig_rule_id].add_new_push_elem(bud_push_elem)
      else
        @traces[bud_push_elem.orig_rule_id] = RuleTrace.new(bud_push_elem)
      end
    end

    def add_new_proof orig_rule_id, source, derivated
      @traces[orig_rule_id].add_new_proof source, derivated
    end
  end



  # Keep the trace of all the push elements used to evaluate a rule
  class RuleTrace

    attr_reader :push_elems, :pushed_out_facts, :last_push_elem

    def initialize bud_push_elem
      @rule_id = bud_push_elem.orig_rule_id
      @push_elems = [bud_push_elem]      
      @pushed_out_facts = []
      @consolidated = false
      # @!attribute [r]
      #  @return [Array] relation names as symbol
      @sources = nil
    end

    def consolidate
      @last_push_elem = @push_elems.last
      @sources = build_ordered_source_collection
      @consolidated = true
    end

    def add_new_push_elem bud_push_elem
      @push_elems <<  bud_push_elem
    end

    def add_new_proof source, derivated
      @pushed_out_facts << ProofTree.new(source, derivated)
    end

    # read accessor to the @sources attribute
    def sources
      raise WLBud::WLError, "try to access @sources before consolidation" unless @consolidated
      return @sources
    end

    # Build the array of collection ordered as they are evaluated in the rule.
    # It start from the last push_element to retrieve in a backward manner the
    # source collections.
    def build_ordered_source_collection push_elem = nil
      raise WLBud::WLErrorTyping, "The last push element in a RuleTrace object is nil" if @last_push_elem.nil?
      push_elem ? pshelt = push_elem : pshelt = @last_push_elem
      srcs = []
      if pshelt.is_a? Bud::PushSHJoin
        srcs = pshelt.all_rels_below.map{|elem| build_ordered_source_collection elem}.flatten
      elsif pshelt.is_a? Bud::PushElement
        srcs << pshelt.collection_name
      else
        raise WLBud::WLErrorTyping, "Wrong type for the last push element in a RuleTrace object which is an instance of #{@last_push_elem.class}"
      end
      return srcs
    end

    def print_push_elems push_elems = nil
      @push_elems.map{|pshelt| "#{pshelt.sanitize_push_elem_name }"}
    end

    def print_last_push_elem
      if @consolidated
        "#{@last_push_elem.sanitize_push_elem_name }"
      else
        raise WLBud::WLError, "Cannot print last_push_elems before consolidation of the provenance graph"
      end
    end
  end


  
  class ProofTree
    def initialize source, derivated
      @sources = source
      @derivated = derivated
      @proof = {@sources => @derivated}
    end

    def to_a_budstruct
      src = @sources.to_a
      src = src.map{|tuple| tuple.kind_of?(Bud::TupleStruct) ? tuple.to_a : tuple}
      {src.to_a => @derivated.to_a}
    end
  end

  
end