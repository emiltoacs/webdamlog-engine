# Use to override some bud methods in viz_util.rb
#
module VizUtil

  # Override bud
  #
  # Include meta_table after tick 0 since in webdamlog they may have changed
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