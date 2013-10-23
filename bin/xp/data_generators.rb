# executable code goes here
def run!  
  if ARGV.include?("xp1")
    ARGV.delete("xp1")
    WLXP::data_gen_xp1
    puts "Experience 1 generated"
  end
  if ARGV.include?("xp2")
    ARGV.delete("xp2")
    WLXP::data_gen_xp2
    puts "Experience 2 generated"
  end
  if ARGV.include?("xp3")
    ARGV.delete("xp3")
    WLXP::data_gen_xp3 70, false
    puts "Experience 3 generated"
  end
  if ARGV.include?("xp4")
    ARGV.delete("xp4")
    WLXP::data_gen_xp4
    puts "Experience 4 generated"
  end
  if ARGV.include?("xp5_base")
    ARGV.delete("xp5_base")
    WLXP::XP5::data_gen_xp5_base
    puts "Experience 5 base facts generated"
  end
  if ARGV.include?("xp5_rules")
    ARGV.delete("xp5_rules")
    WLXP::XP5::data_gen_xp5_rules 130
    puts "Experience 5 rules generated"
  end
end

# define one methods for each data set used in an experiment
module WLXP
  XP_FILE_DIR = "xp_files"
  PEER_IP="localhost"
  BASEPEERNAME="peer"
  
  # @return [String] representing a fact in wdl format for bootstrap program
  def create_fact(atom, peer, *tuple)
    fact_str = "fact #{atom}@#{peer}("
    tuple.each { |key,value| fact_str << "#{key}," }
    fact_str.slice!(-1)
    fact_str << ");"
    fact_str << "\n"
  end

  
  def declare_collection(relname, peer, arity)
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
    fout.close
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
  # peername running this program. It is used by start_peer in run_xp.rb
  def program_file_name xpname, peername
    return "#{xpname}_#{peername}"
  end

  # Generate the declaration of a peer for a given address
  def generate_peer str
    
  end  
end # module WLXP

module XP1
  include WLXP

  NB_PEERS = 3

  # Experience: Non-local rules
  #
  # [at alice] rel3@sue($Z) :- rel1@alice($X,$Y), rel2@bob($Y,$Z)
  #
  # Generate three programs
  def data_gen_xp1
    facts_per_relations = 1000
    range_value_in_facts = 100

    peer_str=<<END
peer #{BASEPEERNAME}#{PEER_IP}:12345;
peer #{BASEPEERNAME}2=#{PEER_IP}:12346;
peer #{BASEPEERNAME}3=#{PEER_IP}:12347;
END

    pg1 = peer_str + "collection ext per rel1@#{BASEPEERNAME}1(fi*,se*);"
    facts_per_relations.times do |i|
      pg1 += create_fact("rel1", "#{BASEPEERNAME}1", rand(range_value_in_facts), rand(range_value_in_facts))
    end
    pg1 += "rule rel3@#{BASEPEERNAME}3($Z):-rel1@#{BASEPEERNAME}1($X,$Y),rel2@#{BASEPEERNAME}2($Y,$Z);"
    write_xp_file(pg1, program_file_name(__method__, "#{BASEPEERNAME}1"))

    pg2 = peer_str + "collection ext per rel2@#{BASEPEERNAME}2(fi*,se*);"
    facts_per_relations.times do |i|
      pg2 += create_fact("rel1", "#{BASEPEERNAME}1", rand(range_value_in_facts), rand(range_value_in_facts))
    end
    write_xp_file(pg2, program_file_name(__method__, "#{BASEPEERNAME}2"))

    pg3 = peer_str +  "collection ext per rel3@#{BASEPEERNAME}3(fi*);"
    write_xp_file(pg3, program_file_name(__method__, "#{BASEPEERNAME}3"))
  end
end # module XP1

module XP2
  include WLXP

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
peer #{BASEPEERNAME}1=#{PEER_IP}:12345;
peer #{BASEPEERNAME}2=#{PEER_IP}:12346;
peer #{BASEPEERNAME}3=#{PEER_IP}:12347;
END
    3.times do |peer_ind|
      pg = peer_str
      relations_per_peers.times do |rel_ind|
        pg += declare_collection("rel#{rel_ind+1}","#{BASEPEERNAME}#{peer_ind+1}",2)
      end
      relations_per_peers.times do |rel_ind|
        facts_per_relations.times do |fact_int|
          pg += create_fact("rel#{rel_ind+1}","#{BASEPEERNAME}#{peer_ind+1}",rand(range_value_in_facts), rand(range_value_in_facts))
        end
      end
      write_xp_file(pg, program_file_name(__method__, "#{BASEPEERNAME}#{peer_ind}"))
    end
  end
