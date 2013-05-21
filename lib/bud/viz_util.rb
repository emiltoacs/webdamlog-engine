# Use to override some bud methods in viz_util.rb
#
# Add depends_time
#
class VizHelper
  def initialize(tabinf, cycle, depends, rules, dir, provides, depends_time=[])
    @t_tabinf = tabinf
    @t_cycle = cycle
    @t_depends = depends
    @t_rules = rules
    @t_provides = provides
    @dir = dir
    @t_depends_time = depends_time
    super()
  end

  # Change t_depends to t_depends_time
  #
  def summarize(dir, schema)
    table_io = {}
    cardinalities.to_a.sort{|a, b| a[0] <=> b[0]}.each do |card|
      table_io["#{card.table}_#{card.bud_time}"] = start_table(dir, card.table, card.bud_time, schema[card.table])
    end

    full_info.each do |info|
      write_table_content(table_io["#{info.table}_#{info.bud_time}"], info.row)
    end

    table_io.each_value do |tab|
      end_table(tab)
    end

    # fix: nested loops
    times.to_a.sort.each do |time|
      card_info = {}
      cardinalities.each do |card|
        if card.bud_time == time.bud_time
          card_info[card.table] = card.cnt
        end
      end

      d = "#{@dir}/tm_#{time.bud_time}"
      write_graphs(@t_tabinf, builtin_tables, @t_cycle, @t_depends_time, @t_rules, d,
                   @dir, nil, false, nil, time.bud_time, card_info)
    end
  end
end

module VizUtil
  
  # Override bud
  #
  # Include meta_table after tick 0 since in webdamlog they may have changed
  # Add meta_tabs t_depends_time 
  #
  def get_meta2(dir)
    meta_tabs = {"t_table_info" => :tabinf, "t_table_schema" => :tabscm, "t_cycle" => :cycle, "t_depends" => :depends, "t_rules" => :rules, "t_provides" => :provides}
    meta = {}
    data = []

    dir = Dir.glob("#{dir}/bud*").first
    ret = DBM.open("#{dir}/the_big_log.dbm")
    ret.each_pair do |k, v|
      key = MessagePack.unpack(k)
      tab = key.shift
      time = key.shift
      # paa: after switch to 1.9, v appears to always be empty
      tup = key[0]
      MessagePack.unpack(v).each {|val| tup << val}
      if meta_tabs[tab]
        #raise "non-zero budtime.(tab=#{tab}, time=#{time})  sure this is metadata?" if time != 0 #and strict
        meta[meta_tabs[tab]] ||= []
        meta[meta_tabs[tab]] << tup
        # add budtime for depends
        if tab == "t_depends"
          deptime = "depends_time".to_sym
          meta[deptime] ||= []
          meta[deptime] << [time, tup]
        end
      else
        data << [time, tab, tup]
      end
    end

    meta_tabs.each_value do |tab|
      meta[tab] ||= []
    end

    meta[:schminf] = {}
    meta[:tabscm].each do |ts|
      tab = ts[0].to_s
      unless meta[:schminf][tab]
        meta[:schminf][tab] = []
      end
      meta[:schminf][tab][ts[2]] = ts[1] if ts[2]
    end
    return meta, data
  end
end