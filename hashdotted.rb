#
# Mix in for Hash to get dotted names for props
#

class Hash
  
  def each_dotted_name
    self.each { | x,v| 
                if v.is_a? Hash
                  v.each_dotted_name_prefixed(x) { |y| yield y }
                else
                  yield x
                end
              }
  end
  
  def each_dotted_name_prefixed(prefix)
    self.each { | x,v| 
                if v.is_a? Hash
                  v.each_dotted_name_prefixed("#{prefix}.#{x}") { |y| yield y }
                else
                  yield "#{prefix}.#{x}"
                end
              }
  end
    
  def dotted_value(dotted_name)
    parts=dotted_name.split('.')
    v=self.fetch(parts[0])
    case parts.length
    when 1
      return v
    when 2
      return v.fetch(parts[1])
    when 3
      return v.fetch(parts[1]).fetch(parts[2])
    end
  end
end