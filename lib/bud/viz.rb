# Use to override some bud methods in viz.rb
#
class VizOnline
  
  # Override bud
  #
  # Include meta_table after tick 0 since in webdamlog they may have changed
  #
  def do_cards(wlmode=false)
    @bud_instance.tables.each do |t|
      tab = t[0]
      next if tab == :the_big_log
      unless wlmode
        next if @bud_instance.budtime > 0 and META_TABLES.include? tab.to_s # just skip this ligne if wl
      end
      add_rows(t[1], tab)
      if t[1].class == Bud::BudChannel
        add_rows(t[1].pending, "#{tab}_snd")
      end
      @logtab.tick
    end
  end
end