end # module XP2

module XP3
  include WLXP

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
peer #{BASEPEERNAME}1=#{PEER_IP}:12345;
peer #{BASEPEERNAME}2=#{PEER_IP}:12346;
peer #{BASEPEERNAME}3=#{PEER_IP}:12347;
END
    # peer sue union
    pg = peer_str
    pg += declare_collection("union", "#{BASEPEERNAME}1",2)
    write_xp_file(pg, program_file_name(__method__, "#{BASEPEERNAME}1"))

    # remote peers alice and bob
    ["#{BASEPEERNAME}2","#{BASEPEERNAME}3"].each do |user|
      pg = peer_str
      pg += declare_collection("photos", user, 2)
      # matching
      (pourcent_matching*10).times do |fact_ind|
        pg += create_fact("photos", user, "Charlie", fact_ind)
      end
      # not matching
      (facts_per_relations-(pourcent_matching*10)).times do |fact_ind|
        pg += create_fact("photos", user, "Not Charlie", (pourcent_matching*10)+fact_ind)
      end
      write_xp_file(pg, program_file_name(__method__, user))
    end
    if qsq
      ["#{BASEPEERNAME}2","#{BASEPEERNAME}3"].each do |user|
        pg = "rule union@#{BASEPEERNAME}1(\"Charlie\",$X) :- photos@#{user}(\"Charlie\",$X)"
        write_xp_file(pg, program_file_name(__method__, user))
      end
    else
      ["#{BASEPEERNAME}2","#{BASEPEERNAME}3"].each do |user|
        pg =  "rule union@#{BASEPEERNAME}1($user,$X) :- photos@#{BASEPEERNAME}2($user,$X)" + "\n"
        pg += "rule union@#{BASEPEERNAME}1($user,$X) :- photos@#{BASEPEERNAME}3($user,$X)"
        write_xp_file(pg, program_file_name(__method__, user))
      end
    end
  end
end # module XP3

module XP4
  include WLXP

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
peer #{BASEPEERNAME}1=#{PEER_IP}:12345;
peer #{BASEPEERNAME}2=#{PEER_IP}:12346;
peer #{BASEPEERNAME}3=#{PEER_IP}:12347;
END
    # peer sue union
    pg = peer_str
    pg += declare_collection("union", "#{BASEPEERNAME}1",2)
    pg +=  "rule union@#{BASEPEERNAME}1($user,$X) :- photos@#{BASEPEERNAME}2($user,$X)" + "\n"
    pg += "rule union@#{BASEPEERNAME}1($user,$X) :- photos@#{BASEPEERNAME}3($user,$X)"
    write_xp_file(pg, program_file_name(__method__, "#{BASEPEERNAME}1"))

    # remote peers alice and bob
    ["#{BASEPEERNAME}2","#{BASEPEERNAME}3"].each do |user|
      pg = peer_str
      pg += declare_collection("friends", user, 1)
      facts_per_relations.times do |i|
        pg += create_fact("photos", user, "Friend#{i}")
      end
      write_xp_file(pg, program_file_name(__method__, user))
    end
  end
end # module XP4

module XP5
  include WLXP
  
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
      peer_str += "peer #{BASEPEERNAME}#{peer_ind}=#{PEER_IP}:#{port};" + "\n"
    end

    # program for each peer
    NB_PEERS.times do |peer_ind|
      pg = ''
      pg += peer_str
      # declare relations
      NB_RELATIONS.times do |rel_ind|
        pg << declare_collection("rel#{rel_ind}", "#{BASEPEERNAME}#{peer_ind}", 1)
      end
      # create facts
      NB_RELATIONS.times do |rel_ind|
        FACTS_PER_RELATIONS.times do |fact_ind|
          pg << create_fact("rel#{rel_ind}", "#{BASEPEERNAME}#{peer_ind}", rand(RANGE_VALUE_IN_FACTS))
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
              pg << "rule rel#{rel_ind}@#{BASEPEERNAME}#{peer_ind}($X):-rel#{(rel_ind+relation_degree+1).modulo(NB_RELATIONS)}@#{BASEPEERNAME}#{(peer_ind+peer_to_connect+1).modulo(NB_PEERS)}($X)"
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

module XP6
  include WLXP
  
  # Performance of deletion propagation
  #
  #
  def data_gen_xp6

  end
end # module XP6

include WLXP
# call run if this file is invoked from command-line as an executable
run! if __FILE__==$0