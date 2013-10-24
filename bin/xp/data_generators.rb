require 'csv'

# executable code goes here
def run_data_generators!
  if ARGV.include?("xp1")
    ARGV.delete("xp1")
    include WLXP1
    WLXP1::data_gen_xp1
    puts "Experience 1 generated"
  end
  if ARGV.include?("xp2")
    ARGV.delete("xp2")
    include WLXP2
    WLXP2::data_gen_xp2
    puts "Experience 2 generated"
  end
  if ARGV.include?("xp3")
    ARGV.delete("xp3")
    include WLXP3
    WLXP3::data_gen_xp3 70, false
    puts "Experience 3 generated"
  end
  if ARGV.include?("xp4")
    include WLXP4
    ARGV.delete("xp4")
    WLXP4::data_gen_xp4
    puts "Experience 4 generated"
  end
  if ARGV.include?("xp5_base")
    ARGV.delete("xp5_base")
    include WLXP5
    WLXP5::data_gen_xp5_base
    puts "Experience 5 base facts generated"
  end
  if ARGV.include?("xp5_rules")
    ARGV.delete("xp5_rules")
    include WLXP5
    WLXP5::data_gen_xp5_rules 130
    puts "Experience 5 rules generated"
  end
end

# define one methods for each data set used in an experiment
module WLGENERICXP
  XP_FILE_DIR = "xp_files"
  WLXP_PEER_IP = "localhost"
  WLXP_BASEPEERNAME = "peer"
  
  # @return [String] representing a fact in wdl format for bootstrap program
  def create_wlpg_fact(atom, peer, *tuple)
    fact_str = "fact #{atom}@#{peer}("
    tuple.each { |key,value| fact_str << "#{key}," }
    fact_str.slice!(-1)
    fact_str << ");"
    fact_str << "\n"
  end

  
  def declare_wlpg_collection(relname, peer, arity)
    coll_str = "collection ext per #{relname}@#{peer}("
    arity.times { |fi_num| coll_str << "field#{fi_num}*," }
    coll_str.slice!(-1)
    coll_str << ");"
    coll_str << "\n"
  end

  # Write str in a file filename under XP_FILE_DIR directory
  def write_xp_file str, filename
    Dir.mkdir(XP_FILE_DIR) unless File.exist?(XP_FILE_DIR)
    fout = File.new(File.join(XP_FILE_DIR,filename), "w+")
    fout.puts "#{str}"
    filepath = fout.path
    fout.close
    return filepath
  end

  # append str at the end of an existing file
  def append_xp_file str, filename
    raise WLError unless File.exist?(XP_FILE_DIR)
    fout = File.new(File.join(XP_FILE_DIR,filename), "a+")
    fout.puts "#{str}"
    fout.close
  end

  # Create the program file to be used by the peer with the name in the end of
  # the filename. Underscore separated filename, the last field should be the
  # peer name running this program. It is used by start_peer in run_xp.rb
  def program_file_name xpname, peername
    return "#{xpname}_#{peername}"
  end

  # Generate the declaration of a peer for a given address
  def generate_peer str
    
  end

  # Write files names to be used by run_xp @param files [Array] list of filename
  # to be used to run the experiment @pararm xp [String] the name of the
  # experimentation to run. It should match the name of the method in a module
  # that include WLXP
  def create_run_xp_file files, filename    
    Dir.mkdir(XP_FILE_DIR) unless File.exist?(XP_FILE_DIR)
    filepath = File.join(XP_FILE_DIR,filename)
    File.new(filepath, "w+") unless File.exist? filepath
    CSV.open(filepath, "w") do |csv|
      csv << files
    end
    return filepath
  end

  # Get the file that store all the other files needed for the experiment
  def get_run_xp_file
    raise "WLXP alone is not an experiment, choose one of the xp" unless defined? XPFILE
    return File.join(XP_FILE_DIR, XPFILE)
  end
end # module WLXP

module WLXP1
  include WLGENERICXP

  NB_PEERS = 3
  XPFILE = "XP1"

  # Experience: Non-local rules
  #
  # [at alice] rel3@sue($Z) :- rel1@alice($X,$Y), rel2@bob($Y,$Z)
  #
  # Generate three programs
  def data_gen_xp1
    facts_per_relations = 1000
    range_value_in_facts = 100
    xp_pg_arr = []

    peer_str=<<END
