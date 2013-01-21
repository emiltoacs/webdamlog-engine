# ####License####
#  File name wlprogram.rb
#  Copyright © by INRIA
#
#  Contributors : Webdam Team <webdam.inria.fr>
#       Jules Testard <jules[dot]testard[@]mail[dot]mcgill[dot]ca>
#       Emilien Antoine <emilien[dot]antoine[@]inria[dot]fr>
#
#   WebdamLog - 30 juin 2011
#
#   Encoding - UTF-8
# ####License####

module WLBud
 
  # :title: WLProgram WLProgram is a class that parses and interprets
  # WebdamLog files (.wl). Parsing is done using the Treetop module (and
  # wlgrammar.treetop file). Interpretation is done using the three following
  # methods. They all generate an [name,proc] array used by the WLBud
  # initializer to create an instance method that would be understood as a
  # Bloom collectionment by Bloom engine:
  # * <tt>--generate_schema</tt> Generates relations names.
  # * <tt>--generate_bootstrap</tt> Generates extensional facts.
  # * <tt>--translate_rules</tt> Generates webdamlog rules. #A printing function
  #   (showing information to the screen) is also avaible :
  # * <tt>--print_content</tt> print all rules, facts and relations to the
  #   screen.
  #
  class WLProgram    
    attr_reader :wlcollections, :peername, :wlpeers, :wlfacts
    attr_accessor :localrules, :nonlocalrules, :delegations, :rewrittenlocal    
    
    # The initializer for the WLBud program takes in a filename corresponding to
    # a WebdamLog file (.wl) and parses each line in the file either as a
    # relation declaration, a fact or a WebdamLog rule.
    # ==== Attributes
    #
    # * +peername+ identifier for the peer hosting this program to identify the
    #   local data
    # * +filename+ the filename containing the program (or any IO object
    #   readable)
    # * +[DEPRECATED] make_binary_rules+ false by default
    # * +options+ ...
    #
    # ==== Options
    #
    # * +:debug+ very verbose debug
    #
    # === Return
    # the list of declaration of relations to create as WLCollection object
    #
    def initialize (peername,filename,ip,port,make_binary_rules=false,options={})
      raise WLBud::WLError, 'Program file has to be a string' unless filename.is_a?(String)
      #absolute path file to the program *.wl
      @programfile = filename
      @parser = WLBud::WebdamLogGrammarParser.new
      @peername=peername
      @peername.freeze
      @ip=ip
      @ip.freeze
      @port=port
      @port.freeze
      # A counter for this program to name rule with a uniq ID
      #
      @next=0
      @make_binary_rules=make_binary_rules #Use binary rule format (use Bloom pairs keyword instead of combos).
      my_address = "#{ip}:#{port}"
      # List of the webdamlog relation inserted in that peer
      #
      @wlcollections={} 
      # List of known peers
      #
      # Define here some std alias for local peer
      # * @peername
      # * 'localhost'
      # * 'me'
      @wlpeers={}
      @wlpeers[@peername]=my_address
      @wlpeers['localhost']=my_address
      @wlpeers['me']=my_address
      # List of bootstrap facts ie. the facts given in the program file
      # === data struct
      # Array:(WLBud:WLFact)
      #
      @wlfacts=[]
      # The local rules straightforward to convert into bud (simple syntax
      # translation)
      # === data struct
      # Array:(WLBud:WLRule)
      #
      @localrules=[]
      # Nonlocal rules in WL are never converted into Bloom rules directly (as
      # opposed to previous types of rules). They are split in two part one
      # stored in delegation that must be send to a remote peer and another part
      # stored in rewrittenlocal that correspond to the longest sequence possible
      # to evaluate locally, that may be the whole original rule if only the head
      # was not local.
      # === data struct
      # Array:(WLBud:WLRule)
      #
      @nonlocalrules=[]
      # The list of delegation needed to send after having processed the
      # wlprogram at initialization. Ie. the non-local part of rules usually
      # start with an intermediary relation that control it triggering.
      #
      # Array:(WLBud:WLRule)
      #
      @delegations = Hash.new{ |h,k| h[k]=Array.new }
      # This is the list of rules which contains the local rules after a
      # non-local rule of the wlprogram at initialization has been rewritten.
      # This kind of rule have a intermediary relation in their head that
      # control the corresponding delegated part of the rule on the remote
      # peer.
      # === data struct
      # Array:(WLBud:WLRule)
      #
      @rewrittenlocal=[]
      # Keep the new relation to declare on remote peer (typically intermediary
      # relation created when rewrite) due to processing of of a wlgrammar line
      # in rewrite_non_local.
      # === data struct
      # Hash:(peer address, Set:(string wlgrammar collection declaration) )
      #
      @new_relations_to_declare_on_remote_peer = Hash.new{|h,k| h[k]=Set.new }
      # The list of all the new delegations to be send due to processing of a
      # wlgrammar line in rewrite_non_local. It contains the non-local part of
      # the rule that have been splitted.
      # === data struct
      # Hash:(peer address, Set:(string wlgrammar rule) )
      #
      @new_delegations_to_send = Hash.new{|h,k| h[k]=Set.new }
      # The list of all the new local collection to create due to processing of
      # a wlgrammar line in rewrite_non_local. It contains the intermediary
      # relation declaration.
      # === data struct
      # Array:(string wlgrammar collection)
      #
      @new_local_declaration = []
      # The list of all the new local rule to create due to processing of a
      # wlgrammar line in rewrite_non_local. It contains the local part of the
      # rule that have been splitted.
      # === data struct
      # Array:(WLBud::WLRule)
      #
      @new_rewritten_local_rule_to_install = []
      #@name=@programfile.split('/').last.split('.').first
      options[:debug] ||= false
      @options=options.clone

      # Parse lines to be read
      parse_lines(IO.readlines(@programfile))
      # process non-local rules
      @nonlocalrules.each do |r|
        rewrite_non_local r
      end
    end

    
    public
    # REMOVE 
    #    def add_peer(peername,ip,port)
    #      @peername=peername
    #      address = "#{ip}:#{port}"
    #      @wlpeers[@peername]=address
    #    end

    # The print_content method prints the content of the relations
    # declarations, extensional facts and rules of the program to the screen.
    #
    def print_content
      puts "-----------------------RELATIONS------------------------"
      @wlcollections.each_value {|wl| wl.show}
      puts "\n\n------------------------FACTS---------------------------"
      @wlfacts.each {|wl| wl.show}
      puts "\n\n------------------------RULES---------------------------"
      @localrules.each {|wl| wl.show}
      puts "\n\n--------------------------------------------------------"
    end
    
    # Returns true if no rules are loaded for evaluation.
    def rules_empty? ; return @localrules.empty?; end

    # Returns true if no facts are loaded for evaluation.
    def facts_empty? ; return @wlfacts.empty?; end

    # Return true if no collection is loaded for evaluation.
    def collection_empty? ; return @wlcollections.empty?; end

    # Return true if the whole program to evaluate is empty
    def empty? ; return (rules_empty? and facts_empty? and collection_empty?) ; end
    
    def print_arg_tab(target,str)
      string=""
      target.each {|r| string << "#{r};\n"}
      puts "#{str} :{\n#{string}}"
    end
    
    # Line parsing function. Notice that ';' is a reserved keyword. look through
    # each atom of the body for variables.
    #
    # Thanks to this function everything until the parser meet a semi-colon will
    # be interpreted as if it was written on one line. This should allow to
    # write long rule on multiple-lines.
    #
    # ===parameter
    # * +lines+ is an array of string, each cell containing a line of the file.
    #   Usually lines is the result of IO.readlines.
    #
    def parse_lines (lines)
      current=""
      lines.each_index do |i|
        l=lines[i]
        current << l
        next unless l =~ /;/
        parse(current,true,false,{:line_nb=>i+1})
        current = "" #reset current line after parsing
      end
    end
    
    # Parses one line of WLcode and adds it to the proper WL collection if the
    # add_to_program boolean is true.
    #
    # TODO: should check before adding rule that the all the local atoms have
    # been declared. The atoms in the head that are not local should also be
    # declared but I can also make my parser declare them automatically since
    # the type is not important.
    #
    def parse (line,add_to_program=false,rewritten=false, options={})
      raise WLErrorTyping, "in parse the parameter must be a string representing a valid wlgrammar expression" unless line.is_a?(String)
      unless (output=@parser.parse(line))
        line_nb = options[:line_nb] ||= "unknown"
        raise WLErrorGrammarParsing, <<-MSG
          "\r\nFailure reason: #{@parser.failure_reason}\r\n
            line in the file:#{line_nb}\r\n
            line in the rule #{@parser.failure_line}\r\n
            column:#{@parser.failure_column}\r\n
            In the string: #{line}"
        MSG
      else
        result = output.elements.first
        if add_to_program
          case result
          when WLBud::WLPeerName then @wlpeers[result.name] = result.address
          when WLBud::WLCollection then @wlcollections[result.name] = result
          when WLBud::WLFact then @wlfacts << result
          when WLBud::WLRule
            if rewritten
              if result.nonlocal?(@peername)
                @delegations << result
              else
                @rewrittenlocal << result
              end
            else
              if result.nonlocal?(@peername)
                @nonlocalrules << result                
              else
                @localrules << result
              end
            end          
          end
        end
        return result
      end
    end

    # This method creates a body-local rule with destination peer p and a
    # non-local rule that should be delegated to p.
    #
    # === Remark
    # The intermediary relation created to link the delegated rule with the
    # rewritten local is automatically added
    #
    # ===return [do not use prefer the instance variable @new_local_declaration]
    # +intermediary_relation_declaration_for_local_peer+ if it exists that is
    # when splitting the rule has been necessary. That is the relation
    # declaration that should be created into bud to store intermediary local
    # results of non-local rules rewritten
    #
    def rewrite_non_local(rule)
      raise WLError, "\npeername is not defined yet." if @peername.nil?  
      intermediary_relation_declaration_for_local_peer = nil
      localstack=[]; nonlocalstack=[]; destination_peer="" ; local_vars=[]
      to_delegate=false

      # Scan atoms and divide body in local and non-local
      rule.body.each { |atom|
        if atom.local?(@peername) and !to_delegate
          localstack << atom
        else
          to_delegate=true
          nonlocalstack << atom
        end
      }
      raise WLError, <<-MSG if nonlocalstack.empty?
      ERROR in rewrite : You are trying to rewrite a local rule. There may be an error in your rule filter
        MSG
        #The destination peer is the peer of the first nonlocal atom.
        destination_peer = nonlocalstack.first.rpeer.text_value
        addr_destination_peer = @wlpeers[destination_peer]
      
        # RULE REWRITING If local atoms are present at the beginning of the non
        # local rule, then we have to add a local rule to the program. Otherwise,
        # the nonlocal rule can be sent as is to its destination. Create a
        # relation for this declaration and that has an arity corresponding to the
        # number of distinct variables present in the stack.
        #
        if localstack.empty? or !(localstack.empty? or nonlocalstack.empty?)
          if !(localstack.empty? or nonlocalstack.empty?) # if the rule must be cut in two part
            localbody = "" ;
            localstack.each do |atom|
              atom.variables.flatten.each { |var|
                local_vars << var unless var.nil? or local_vars.include?(var)
              }
              localbody << "#{atom},"
            end
            localbody.slice!(-1)
            tmp_name=generate_intermediary_relation_name
            relation_name="#{tmp_name}"
            # build the list of attributes for relation declaration (dec_fields)
            # removing the '$' of variable and create attributes names
            dec_fields=''
            var_fields=''
            local_vars.each_index do |index|
              local_var=local_vars[index]
              dec_fields << local_var.gsub( /(^\$)(.*)/ , tmp_name+"_\\2_"+index.to_s+"\*," )
              var_fields << local_var << ","
            end ; dec_fields.slice!(-1);var_fields.slice!(-1);
            intermediary_relation_atom_in_rule = "#{relation_name}@#{destination_peer}(#{var_fields})"
            intermediary_relation_declaration_for_remote_peer = "collection inter persistent #{relation_name}@#{destination_peer}(#{dec_fields});"
            intermediary_relation_declaration_for_local_peer = intermediary_relation_declaration_for_remote_peer.gsub("persistent ", "")
            local_rule_which_delegate_facts = "rule #{intermediary_relation_atom_in_rule}:-#{localbody};"
            #Declare the new remote relation as a scratch for the local peer and add it to the program
            @new_local_declaration << parse(intermediary_relation_declaration_for_local_peer,true,true)
            @new_relations_to_declare_on_remote_peer[addr_destination_peer] << intermediary_relation_declaration_for_remote_peer
            #Add local rule to the set of rewritten local rules
            @new_rewritten_local_rule_to_install << parse(local_rule_which_delegate_facts, true, true)
            #Create the delegation rule string
            nonlocalbody="" ;
            nonlocalstack.each { |atom| nonlocalbody << "#{atom}," } ; nonlocalbody.slice!(-1)
            delegation="rule #{rule.head}:-#{intermediary_relation_atom_in_rule},#{nonlocalbody};"
          elsif localstack.empty? # else if the whole body is non-local, no rewriting are needed just delegate all the rule
            delegation="#{rule};"
          end
          @new_delegations_to_send[addr_destination_peer] << delegation
        elsif nonlocalstack.empty?
          raise WLErrorProgram, "\nLocal rule found in nonlocal rule table. There may have been an error in previous processing"
        else # the last case where only the head is non-local and the body is only local, we can install it as it is
          @new_rewritten_local_rule_to_install << rule
        end
        return intermediary_relation_declaration_for_local_peer
      end
    
      # Generates the string representing the rule in the Bud format from a
      # WLrule.
      #
      def translate_rule_str(wlrule)
        unless wlrule.is_a?(WLBud::WLRule)
          raise WLErrorTyping,
            "wlrule should be of type WLBud::WLRule, not #{wlrule.class}"
        end
        unless (head_atom_peer_name = wlrule.head.rpeer.text_value)
          raise WLErrorGrammarParsing,
            "In this rule: #{wlrule.show}\n Problem: the name of the peer in the relation in the head cannot be extracted. Relation in the head #{wlrule.head.text_value}"
        end
        if @wlpeers[head_atom_peer_name].nil?
          raise WLErrorPeerId,
            "This peer name: #{head_atom_peer_name} cannot be found in the list of known peer: #{@wlpeers.inspect}"
        end
        str_res=''
        str_self_join=''
        body = wlrule.body

        #Generate rule head
        #Send fact buffer if non-local head
        unless wlrule.head.local?(@peername)
          str_res << "sbuffer <= "
        else if is_tmp?(wlrule.head)
            str_res << "temp :#{wlrule.head.name} <= "
          else
            str_res << "#{wlrule.head.name} <= "
          end
        end

        #Obsolete code when self-joins where badly implemented
        #rename_atoms adds temp relations in case of self joins.
        #renamed = rename_atoms(body)
        #renamed.each {|relation| strRes <<  "#{relation};\n"} unless @make_binary_rules

        #Make the locations dictionaries for this rule
        wlrule.make_dictionaries unless wlrule.dic_made

        #      if @options[:debug] then
        #        WLTools::Debug_messages.h4("Display dictionaries generated for rule \n\t#{wlrule.to_s}\n")
        #        puts <<-END
        #          dic_wlvar - #{wlrule.dic_wlvar.inspect}
        #          dic_wlconst - #{wlrule.dic_wlconst.inspect}
        #          dic_relation_name - #{wlrule.dic_relation_name.inspect}
        #          dic_invert_relation_name - #{wlrule.dic_invert_relation_name.inspect}
        #        END
        #      end
      
        if body.length==0
          str_res << " ["
          str_res << def_projection(wlrule)
          str_res << "];"
        else
          if body.length==1
            str_res << body.first.name
          else
            #Generate rule collection names using pairs and combos keywords.
            #          if @make_binary_rules
            #            s , str_self_join = make_pairs(wlrule)
            #          else
            s , str_self_join = make_combos(wlrule)
            #          end
            str_res << s
          end
          str_res << " {|";
          wlrule.dic_invert_relation_name.keys.sort.each {|v| str_res << "#{WLProgram.get_bud_var_by_pos(v)}, "}
          str_res.slice!(-2..-1) #remove last and before last
          str_res << "| "
          str_res << def_projection(wlrule)
          wlrule.dic_wlconst.each do |key,value|
            value.each do |v|
              relation_position , attribute_position = v.first.split('.')
              if wlrule.dic_wlconst.keys.first==key
                str_res << " if "
              else
                str_res << " && "
              end
              str_res << "#{wlrule.dic_relation_name[relation_position]}.#{attribute_position}==#{quotes(key)}"
            end
          end
          unless wlrule.dic_wlconst.empty?
            str_res << str_self_join.sub(/&&/,'if')
          else
            str_res << str_self_join
          end
          str_res << "};"
        end
      end

      # Read the content and erase. It return the hash of the collection to create
      # and clear it after.
      #
      # == return
      #
      # a hash with
      # * +key+  peerIp:port
      # * +value+ array with the relation as strings in wlpg format
      #
      def flush_new_relations_to_declare_on_remote_peer
        unless @new_relations_to_declare_on_remote_peer.empty?
          flush = @new_relations_to_declare_on_remote_peer.dup
          flush.each_pair { |k,v| flush[k]=v.to_a }
          @new_relations_to_declare_on_remote_peer.clear
        else
          flush={}
        end
        return flush
      end
    
      # Read the content and erase. It return the hash of the delegation to send
      # and clear it after.
      #
      #  == return
      #
      # a hash with
      # * +key+  peerIp:port
      # * +value+ array with the relation as strings in wlpg format
      #
      def flush_new_delegations_to_send
        unless @new_delegations_to_send.empty?
          flush = @new_delegations_to_send.dup
          flush.each_pair { |k,v| flush[k]=v.to_a }
          @new_delegations_to_send.clear
        else
          flush={}
        end
        return flush
      end

      # Read new_local_declaration content and clear it. It return
      # the array of the collections to create and clear it after.
      #
      # == return
      #
      # an array of wlgrammar collections
      #
      def flush_new_local_declaration
        unless @new_local_declaration.empty?
          flush = @new_local_declaration.dup
          @new_local_declaration.clear
        else
          flush=[]
        end
        return flush
      end

      # Read new_rewritten_local_rule_to_install content and clear it. It return
      # the array of the rules to create and clear it after.
      #
      # == return
      #
      # an array of wlgrammar rules
      #
      def flush_new_rewritten_local_rule_to_install
        unless @new_rewritten_local_rule_to_install.empty?
          flush = @new_rewritten_local_rule_to_install.dup
          @new_rewritten_local_rule_to_install.clear
        else
          flush=[]
        end
        return flush
      end

      private

      # Define the format of the name of the variable for the name of the
      # relation inside the block of the bud rules
      def self.get_bud_var_by_pos(position)
        "atom#{position}"
      end

      # According to the variable found in the head of the rule this method
      # define the schema of tuples to produce from the variable appearing in the
      # body.
      #
      # For a bud rule like the following it produce the part between stars
      # marked with ** around
      #
      # {descendant_at_emilien <= child_at_emilien {|atom0| *[atom0[0],
      # atom0[2]]*}
      def def_projection(wlrule)
        str = ''
        str << '['
        # add location of the peer which should receive the fact and relation and
        # the relation in which the fact should be added on the remote peer.
        unless wlrule.head.local?(@peername)
          destination = "#{@wlpeers[wlrule.head.rpeer.text_value]}"
          #add location specifier
          raise WLErrorPeerId, "impossible to define the peer that should receive a message" if destination.nil? or destination.empty?
          str << "\"#{destination}\", "
          relation = "#{wlrule.head.name}"
          raise WLErrorProgram, "impossible to define the relation that should receive a message" if destination.nil? or destination.empty?
          str << "\"#{relation}\", "
          str << "["
        end
        # add the list of variable and constant that should be projected
        wlrule.head.fields.each_with_index do |f,i|
          # treat as a constant or a variable
          unless f.include?('$')  #for constant
            str << "#{quotes(f)}, "
          else
            unless wlrule.dic_wlvar.include?(f)
              raise( WLErrorGrammarParsing,
                "\nIn rule "+wlrule.text_value+" #{f} is present in the head but not in the body. This is not WebdamLog syntax." )
            else
              relation , attribute = wlrule.dic_wlvar.fetch(f).first.split('.')
              str << "#{WLBud::WLProgram.get_bud_var_by_pos(relation)}[#{attribute}], "
            end
          end
        end
        str.slice!(-2..-1)
        str << ']'
        unless wlrule.head.local?(@peername)
          str << "]"
        end
        return str
      end
    
