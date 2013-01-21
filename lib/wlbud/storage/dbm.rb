# ####License####
#  File name dbm.rb
#  Copyright © by INRIA
# 
#  Contributors : Webdam Team <webdam.inria.fr>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
# 
#   WebdamLog - May 13, 2012
# 
#   Encoding - UTF-8
# ####License####

require 'dbm'

module DBM_Utility

  def open(filename)
    unless File.exists?(filename)
      raise StandardError, "No file #{filename}"
    else
      unless dbm = DBM.new(filename, 0666, DBM::READER)
        raise StandardError, "failed to open dbm database #{filename}"
      end
    end
    return dbm
  end 
end
