class Hash

  # Take keys of hash and transform those to a symbols.
  def self.transform_keys_to_symbols(value, depth=0)
    if not value.is_a?(Hash) or depth == 0
      return value
    end
    hash = value.inject({}) do |memo,(k,v)|
      memo[k.to_sym] = Hash.transform_keys_to_symbols(v, depth-1);
      memo
    end
    return hash
  end
  
  # List the difference between self and other
  # @return [Hash] a hash listing differences between two hash
  def deep_diff(other)
    (self.keys + other.keys).uniq.inject({}) do |memo, key|
      if self[key] != other[key]
        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
          memo[key] = self[key].deep_diff(other[key])
        else
          memo[key] = [self[key], other[key]]        
        end
      end
      memo
    end
  end
  
  # List the difference between self and other
  # 
  # @return [Array] two hashes the first list the different value in other
  # collection the second list the deleted value from self collection
  def deep_diff_split(other)
    right = Hash.new{ |h,k| h[k]=Array.new }
    left = Hash.new{ |h,k| h[k]=Array.new }
    (self.keys + other.keys).uniq.each do |key|
      if self[key] != other[key]
        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
          left[key], right[key] = self[key].deep_diff_split(other[key])
        else          
          left[key] << self[key] unless self[key].nil?
          right[key] << other[key] unless other[key].nil?
        end
      end
    end
    return left, right
  end
  
  # List the difference between self and other
  # @return [Hash] a hash listing differences between two hash
  def deep_diff_split_lookup(other) 
    right = Hash.new{ |h,k| h[k]=Array.new }
    left = Hash.new{ |h,k| h[k]=Array.new }
    lookup_table = DeepClone.clone self
    # check each relations for each peers
    (self.keys + other.keys).uniq.each do |key|
      if self[key] != other[key]
        if self[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)  
          right = {}
          left = {}
          left[key], right[key] = self[key].deep_diff_split_lookup(other[key])
        elsif self[key].kind_of?(Set) &&  other[key].kind_of?(Array)          
          # lookup facts
          other[key].each do |fact|
            if lookup_table[key].include?(fact)
              lookup_table[key].delete(fact)
            else
              right[key] << fact unless fact.nil?
            end
          end
          left[key] = lookup_table[key] unless lookup_table[key].empty?
        elsif self[key].nil?
          right[key] << other[key]
        elsif other[key].nil?
          left[key] << lookup_table[key]
        else
          raise StandardError, "unexpected type of data to compared in deep_diff_split_lookup"
        end
      end
      left.delete(key) if left[key].empty?
      right.delete(key) if right[key].empty?
    end
    return left, right
  end
    
  def transform_inner_array_into_set
    res = {}
    self.each_pair do |key,value|
      if value.kind_of? Hash
        res[key] = transform_inner_array_into_set value
      elsif value.kind_of?(Enumerable)
        res[key] = value.to_set
      else
        res[key]= value
      end
    end
    res
  end
end