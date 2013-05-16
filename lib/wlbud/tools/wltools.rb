# To change this template, choose Tools | Templates
# and open the template in the editor.

module WLTools

  # Sanitize the string ie.
  # + Remove leading and trailing whitespace
  # + Downcase
  # + Replace internal space by _
  # + Remove " or '
  #
  def self.sanitize(string)
    str = string.strip.downcase
    ['"', "'", "."].each do |c|
      str.delete!(c)
    end
    return str.gsub(/\s+/, '_')
  end

  # Sanitize the string ie.
  # + Remove leading and trailing whitespace
  # + Downcase
  # + Replace internal space by _
  # + Remove " or '
  #
  def self.sanitize!(string)
    string.strip!
    string.downcase!
    ['"', "'", "."].each do |c|
      string.delete!(c)
    end
    string.gsub!(/\s+/, '_')
    return string
  end

  # Transform *filename* into a nice *NIX filename
  #
  # This regex will match all characters other than basic letters and digits:
  # s/[^\w\s_-]+//g
  #
  # This will remove any extra whitespace in between words
  # s/(^|\b\s)\s+($|\s?\b)/\\1\\2/g
  #
  # And lastly, replace the remaining spaces with underscores:
  # s/\s+/_/g
  #
  def self.friendly_filename(filename)
    filename.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')
  end

  # The classic group by method that group a list of array by the field in
  # position key_pos.
  #
  # Return a hash built from an array of array with key_pos fields of each
  # array element as key of the hash and merge all the equals values
  # constituted of all other fields of array elements into an array. Example:
  # a = [["one", "value11"], ["one", "value12"], ["two", "value21"], ["two",
  # "value22"]]
  #
  # return !{"one" => [["value11"], ["value12"]], "two" => [["value21"], ["value22"]]}
  #
  # NB: un-nest the array in value if size is one after key extraction
  #
  def self.merge_multivaluehash_grouped_by_field(ar_ar,key_pos)
    grouped = {}
    ar_ar.each do |arr|
      l_arr = arr.dup
      key = l_arr.delete_at(key_pos)
      if l_arr.length == 1
        (grouped[key] ||= []) << l_arr.first
      else
        (grouped[key] ||= []) << l_arr
      end
    end
    grouped
  end

  module SerializeObjState
    # ===return
    # a hash with variable name as key with their value as hash value
    #
    # ===option
    # change the key_type for something else than "string" which is set by
    # default to get symbol instead of string as key of the returned hash
    #
    def self.obj_to_hash (obj, key_type="string")
      if key_type=="string"
        Hash[obj.instance_variables.map {|var| [var[1..-1].to_s, obj.instance_variable_get(var)]}]
      else
        Hash[obj.instance_variables.map {|var| [var[1..-1].to_sym, obj.instance_variable_get(var)]}]
      end
    end
  end  

  module Print_Tables
    
    def self.print_arg_tab(target,prefix)
      string=""
      target.each {|r| string << "#{r}\n"}
      puts "#{prefix} :{\n#{string}}"
    end

    # format Distrib messages with timestamp on the right of the screen
    # print_table[0] = ip_port : not used.
    # print_table[1] = source of the message
    # print_table[2] = source bud time
    # print_table[3] = data content.
    #.map{|t| [t.inspect]}
    def self.pretty_print(print_table)
      s =""
      s1 = print_table[0].to_s  + "\t"                              #Source location
      s2 = print_table[1].to_s  + "\t"                              #Key of message (only for non-local)
      s3 = print_table[2].to_s + "\t"                               #relation name
      if print_table[3]!=nil
        s4 = print_table[3].inspect + "\t"                          #Data content
      else
        s4 = "nil\t"                                                  #Data content
      end
      s5 = print_table[4].to_s + "\t"                               #Source bud time
      s += s1 + "\t" + s2 + "\t" + s3 + "\t\t" + s4 + "\t\t" + s5 + "\n"
      return s
    end
  
    #Pretty print with id
    def self.p_print_id(print_table)
      s =""
      if print_table[3]!=nil
        s1 = print_table[0].to_s  + "\t"                              #Source location
        s2 = print_table[1].to_s  + "\t"                              #Key of message (only for non-local)
        s3 = print_table[2].to_s + "\t"                               #relation name
        s4 = print_table[3].inspect + "\t"                            #Data content
        s5 = print_table[4].to_s + "\t"                               #Source bud time
        s6 = budtime.to_s                                             #Local bud time
        s += s1 + "\t" + s2 + "\t" + s3 + "\t\t" + s4 + "\t\t" + s5 + "\t\t" + s6 + "\n"
      else
        s1 = print_table[0].to_s  + "\t"                              #Source location
        s2 = print_table[1].to_s  + "\t"                              #Key of message (only for non-local)
        s3 = print_table[2].to_s + "\t"                                    #relation name
        s4 = "nil\t"                                                  #Data content
        s5 = print_table[4].to_s + "\t"                               #Source bud time
        s6 = budtime.to_s                                             #Local bud time
        s += s1 + "\t" + s2 + "\t\t"+ s3 + "\t\t" + s4 + "\t\t" + s5 + "\t\t" + s6 + "\n"
      end
      return s
    end
  end

  module Debug_messages

    public

    # Insert level one title
    # Return the string formated with the corresponding modifier
    # "b", "begin", "B", "Begin", "BEGIN" for a begin comment output
    # "e", "end", "E", "End", "END" for a end comment output
    def self.h1(string, modifier=nil)
      puts <<-END
