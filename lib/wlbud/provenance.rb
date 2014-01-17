module WLBud


  class ProvenanceGraph

    attr_accessor :traces
    
    def initialize
      # Store the RuleTrace objects generating provenance graph nodes
      @traces = {}
    end

    def add_new_push_elem bud_push_elem
      if @traces.key? bud_push_elem.orig_rule_id
        @traces[bud_push_elem.orig_rule_id].add_new_push_elem(bud_push_elem)
      else
        @traces[bud_push_elem.orig_rule_id] = RuleTrace.new(bud_push_elem)
      end
    end

    # PENDING a possible optimization would be to get the reference of the
    # objects in source and destination stored in collections instead of the
    # reference here that are the temporary objects used in push_elements. The
    # solution for now is to deep-copy the object to keep them in the provenance
    # graph.
    def add_new_pushed_out orig_rule_id, source, derivated
      #      src = source.to_a
      #      src = source.map{|budstruct| budstruct.to_a if budstruct.kind_of? Bud::TupleStruct }
      #      dst = derivated.to_a
      #      src = Marshal.load(Marshal.dump(src))
      #      dst = Marshal.load(Marshal.dump(dst))
      @traces[orig_rule_id].add_new_proof source, derivated
    end
  end

  # Keep the trace of all the push elements used to evaluate a rule
  class RuleTrace

    attr_reader :pushed_out_facts

    def initialize bud_push_elem
      @rule_id = bud_push_elem.orig_rule_id
      @push_elems = [bud_push_elem]
      @pushed_out_facts = []
    end

    def add_new_push_elem bud_push_elem
      @push_elems <<  bud_push_elem
    end

    def add_new_proof source, derivated
      @pushed_out_facts << ProofTree.new(source, derivated)
    end

    # Remove the object id from the name to perform test and display the push
    # element for stdout
    def self.sanitize_push_elem_name push_elt
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
    end

    def print_push_elems
      @push_elems.map{|pshelt| "#{RuleTrace.sanitize_push_elem_name pshelt}"}
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