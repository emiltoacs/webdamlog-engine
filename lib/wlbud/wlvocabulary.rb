module WLBud

  #The WLVocabulary classes are instantiated using the Treetop parsing
  #gem and all inherit the Treetop::Runtime::SyntaxNode class.
  #When a .wl file is parsed, a tree of nodes is created, with each 
  #node (not only the leaves) are assigned a proper subclass of WLVocabulary.
  #
  class WLVocabulary < Treetop::Runtime::SyntaxNode
    
    public     
    def to_s
      self.text_value
    end
    protected
    #    #The firstchild class
    #    def firstchild
    #      self.elements.first
    #    end
  end
  
  #The WLrule class is used to store the content of parsed WLRules.
  class WLRule < WLVocabulary
    @@index=0
    attr_accessor :has_self_join
    attr_reader :index, :dic_made
    # The budvar dictionary is a hash defines variables included in the
    # conversion from webdamlog-formatted rule to bud-formatted rule. Its key is
    # the name of the relation of which the variable is bound to. Its value
    # correspond to the local variable position where this relation appear.
    #
    attr_reader :dic_relation_name
    # Inverted dictionary corresponding to dic_relation_name ie. it maps body
    # atom position to string name of the relation
    #
    attr_reader :dic_invert_relation_name
    # The wlvar dictionary is a hash that contains the position of the
    # variables of each atom of the body. It takes as key the field value of the
    # variable, e.g. '$x' and as value it's location in the following format :
    # 'relation_position.field_position'
    # Remark: position always start from 0
    #
    attr_reader :dic_wlvar
    # The var dictionary is a hash that contains the name of the constants of
    # each atom of the body. It takes as key the field value of the constant,
    # e.g. 'a' and as value it's location in the following format :
    # 'relation_position.field_position'
    # Remark: position always start from 0
    #
    attr_reader:dic_wlconst
    
    # Creates a new WLRule and instantiate empty dictionaries for that rule.
    #
    # The parameters are given by WebdamLogGrammarParser the
    # Treetop::Runtime::CompiledParser
    # * input
    # * interval
    # * elements
    #
    def initialize (a1,a2,a3)
      @dic_made=false
      # TODO add self-join detection and think of the structure to use to create
      # the symbolic predicates of linkage during joins instead of named
      # perspective. See functionmake_combos in wlprogram
      # @has_self_join=false
      @index=@@index+=1
      @body=nil      
      @dic_relation_name={}
      @dic_invert_relation_name={}
      @dic_wlvar={}
      @dic_wlconst={}
      super(a1,a2,a3)
    end
    
    public
            
    #prints to the screen information about the rule
    def show
      puts "Class name : #{self.class}"
      puts "Head : #{show_head}" 
      puts "Body : #{show_body}"
      puts "--------------------------------------------------------"
    end
     
    #return the head atom of the rule
    def head
      self.atom
    end

    #return the body atoms of the rule in an array
    def body
      if @body.nil?
        array=[];        
        self.atoms.elements.each {|rf| if rf.is_a?(WLBud::WLAtom) then array << rf else 
            if rf.elements.first.is_a?(WLBud::WLAtom) then array << rf.elements.first else raise WLErrorGrammarParsing end end}
        @body = array
      end
      return @body
    end
    
    #return true if head is local, false otherwise.
    def head_local?
      return self.head.local?
    end
    
    #Checks if a rule is a delegation
    def nonlocal?(peername)
      self.body.each { |atom|
        unless atom.local?(peername)
          return true
        end
      }
      return false
    end

    #returns all atoms of the rule in an array (head + body).
    def atoms
      [self.head,self.body].flatten
    end

    # Make dictionary : creates hash dictionaries for WLvariables and constants.
    # These dictionaries take as key the field value as it appears in the .wl
    # file along with their position in the rule to disambiguate in case of self
    # joins. As value it's location in the following format :
    # 'relation_pos.field_pos'
    #
    # Detect variable by checking field names starting with a '$' sign
    # This populate the four dictionaries
    def make_dictionaries ()
      self.body.each_with_index do |atom,n|
        # field variable goes to wlvar and constant to const dictionary
        atom.fields.each_with_index do |f,i|
          str = "#{n}.#{i}"
          # if the rule is not a temporary variable
          #          unless is_tmp
          #            str = "#{atom.name}.#{@wlcollections["#{atom.rrelation.text_value}_at_#{atom.rpeer.text_value}"].fields.fetch(i)}"
          #          else
          #            str = "#{atom.name}.pos#{i}"
          #          end
          unless f.=~ /'^$*'/.nil?
            if self.dic_wlvar.has_key?(f)
              self.dic_wlvar[f] << str
            else
              self.dic_wlvar[f]=[str]
            end
          else
            if self.dic_wlconst.has_key?(f)
              self.dic_wlconst[f] << str
            else
              self.dic_wlconst[f]=[str]
            end
          end
        end
        # TODO list all the useful relation, a relation is useless if it's arity
        # is more than zero and none variable and constant inside aren't used in
        # other relation of this rule insert here the function
        if self.dic_relation_name.has_key?(atom.name)
          self.dic_relation_name[atom.name] << n
        else
          self.dic_relation_name[atom.name]=[n]
        end
        if self.dic_invert_relation_name.has_key?(n)
          self.dic_invert_relation_name[n] << atom.name
        else
          self.dic_invert_relation_name[n]=[atom.name]
        end
      end
      @dic_made = true
    end

    private
    
    def show_head
      self.head.show
    end

    def show_body
      s=""
      self.atoms.elements.each do |rf|
        if rf.is_a?(WLBud::WLAtom)
          s << rf.show
        else
          if rf.elements.first.is_a?(WLBud::WLAtom) 
            s << rf.elements.first.show
          else 
            raise WLErrorGrammarParsing
          end
        end
        return s
      end
    end
  end
  
  #The WLrule class is used to store the content of parsed WL facts.
  class WLFact < WLVocabulary
    public
    
    def initialize (a1,a2,a3)
      @contents=nil
      super(a1,a2,a3)
    end
    #prints to the screen information about the extensional fact.
    def show
      puts "Class name : #{self.class}"
      puts "Content : #{self.text_value}"
      puts "Relation name : #{self.name}" 
      puts "Peer name: #{self.peer_name.text_value}"
      puts "Data content : #{self.fields.text_value}"      
      puts "--------------------------------------------------------"
    end
    #return an array of strings containing each element of the Fact.
    def contents
      if @contents.nil?
        array=[]
        self.fields.text_value.split(',').each {|s| array << s}
        @contents=array
      end
      return @contents
    end
    #returns the name of the relation of the fact.
    def name
      "#{self.relation_name.text_value}_at_#{self.peer_name.text_value}"
    end
  end
  
  # The WLcollection class is used to store the content of parsed WL relation
  # names (Bloom collection) that is the declaration of predicate in the
  # beginning of the program file.
  class WLCollection < WLVocabulary

    attr_reader :type, :persistent

    def initialize(a1,a2,a3)
      @schema=nil
      @fields=nil
      @type=nil
      @persitent=false
      super(a1,a2,a3)
    end

    public
    #prints to the screen information about the extensional fact.    
    def show
      puts "Class name : #{self.class}"
      puts "Content : #{self.text_value}"
      puts "Relation name : #{self.name}" 
      puts "Schema key(s) : #{self.col_fields.keys.text_value}"
      puts "Schema value(s) : #{self.col_fields.values.text_value}"
      puts "--------------------------------------------------------"
    end
    
    #This method generates the schema corresponding to this 'collection'
    def schema
      if @schema.nil?
        keys = [];
        values=[];
        self.col_fields.keys.text_value.split(',').each {|s| keys << s.split('*').first.to_sym}
        self.col_fields.values.text_value.split(',').each {|s| values << s.to_sym}
        h = {keys => values}
        @schema=h
      end
      return @schema
    end

    # Return the relation type
    def get_type
      rel_type.type
    end

    # Return true if it is a persistent relation
    def persistent?
      return rel_type.persistent?
    end

    # Return true if the relation is local.
    #
    def local?(budinstance=nil)
      if budinstance.nil?
        self.peer.eql?('me') 
      else
        self.peer.eql?('me') or self.peer.eql?(budinstance.peername)
      end
    end

    # Return the name of the peer
    #
    def peer
      self.peer_name.text_value
    end
    
    # Return an array of strings containing each element of the Fact.
    #
    def fields
      if @fields.nil?
        array=[];
        self.col_fields.keys.elements.each {|s| array << s.text_value.split('*').first}
        self.col_fields.values.elements.each {|s| array << s.text_value.split(',').first}
        @fields=array
      end
      return @fields
    end
    
    #This method gives the name of the relation.
    def name
      WLCollection.create_relation_name_string(self)
    end

    # Create a string for the name of the relation that fits bud restriction
    #
    # It substitute @ by '_at_'
    #
    def self.create_relation_name_string (a_WLCollection)
      raise WLErrorTyping, "try to create a name for an atom: #{a_WLCollection.class} which is not a WLCollection object." unless a_WLCollection.is_a?(WLCollection)
      "#{a_WLCollection.relation_name.text_value}_at_#{a_WLCollection.peer}"
    end
  end

  class WLRelType < WLVocabulary
    attr_reader :type    
    def initialize (a1,a2,a3)
      super(a1,a2,a3)
      @type=nil
      @persistent=false
    end
    def persistent?
      return @persistent
    end
  end

  class WLExtensional < WLRelType
    def initialize (a1,a2,a3)
      super(a1,a2,a3)
      @type = :Extensional
      @persistent = nil
    end
    public
    def persistent?
      if @persistent.nil?
        @persistent = (not persistent.elements.nil?)
      else
        return @persistent
      end
    end
  end
  
  class WLIntensional < WLRelType
    def initialize (a1,a2,a3=nil)
      # a3 default value is nil since WLIntensional rule is terminal node the elements methods is not available
      super(a1,a2,a3)
      @type = :Intensional
      @persistent=false
    end
  end

  class WLIntermediary < WLRelType
    def initialize (a1,a2,a3)
      super(a1,a2,a3)
      @type = :Intermediary
      @persistent = nil
    end
    public
    def persistent?
