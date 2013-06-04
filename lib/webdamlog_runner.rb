# #!/usr/bin/env ruby

# Interface to use the webdamlog engine from an external application such as a
# rail application

require_relative 'wlbud'

module WLRunner
  include WLBud

  # Create a new webdamlog engine object ready to be run
  #
  def self.create (username, pg_file, port, options={})
    klass_name = "ClassWLEngineOf#{username}On#{port}".split('_').collect!{ |w| w.capitalize }.join
    ano_klass = Class.new WLBud::WL
    klass = Object.const_set klass_name, ano_klass
    return klass.new(username, pg_file, {:port => port, :rule_dir => options[:rule_dir]})
  end

  def run
    run_bg
  end

  def add_peer
    
  end

  def add_collection
    
  end

  def add_fact
    
  end

  def add_rule
    
  end
end

