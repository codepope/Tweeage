# Action will encapsulate a Tweet
# It will include call on rules to decide if a tweet is actionable or not
# It will retain a list of actions that could be taken on a tweet

class Actionable
  
  attr_accessor :tweet
  attr_accessor :action

  def do_action
    puts "I, I who do nothing"
  end 

end

  
  