peer #{WLXP_BASEPEERNAME}1=#{WLXP_PEER_IP}:12345;
peer #{WLXP_BASEPEERNAME}2=#{WLXP_PEER_IP}:12346;
peer #{WLXP_BASEPEERNAME}3=#{WLXP_PEER_IP}:12347;
END

    pg1 = peer_str + "collection ext per rel1@#{WLXP_BASEPEERNAME}1(fi*,se*);"
    facts_per_relations.times do |i|
      pg1 += create_wlpg_fact("rel1", "#{WLXP_BASEPEERNAME}1", rand(range_value_in_facts), rand(range_value_in_facts))
    end
    pg1 += "rule rel3@#{WLXP_BASEPEERNAME}3($Z):-rel1@#{WLXP_BASEPEERNAME}1($X,$Y),rel2@#{WLXP_BASEPEERNAME}2($Y,$Z);"
    xp_pg_arr << write_xp_file(pg1, program_file_name(__method__, "#{WLXP_BASEPEERNAME}1"))

    pg2 = peer_str + "collection ext per rel2@#{WLXP_BASEPEERNAME}2(fi*,se*);"
    facts_per_relations.times do |i|
      pg2 += create_wlpg_fact("rel1", "#{WLXP_BASEPEERNAME}1", rand(range_value_in_facts), rand(range_value_in_facts))
    end
    xp_pg_arr << write_xp_file(pg2, program_file_name(__method__, "#{WLXP_BASEPEERNAME}2"))

    pg3 = peer_str +  "collection ext per rel3@#{WLXP_BASEPEERNAME}3(fi*);"
    xp_pg_arr << write_xp_file(pg3, program_file_name(__method__, "#{WLXP_BASEPEERNAME}3"))

    create_run_xp_file xp_pg_arr, XPFILE
  end
end # module XP1

module WLXP2
  include WLGENERICXP

  NB_PEERS = 3

  # Experience: Relation and peer variables
  #
  # [at sue] union@sue($X) :- peers@sue($Y,$Z), $Y@$Z($X)
  #
  # Generate three programs
  def data_gen_xp2
    relations_per_peers = 4
    facts_per_relations = 1000
    range_value_in_facts = 10000

    peer_str=<<END
peer #{WLXP_BASEPEERNAME}1=#{WLXP_PEER_IP}:12345;
peer #{WLXP_BASEPEERNAME}2=#{WLXP_PEER_IP}:12346;
peer #{WLXP_BASEPEERNAME}3=#{WLXP_PEER_IP}:12347;
END
    3.times do |peer_ind|
      pg = peer_str
      relations_per_peers.times do |rel_ind|
        pg += declare_wlpg_collection("rel#{rel_ind+1}","#{WLXP_BASEPEERNAME}#{peer_ind+1}",2)
      end
      relations_per_peers.times do |rel_ind|
        facts_per_relations.times do |fact_int|
          pg += create_wlpg_fact("rel#{rel_ind+1}","#{WLXP_BASEPEERNAME}#{peer_ind+1}",rand(range_value_in_facts), rand(range_value_in_facts))
        end
      end
      write_xp_file(pg, program_file_name(__method__, "#{WLXP_BASEPEERNAME}#{peer_ind}"))
    end
  end
end # module XP2

module WLXP3
  include WLGENERICXP

  NB_PEERS = 3

  # Experience: QSQ-style optimization
  #
  # [at sue] union2@sue($name,$X) :- photos@alice($name,$X) union2@sue($name,$X)
  # :- photos@bob($name,$X)
  #
  # If qsq=true Generate three programs for first case: QSQ optimization
  #
  # If qsq= false Generate three programs for second case: full materialization
  def data_gen_xp3 (pourcent_matching=50, qsq=true)

    facts_per_relations = 1000

    peer_str=<<END
peer #{WLXP_BASEPEERNAME}1=#{WLXP_PEER_IP}:12345;
peer #{WLXP_BASEPEERNAME}2=#{WLXP_PEER_IP}:12346;
peer #{WLXP_BASEPEERNAME}3=#{WLXP_PEER_IP}:12347;
END
    # peer sue union
    pg = peer_str
    pg += declare_wlpg_collection("union", "#{WLXP_BASEPEERNAME}1",2)
    write_xp_file(pg, program_file_name(__method__, "#{WLXP_BASEPEERNAME}1"))

    # remote peers alice and bob
    ["#{WLXP_BASEPEERNAME}2","#{WLXP_BASEPEERNAME}3"].each do |user|
      pg = peer_str
      pg += declare_wlpg_collection("photos", user, 2)
      # matching
      (pourcent_matching*10).times do |fact_ind|
        pg += create_wlpg_fact("photos", user, "Charlie", fact_ind)
      end
      # not matching
      (facts_per_relations-(pourcent_matching*10)).times do |fact_ind|
        pg += create_wlpg_fact("photos", user, "Not Charlie", (pourcent_matching*10)+fact_ind)
      end
      write_xp_file(pg, program_file_name(__method__, user))
    end
    if qsq
      ["#{WLXP_BASEPEERNAME}2","#{WLXP_BASEPEERNAME}3"].each do |user|
        pg = "rule union@#{WLXP_BASEPEERNAME}1(\"Charlie\",$X) :- photos@#{user}(\"Charlie\",$X)"
        write_xp_file(pg, program_file_name(__method__, user))
      end
    else
      ["#{WLXP_BASEPEERNAME}2","#{WLXP_BASEPEERNAME}3"].each do |user|
        pg =  "rule union@#{WLXP_BASEPEERNAME}1($user,$X) :- photos@#{WLXP_BASEPEERNAME}2($user,$X)" + "\n"
        pg += "rule union@#{WLXP_BASEPEERNAME}1($user,$X) :- photos@#{WLXP_BASEPEERNAME}3($user,$X)"
        write_xp_file(pg, program_file_name(__method__, user))
      end
    end
  end
