module WLBud


  class ProvenanceGraph

    attr_accessor :traces
    
    def initialize
      # Store the Trace objects generating provenance graph nodes
      @traces = {}
    end

    def add_new_push_elem bud_push_elem
      if @traces.key? bud_push_elem.orig_rule_id
        @traces[bud_push_elem.orig_rule_id].add_new_push_elem(bud_push_elem)
      else
        @traces[bud_push_elem.orig_rule_id] = RuleTrace.new(bud_push_elem)
      end
    end
  end

  # Keep the trace of all the push elements used to evaluate a rule
  class RuleTrace
    
    def initialize bud_push_elem
      @rule_id = bud_push_elem.orig_rule_id
      @push_elems = [bud_push_elem]
    end

    def add_new_push_elem bud_push_elem
      @push_elems <<  bud_push_elem
    end    

    # Remove the object id from the name to perform test
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

    def inspect
      @push_elems.map{|pshelt| "#{RuleTrace.sanitize_push_elem_name pshelt}"}
    end
  end

  class ProofTree

    def initialize
      @sources = []
      @destination = []
    end
  end
end