#!/usr/bin/env ruby

# executable code goes here
def run!
  
end

# define one methods for each data set used in an experiement
module WLXP

  # [at alice]
  # rel3@sue($Z) :- rel1@alice($X,$Y), rel2@bob($Y,$Z)
  #
  # generate the program for alice, bob and sue
  def xp1
    pg1=<<END
peer peer1=localhost:12345;
peer peer2=localhost:12346;
peer peer3=localhost:12347;
collection ext per rel1@peer1(fi*,se*);
END
    #add here facts for peer1

    pg2=<<END
peer peer1=localhost:12345;
peer peer2=localhost:12346;
peer peer3=localhost:12347;
collection ext per rel2@peer2(fi*,se*);
END
    #add here facts for peer2

    pg3=<<END
peer peer1=localhost:12345;
peer peer2=localhost:12346;
peer peer3=localhost:12347;
collection ext per rel3@peer3(fi*,se*);
END
    #add here facts for peer3    
    
  end

  
  def create_fact(atom, peer, tuple={})
    
  end
end

# call run if this file is invoked from command-line as an executable
run! if __FILE__==$0