\n---------------------------------------------------
---------------------------------------------------
---------------------------------------------------
- #{format_with_modifier(string, modifier)} -
---------------------------------------------------
---------------------------------------------------
---------------------------------------------------\n
      END
    end
    # Insert level two title
    # Return the string formated with the corresponding modifier
    # "b", "begin", "B", "Begin", "BEGIN" for a begin comment output
    # "e", "end", "E", "End", "END" for a end comment output
    def self.h2(string, modifier=nil)
      puts <<-END
\n---------------------------------------------------
---------------------------------------------------
- - #{format_with_modifier(string, modifier)} - -
---------------------------------------------------
---------------------------------------------------\n
      END
    end
    # Insert level three title
    # Return the string formated with the corresponding modifier
    # "b", "begin", "B", "Begin", "BEGIN" for a begin comment output
    # "e", "end", "E", "End", "END" for a end comment output
    def self.h3(string, modifier=nil)
      puts <<-END
\n---------------------------------------------------
- - - #{format_with_modifier(string, modifier)} - - -
---------------------------------------------------\n
      END
    end
    # Insert level four title
    # Return the string formated with the corresponding modifier
    # "b", "begin", "B", "Begin", "BEGIN" for a begin comment output
    # "e", "end", "E", "End", "END" for a end comment output
    def self.h4(string, modifier=nil)
      puts "\n - - - - #{format_with_modifier(string, modifier)} - - - -\n"
    end

    private

    # Insert a begin prefix to comment for mark of something to enclose with an
    # end
    def self.begin_comment(string)
      "BEGIN>>>>#{string}>>>>"
    end
    # Insert a end prefix to comment for mark of something to enclose with a
    # begin
    def self.end_comment(string)
      "<<<<#{string}<<<<END"
    end
    # Return the string formated with the corresponding modifier
    # "b", "begin", "B", "Begin", "BEGIN" for a begin comment output
    # "e", "end", "E", "End", "END" for a end comment output
    def self.format_with_modifier(string, modifier)
      case modifier
      when "b", "begin", "B", "Begin", "BEGIN"
        begin_comment(string)
      when "e", "end", "E", "End", "END"
        end_comment(string)
      else
        string
      end
    end
  end
end

# From http://www.lesismore.co.za/rubyenums.html
#
module Kernel
  # simple (sequential) enumerated values
  # enum Java style
  #
  def enum(*syms)
    syms.each { |s| const_set(s, s.to_s) }
    const_set(:DEFAULT, syms.first) unless syms.nil?
  end
end

