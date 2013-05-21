# Use to override some bud methods in viz.rb
#
class GraphGen
  
  # Override bud
  #
  # Add filter on rule by timesteps to display only active rules during this timestep
  # parameter has changed to receive depends_time array
  #
  def process(depends_time)
    raise "error you should have override depends to add time like this [time, tup]" unless depends_time.first.size == 2

    # collapsing NEG/+ cycles. we want to create a function from any predicate
    # to (cycle_name or bottom) bottom if the predicate is not in a NEG/+ cycle.
    # otherwise, its name is "CYC" + concat(sort(predicate names))
    depends_time.each do |d|
      time = d[0]
      # skip if budtime not current budtime for this graph
      next if @budtime != time
      # b/c bud_obj was pruned before serialization...
      bud_obj, rule_id, lhs, op, body, nm, in_body = d[1].to_a
      head = lhs
      body = body

      if @builtin_tables.has_key?(head.to_sym) or @builtin_tables.has_key?(body.to_sym)
        next
      end

      head = name_of(head)
      body = name_of(body)
      addonce(head, (head != lhs), true)
      addonce(body, (body != body))
      addedge(body, head, op, nm, (head != lhs), rule_id)
    end
  end
end
