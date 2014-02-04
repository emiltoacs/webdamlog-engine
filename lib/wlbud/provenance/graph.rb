module WLBud


  class ProvenanceGraph

    attr_accessor :traces, :rel_index
    
    def initialize
      # Store the RuleTrace objects generating provenance graph nodes
      @traces = {}
      # Store for each relation and for each fact the proof tree depending on
      # them
      #  @return [Hash] :relname=>[tuple]=>ProofTree
      @rel_index = Hash.new{ |h,k| h[k]=Hash.new{ |h2,k2| h2[k2]=Array.new } }
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

    # Here source is possibly one Bud::TupleStruct or several tuple represented
    # as an array of Bud::TupleStruct. However inferred is one single tuple.
    # @return [ProofTree] the proof tree created or nil if it was a duplicate
    def add_new_proof orig_rule_id, source, inferred
      # Create new proof tree
      pt = @traces[orig_rule_id].add_new_proof source, inferred

      unless pt.nil?
        # Update relation index used to find proof trees
        src_rels = @traces[orig_rule_id].sources
        src_tuples = pt.sources
        raise WLBud::WLError, "Proof for fact #{pt.inferred} with #{src_tuples.size} facts, does not respect arity of rule #{orig_rule_id} supposed to be #{src_rels.size}" unless src_rels.size == src_tuples.size
        src_rels.zip(src_tuples).each do |rel,tuple|
          @rel_index[rel][tuple] << pt
        end
        return pt
      else
        return nil
      end      
    end

    def print_rel_index
      @rel_index.map do |rel,hash| 
        [rel, hash.map{|tup,pts| [tup.to_h, pts.map{|pt| {pt.rule_trace.inferred => pt.inferred}}]}]
      end
    end
  end


  
  class RuleTrace

    attr_reader :push_elems, :pushed_out_facts, :output_push_elem
    attr_reader :sources, :inferred

    def initialize bud_push_elem
      # Bud id of this rule
      @rule_id = bud_push_elem.orig_rule_id
      # The array of all the push elements used to evaluate a rule
      @push_elems = [bud_push_elem]
      # The hash of all the proof tree depending on this rule
      @pushed_out_facts = {}
      # true when the rule is completely wired in and out
      @consolidated = false
      # @return [Array] relation names as symbol
      @sources = nil
      # @return [Symbol] relation name
      @inferred = nil
    end

    def consolidate
      # retrieve the last push element that insert facts in a collection
      @push_elems.reverse_each do |pshelt|
        # Scanners may have multiple outputs
        if pshelt.is_a? Bud::ScannerElement
          next
        end
        # All other PushElements (non-scanners ones) have one output or pending
        # if a deferred op is used
        unless pshelt.outputs.size == 1 or pshelt.pendings.size == 1
          raise WLBud::WLError, "Element of class #{pshelt.class} raised an error since we assumed that non-scanners elements must have only one output or pending instead there are #{pshelt.outputs.size} output and #{pshelt.pendings.size} output"
        end
        if pshelt.outputs.first.is_a? Bud::PushElement
          next
        elsif pshelt.pendings.first.is_a? Bud::BudCollection
          @output_push_elem = pshelt
          @target = pshelt.pendings
        elsif pshelt.outputs.first.is_a? Bud::BudCollection
          @output_push_elem = pshelt
          @target = pshelt.outputs
        else
          raise WLBud::WLErrorTyping, "found objects #{pshelt.outputs.first.class} and #{pshelt.pendings.first.class} in @push_elems outputs and pendings attribute of RuleTrace"
        end
      end
      @sources = build_ordered_source_collection
      @consolidated = true
      raise WLBud::WLErrorTyping, "last push element is wired to multiple output but it is expected to have only one" unless @target.size == 1
      raise WLBud::WLErrorTyping, "output of the last push element is supposed to be a Bud::BudCollection not a #{@target.first}" unless @target.first.is_a? Bud::BudCollection
      @inferred = @target.first.tabname
    end

    def add_new_push_elem bud_push_elem
      @push_elems <<  bud_push_elem
    end
    
    # @return [ProofTree] the proof tree created or nil if it was a duplicate
    def add_new_proof source, inferred
      raise WLBud::WLError, "try to access add new proof before consolidation" unless @consolidated
      pt = ProofTree.new(source, inferred, self)
      key = pt.to_a_budstruct.to_a
      # ignore duplicates
      unless @pushed_out_facts.include?(key)
        @pushed_out_facts[key] = pt
        return pt
      else
        return nil
      end
    end

    # read accessor to the @sources attribute
    def sources
      raise WLBud::WLError, "try to access @sources before consolidation" unless @consolidated
      return @sources
    end

    # Build the array of collection ordered as they are evaluated in the rule.
    # To retrieve the source collection, we start from the last push_element and
    # run backward to the source push elements until the the source collections
    # are reached. Note that depending on the type of push elements the way to
    # retrieve sources differs. FIXME take care that tuple could be simple Array
    # when group predicate is used. For now we skip provenance for group_by, see
    # our push_out in budoverride/elements.rb
    def build_ordered_source_collection push_elem = nil
      raise WLBud::WLErrorTyping, "The last push element in a RuleTrace object is nil" if @output_push_elem.nil?
      push_elem ? pshelt = push_elem : pshelt = @output_push_elem
      srcs = []
      if pshelt.is_a? Bud::PushSHJoin
        srcs = pshelt.all_rels_below.map{|elem| build_ordered_source_collection elem}.flatten
      elsif pshelt.is_a? Bud::PushElement
        srcs << pshelt.collection_name
      else
        raise WLBud::WLErrorTyping, "Wrong type for the last push element in a RuleTrace object which is an instance of #{@output_push_elem.class}"
      end
      return srcs
    end

    def print_push_elems push_elems = nil
      @push_elems.map{|pshelt| "#{pshelt.sanitize_push_elem_name }"}
    end

    def print_last_push_elem
      if @consolidated
        "#{@output_push_elem.sanitize_push_elem_name }"
      else
        raise WLBud::WLError, "Cannot print last_push_elems before consolidation of the provenance graph"
      end
    end
  end


  
  class ProofTree

    attr_reader :sources, :inferred, :rule_trace

    # Here source is possibly one Bud::TupleStruct or several tuple represented
    # as an array of Bud::TupleStruct
    def initialize source, inferred, rule_trace
      if source.kind_of?(Bud::TupleStruct)
        src = [source]
      elsif source.kind_of? Array
        src = source.map do |tuple|
          if tuple.kind_of?(Bud::TupleStruct)
            tuple
          else
            raise WLBud::WLErrorTyping, "facts in the leaves of the proof tree must be an array of TupleStruct not an array of #{source.class}"
          end
        end
      else
        raise WLBud::WLErrorTyping, "source of the proof tree should be an array or a single TupleStruct not a #{source.class}"
      end
      # An array of tuple, a tuple is always converted into an array of
      # Bud::TupleStruct
      @sources = src
      # One single tuple inferred from source
      @inferred = inferred
      # The RuleTrace object on which this proof tree depends
      @rule_trace = rule_trace
      
      @proof = {@sources => @inferred}
    end

    # Used to create unique key for this proof
    def to_a_budstruct
      src = @sources.map{|tuple| tuple.kind_of?(Bud::TupleStruct) ? tuple.to_a : tuple}
      {src.to_a => @inferred.to_a}
    end
  end
end