=begin    
    # Generates a string corresponding to the appropriate delegation.
    # Ensure that the delegation string is created according to the specifications.    # 
    #
    def generate_delegation(delegation) 
      ######## MANAGE DELEGATIONS ########
      # Pushes each atom of the body of the rule (left to right) into a stack until it finds a non local one.
      # Take all the previous atoms and puts them into a temporary variable. 
      # From : out@j($x,$y,$z):-f@j(alice,$x), f@e(alice,$y), f@a(alice,$z)
      # Get to : 
      # collection tmp_from_j@e($x)
      # rule tmp_from_j@e($x):-f@j(alice,$x)
      #
      stack=[]; destination_peer="" ; fields="" ; local_vars=[] ; body = ""
      delegation.body.each_with_index { |atom,n|
        if atom.local?(@WLinstance)
          stack << atom
        else
          destination_peer = atom.rpeer.text_value
          break
        end
      }
      # RULE REWRITING
      # create a relation for this declaration that is persistent and that has 
      # an arity corresponding to the number of unique variables present in the stack.      
      stack.each { |atom|
        atom.variables.flatten.each {|var|
          unless var.nil? or local_vars.include?(var)
            local_vars << var
          end
        }
        body << "#{atom}*,"
      } ; body.slice!(-1)
      collection_name="deleg_#{generate_intermediary_relation_name}_at_#{destination_peer}"
      local_vars.each { |variable| fields << "#{variable},"} ; fields.slice!(-1)
      collection = "#{collection_name}@#{destination_peer}(#{fields})"
      rule = "rule #{collection}:-#{body};"
      declaration="collection #{collection};"
      puts "Delegation WL:{\n#{rule}\n#{collection}\n}"
      
      # RULE TRANSLATION
      bud_rule_str=translate_rule_str(add_rule(rule,true)) # Creates a string corresponding to the bud equivalent rule
      # add_collection(declaration)
      collection_meta=""
      
      # RULE SENDING
      facts="{['#{collection_name}']=>[#{collection_name} {|s| s}]}"
      destination_delegation="[]"
      io = "sbuffer <= [['#{@wlpeers[destination_peer]}',[#{collection_meta},[#{facts},#{destination_delegation}]]]];"
      str = "{\n#{bud_rule_str}\n#{io}\n}"
      puts "Delegation Bud : #{str}"
      proc = eval("Proc.new#{str}")
      name = "__bloom__#{@name}_rule#{wlrule.index}".to_sym
      @WLinstance.rule_init([name,proc])
    end
