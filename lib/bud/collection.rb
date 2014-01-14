# Bud methods overridden in Webdamlog
module Bud

  # Add the rule from which the push element has been created
  class PushElement < BudCollection

    def initialize(name_in, bud_instance, collection_name, given_schema, defer_schema, & blk)
      super
      @orig_rule_id = bud_instance.current_eval_rule_id 
    end

  end
  
end