#      p "self here: #{self.text_value}"
#      p "self from #{self.input} interval #{self.interval}"
#      puts self.parent
#      p "self here: #{self.inspect}"
#      p "per elem : #{persistent.elements}"
      if @persistent.nil?
        @persistent = (not persistent.elements.nil?)
      else
        return @persistent
      end
    end
  end

  module WLItem
  end
  
  class WLFields < WLVocabulary
  end
  
  class WLRelation < WLVocabulary
  end
  
  class WLVar < WLVocabulary
  end
  
  #WebdamLog Atom, element of a WLrule.
  class WLAtom < WLVocabulary    
    def initialize (a1,a2,a3)
      @name_choice=false
      @variables=nil
      super(a1,a2,a3)      
    end
    public
    #return true if the atom is local, false otherwise
    #
    def local?(peername)
      self.rpeer.text_value.eql?('me') or self.rpeer.text_value.eql?(peername)
    end
   
    #return the variables included in the atom in an array format.
    #e.g. : [relation_var,peer_var,[field_var1,field_var2,...]]
    #
    def variables
      if @variables.nil?
        vars = []
        relation=self.rrelation.text_value
        peer=self.rpeer.text_value
        #Check if relation and/or peer are variables.
        if relation.include?('$') then vars << relation else vars << nil end
        if peer.include?('$') then vars << peer else vars << nil end
        vars << self.rfields.variables
        @variables=vars
      end
      return @variables
    end
    
    #returns the fields of the atom (variables and constants) in an array format
    #
    def fields
      self.rfields.fields
    end
    
    # This method gives the name of the relation. It may also change the name
    # of the relation on this rule only, in order to implement renaming
    # strategies for self joins.
    def name(newname=nil)
      if !@name_choice then @name = "#{self.rrelation.text_value}_at_#{self.rpeer.text_value}" end
      unless newname.nil?
        @name = newname
        @name_choice = true
      end
      return @name
    end

    # Pretty print for atoms
    def show
      str = "\n\t-#{self.class} , #{text_value},"
      variables
      if @variables[0].nil?
        str << self.rrelation.text_value << " "
      else
        @variables[0]
      end
      if @variables[1].nil?
        str << self.rpeer.text_value << " "
      else
        @variables[1]
      end
      str << fields.inspect << "\n"
    end
  end
  

  class WLPeer < WLVocabulary
  end
  
  
  #The Rfields class corresponds to nodes contains the fields of atoms in rules.
  class WLRfields < WLVocabulary
    def initialize(a1,a2,a3)
      @fields=nil
      @variables=nil
      super(a1,a2,a3)
    end    
    #this methods gives only variable fields (in text value)
    def variables
      if @variables.nil?
        f = []
        self.rtokens.elements.each {|t| f << t.elements.first.text_value.split(',').first unless !t.text_value.include?('$')}
        f << self.rtoken.text_value unless !self.rtoken.text_value.include?('$')
        @variables=f
      end
      return @variables
    end
    #this methods hands in all fields (in text value) 
    def fields
      if @fields.nil?
        f = []
        self.rtokens.elements.each {|t| f << t.elements.first.text_value.split(',').first}# unless t.text_value.include?(',')}
        f << self.rtoken.text_value
        @fields=f
      end
      return @fields
    end
  end
  
  class WLPeerName < WLVocabulary
    def name
      self.peer_name.text_value
    end
    def address
      self.peer_address.text_value
    end
  end
  
  class WLComment < WLVocabulary
    def show
      puts "--------------------------------------------------------"
      puts 'I am a comment :) .'
    end
  end
end