=end

      # DEPRECATED
      #
      def make_binary (wlrule)
        # #r($a,$e,d):-r1($a,$b,coco),r2($b,$c,toto),r3($b,$c,titi)
        # #tmp($a,$e,d,$b):-:-r1($a,$b,coco),r2($b,$c,toto)
        # #r($a,$e,d):-tmp($a,$e,d,$b),r3($b,$c,titi)
        #
        # #create first temporary relation and transform the rule
        # #make_dictionnaries(wlrule) unless wlrule.made_dictionnaries
        rewritten_rules=[];head_str='';body_str=''
        wlbody = wlrule.body
        prev_atom_var=wlbody.first.variables[2]
        join = wlbody.first.text_value
        wlbody.each_with_index {|atom,i|
          unless i==0 #do not do anything with the first atom

            # head rewriting
            if wlbody.last.eql?(atom)
              head_str<<wlrule.head.text_value
            else
              head_str<<"#{generate_intermediary_relation_name}@me("
              var_in_hd=[]
              atom.variables[2].each {|var| (head_str << "#{var}," ; var_in_hd << var) unless var_in_hd.include?(var)}
              prev_atom_var.each {|var| (head_str << "#{var}," ; var_in_hd << var) unless var_in_hd.include?(var)}
              prev_atom_var=var_in_hd
              head_str.slice!(-1)
              head_str << ')'
            end

            # body rewriting
            body_str << "#{join},#{atom.text_value}"
            rewritten_rules << "{#{head_str}:-#{body_str}};"
            join=head_str
            head_str=''
            body_str=''
          end
        }
        puts rewritten_rules.inspect
        return rewritten_rules
      end
    
    
      # Update nonlocal updates the head_nonlocal. Has to be called each time
      # program collection changes (new rules or new peers added to the program).
      #
      #    def update_body_local
      #      @localrules.each_with_index { |wlrule,n|
      #        hd = wlrule.head
      #        peer = hd.rpeer.text_value
      #        relation = hd.rrelation.text_value
      #        raise WLError, "\nUnknown peer name '#{peer}'for head atom of rule\##{n}." unless @wlpeers.include?(peer)
      #        raise WLError, "\nHead non local not full" unless @facts_for_peer.include?(peer)
      #        @facts_for_peer[peer] << relation unless @facts_for_peer[peer].include?(relation)
      #      }
      #      @delegations.each { |delegation|
      #
      #      }
      #      #@facts_for_peer.each {|k,v| puts "#{k} => #{v.inspect}"}
      #    end

      def make_pairs (wlrule)
        str = "(#{wlrule.body.first.name} * #{wlrule.body.last.rrelation.text_value}).pairs(" ;
        pairs=false
        wlrule.dic_wlvar.each { |key,value| next unless value.length > 1
          rel_first , attr_first =value.first.split('.')
          rel_other , attr_other =value.last.split('.')
          if wlrule.has_self_join
            str << ":#{attr_first}" << ' => ' << ":#{attr_other}" << ',' ;
          else
            str << "#{rel_first}.#{attr_first}" << ' => ' << "#{rel_other}.#{attr_other}" << ',' ;
          end
          pairs=true
        }
        str.slice!(-1) if pairs
        str << ')'
        return str , ''
      end

      # This code manages renaming in case of self joins
      #
      # === DEPRECATED ====
      # Renaming for self join must be rewrote from scratch
      #
      def rename_atoms (input)
        tmp_rels=[];rels=[]
        if input.is_a?(WLBud::WLRule)
          wlrule = input
          wlrule.body.each_with_index {|atom,n|
            #Creates temp collections when self-joins are present
            if !rels.include?(atom.name) then rels << atom.name
            else #we have a self join situation. Create a temporary relation and rename the relation
              atom.name(generate_intermediary_relation_name)
              tmp_r = "temp :#{atom.name} <= #{"#{atom.rrelation.text_value}_at_#{atom.rpeer.text_value}"}"
              tmp_rels << tmp_r
              wlrule.has_self_join=true
            end
          }
        else
          body = input
          body.each_with_index {|atom,n|
            #Creates temp collections when selfjoins are present
            if !rels.include?(atom.name) then rels << atom.name
            else #we have a self join situation. Create a temporary relation and rename the relation
              atom.name(generate_intermediary_relation_name)
              tmp_r = "temp :#{atom.name} <= #{"#{atom.rrelation.text_value}_at_#{atom.rpeer.text_value}"}"
              tmp_rels << tmp_r
            end
          }
        end
        return tmp_rels
      end

      # If the name of the atom start with tmp_ or temp_ it is a temporary
      # relation so return true.
      def is_tmp? (result)
        if result.is_a?(WLBud::WLAtom)
          if result.name=~/temp_/ or result.name=~/tmp_/ then return true else return false end
        else
          raise WLErrorGrammarParsing, "is_tmp? is called on non-WLAtom object, of class #{result.class}"
        end
      end

      # FIXME error in the head of the rules aren't detcted during parsing but
      # here it is too late.
      #
      # Make joins when there is more than two atoms in the
      # body. Need to call make_dic before calling this function. it return the
      # beginning of the body of the bud rule containing the join of relations
      # along with their join tuple criterion for example (rel1 *
      # rel2).combos(rel1.1 => rel2.2) TODO move to wlvocabulary
      #
      # For a bud rule like the following it produce the part between stars marked
      # with ** around
      #
      # sibling <= *(childOf*childOf).pairs(:father => :father,:mother =>
      # :mother)* {|s1,s2| [s1[0],s2[0]] unless s1==s2}
      def make_combos (wlrule)
        raise WLError, "The dictionary should have been created before calling this method" unless wlrule.dic_made
        str = '('; if_str = '' ;
        wlrule.body.each do |atom|
          unless atom==wlrule.body.last then str <<  "#{atom.name} * "
          else str << "#{atom.name}" end
        end
        str << ').combos('
        combos=false
        wlrule.dic_wlvar.each do |key,value|
          next unless value.length > 1 #skip anonymous variable (that is occurring only once in the body)
          value.each do |v|
            v1 = value.first
            #join every first occurrence of a variable with its subsequent
            rel_first , attr_first = v1.first.split('.')
            unless v1.eql?(v)
              rel_other , attr_other = v.first.split('.')
              # If it is a self-join symbolic name should be used
              rel_first_name = wlrule.dic_invert_relation_name[rel_first]
              rel_other_name = wlrule.dic_invert_relation_name[rel_other]
              unless rel_first_name.eql?(rel_other_name)
                str << WLProgram.get_bud_var_by_pos(rel_first) << attr_first << ' => ' << WLProgram.get_bud_var_by_pos(rel_other) << attr_other << ',' ;
                combos=true
              else
                #if_str << " && #{wlrule.dic_relation_name[rel_first]}.#{attr_first}==#{wlrule.dic_budvar[rel_other]}.#{attr_other}"
                first_atom = wlrule.body[Integer(rel_first)]
                other_atom = wlrule.body[Integer(rel_other)]
                col_name_first = get_column_name_of_relation(first_atom, Integer(attr_first))
                col_name_other = get_column_name_of_relation(other_atom, Integer(attr_other))
                str << ":#{col_name_first}" << ' => ' << ":#{col_name_other}" << ',' ;
                combos=true
              end
            end
          end
        end
        str.slice!(-1) if combos
        str << ')'
        return str, if_str
      end

      # Get the the name specified for the column of the relation in given atom as
      # it is declared in the collection
      def get_column_name_of_relation (atom, column_number)
        ~      @wlcollections["#{atom.rrelation.text_value}_at_#{atom.rpeer.text_value}"].fields.fetch(column_number)
      end

      # Add quotes around s if it is a string
      #
      def quotes(s)
        if s.is_a?(String)
          return "\'#{s}\'"
        else
          return s.to_s
        end
      end

      # Tools for WLprogram This tool function checks if a table includes an
      # object. If so, it will return its index. Otherwise it will raise a
      # WLParsing Error.
      def include_with_index (table,obj)
        raise WLBud::WLErrorGrammarParsing, "#{obj} is a lone variable" unless table.include?(obj)
        table.each_with_index {|a,i| if obj.eql?(a) then return i else next end}
      end
    
      # Generates a temporary name that is guaranteed to be unique. This one is
      # based in the fact that peername are unique and always have one uniq
      # program
      # TODO: add more stuff in the name to guarantee uniqueness
      #
      def generate_intermediary_relation_name()
        return "deleg_#{@next+=1}_from_#{@peername}"
      end
    end
  end

