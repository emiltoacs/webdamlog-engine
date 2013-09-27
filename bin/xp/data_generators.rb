# #!/usr/bin/env ruby

# executable code goes here
def run!  
  if  ARGV.include?("xp1")
    ARGV.delete("xp1")
    WLXP::xp1
    puts "Experience 1 generated"
  end
end

# define one methods for each data set used in an experiement
module WLXP

  XP_FILE_DIR = "xp_files"

  # Experience: Non-local rules
  #
  # [at alice] rel3@sue($Z) :- rel1@alice($X,$Y), rel2@bob($Y,$Z)
  #
  # Generate the program for alice, bob and sue
  def xp1
    facts_per_relations = 1000
    range_value_in_facts = 100

    peer_str=<<END
peer peer1=localhost:12345;
peer peer2=localhost:12346;
peer peer3=localhost:12347;
END

    pg1 = peer_str << "collection ext per rel1@peer1(fi*,se*);"
    facts_per_relations.times do |i|
      pg1 << create_fact("rel1", "peer1", rand(range_value_in_facts), rand(range_value_in_facts))
    end
    # rule for peer1
    pg1<<"rule rel3@peer3($Z):-rel1@peer1($X,$Y),rel2@peer2($Y,$Z);"
    write_xp_file pg1, "xp1_peer1"

    pg2 = peer_str << "collection ext per rel2@peer2(fi*,se*);"
    facts_per_relations.times do |i|
      pg2 << create_fact("rel1", "peer1", rand(range_value_in_facts), rand(range_value_in_facts))
    end
    write_xp_file pg2, "xp1_peer2"

    pg3 = peer_str <<  "collection ext per rel3@peer3(fi*);"
    write_xp_file pg3, "xp1_peer3"
  end


  # Experience: Relation and peer variables [at sue] union@sue($X) :-
  # peers@sue($Y,$Z), $Y@$Z($X)
  #
  def xp2
    

    peer_str=<<END
peer peer1=localhost:12345;
peer peer2=localhost:12346;
peer peer3=localhost:12347;
END
    
  end


  # @return [String] representing a fact in wdl format for bootstrap program
  def create_fact(atom, peer, *tuple)
    fact_str = "fact #{atom}@#{peer}("
    tuple.each { |key,value| fact_str << "#{key}," }
    fact_str.slice!(-1)
    fact_str << ");"
    fact_str << "\n"
  end

  # write str in a file filename under XP_FILE_DIR directory
  def write_xp_file str, filename
    Dir.mkdir(XP_FILE_DIR) unless File.exist?(XP_FILE_DIR)
    fout = File.new(File.join(XP_FILE_DIR,filename), "w+")
    fout.puts "#{str}"
    fout.close
  end

end

include WLXP

# call run if this file is invoked from command-line as an executable
run! if __FILE__==$0