# ####License####
#  File name wlextendsbud.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - Aug 7, 2012
# 
#   Encoding - UTF-8
# ####License####

module Bud
  # Puts content of a collection
  #
  # Remark: call the sort method of BudCollection
  #
  # === Parameter
  # * +collmethod+ should be the method use to the BudCollection
  #
  def put_content_in_order(collmethod)
    puts"\n"
    puts"---- put_content_in_order: #{collmethod.tabname} BEGIN #{budtime}-----"
    collmethod.sort.each{|t| puts t.inspect}
    puts"---- put_content_in_order #{collmethod.tabname} END #{budtime}-----"
    puts"\n"
  end
  
  # Puts content of a collection
  #
  # Remark call the to_a method to cast collection then sort the array
  #
  # === Parameter
  # * +collmethod+ should be the reference to the BudCollection
  #
  def put_content_in_order_as_ruby_code(collmethod)
    puts"\n"
    puts"---- put_content_in_order_as_ruby_code: #{collmethod.tabname} BEGIN #{budtime}-----"
    p collmethod.to_a.sort
    puts"---- put_content_in_order_as_ruby_code: #{collmethod.tabname} END #{budtime}-----"
    puts"\n"
  end
end