end # module XP3

module WLXP4
  include WLGENERICXP

  NB_PEERS = 3

  # Overhead of provenance
  #
  # Adding/deleting facts
  #
  # Use sync_do methods in the runner to send between 0 and 1400 add/remove
  # orders
  def data_gen_xp4
    facts_per_relations = 1500

    peer_str=<<END
peer #{WLXP_BASEPEERNAME}1=#{WLXP_PEER_IP}:12345;
peer #{WLXP_BASEPEERNAME}2=#{WLXP_PEER_IP}:12346;
peer #{WLXP_BASEPEERNAME}3=#{WLXP_PEER_IP}:12347;
END
    # peer sue union
    pg = peer_str
    pg += declare_wlpg_collection("union", "#{WLXP_BASEPEERNAME}1",2)
    pg +=  "rule union@#{WLXP_BASEPEERNAME}1($user,$X) :- photos@#{WLXP_BASEPEERNAME}2($user,$X)" + "\n"
    pg += "rule union@#{WLXP_BASEPEERNAME}1($user,$X) :- photos@#{WLXP_BASEPEERNAME}3($user,$X)"
    write_xp_file(pg, program_file_name(__method__, "#{WLXP_BASEPEERNAME}1"))

    # remote peers alice and bob
    ["#{WLXP_BASEPEERNAME}2","#{WLXP_BASEPEERNAME}3"].each do |user|
      pg = peer_str
      pg += declare_wlpg_collection("friends", user, 1)
      facts_per_relations.times do |i|
        pg += create_wlpg_fact("photos", user, "Friend#{i}")
      end
      write_xp_file(pg, program_file_name(__method__, user))
    end
  end
end # module XP4

module WLXP5
  include WLGENERICXP
  
  NB_PEERS = 10
  NB_RELATIONS = 100
  FACTS_PER_RELATIONS = 1000
  RANGE_VALUE_IN_FACTS = 10000
  RELATION_DEGREE_CONNECTION = 1000

  # Size of the provenance graph
  #
  # Generate base facts: this quite long due too large among of text to write
  def data_gen_xp5_base

    # declare peers
    peer_str=''
    NB_PEERS.times do |peer_ind|
      port = 12340 + peer_ind
      peer_str += "peer #{WLXP_BASEPEERNAME}#{peer_ind}=#{WLXP_PEER_IP}:#{port};" + "\n"
    end

    # program for each peer
    NB_PEERS.times do |peer_ind|
      pg = ''
      pg += peer_str
      # declare relations
      NB_RELATIONS.times do |rel_ind|
        pg << declare_wlpg_collection("rel#{rel_ind}", "#{WLXP_BASEPEERNAME}#{peer_ind}", 1)
      end
      # create facts
      NB_RELATIONS.times do |rel_ind|
        FACTS_PER_RELATIONS.times do |fact_ind|
          pg << create_wlpg_fact("rel#{rel_ind}", "#{WLXP_BASEPEERNAME}#{peer_ind}", rand(RANGE_VALUE_IN_FACTS))
        end
      end
      write_xp_file(pg, program_file_name(__method__, "user#{peer_ind}"))
    end
  end

  # Size of the provenance graph
  #
  # Generate nb_rules_per_peer new rules for each peers for which facts has been
  # created with xp5_base.  With the setting of the paper this number should be
  # between: 1 and 100 000
  def data_gen_xp5_rules nb_rules_per_peer=15
    NB_PEERS.times do |peer_ind|
      pg = ''
      rule_created = 0
      while rule_created < nb_rules_per_peer
        NB_RELATIONS.times do |rel_ind|
          relation_degree = 0
          while rule_created < nb_rules_per_peer and relation_degree < RELATION_DEGREE_CONNECTION
            peer_to_connect = 0
            while rule_created < nb_rules_per_peer and relation_degree < RELATION_DEGREE_CONNECTION and peer_to_connect < NB_PEERS
              pg << "rule rel#{rel_ind}@#{WLXP_BASEPEERNAME}#{peer_ind}($X):-rel#{(rel_ind+relation_degree+1).modulo(NB_RELATIONS)}@#{WLXP_BASEPEERNAME}#{(peer_ind+peer_to_connect+1).modulo(NB_PEERS)}($X)"
              pg << "\n"
              rule_created += 1
              relation_degree += 1
              peer_to_connect += 1
            end
          end
        end
      end
      write_xp_file(pg, program_file_name(__method__, "user#{peer_ind}"))
    end
  end
end # module XP5

module WLXP6
  include WLGENERICXP
  
  # Performance of deletion propagation
  #
  #
  def data_gen_xp6

  end
end # module XP6

# call run if this file is invoked from command-line as an executable
run_data_generators! if __FILE__==$0