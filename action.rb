class Action
  
  @done=false
  
  def action_name
    "action"
  end
  
  def action_label
    "Action"
  end
  
  def is_done?
    done
  end
  
  def do_action(tweet)
    puts "Doing #{action_name} with #{tweet.id} but not Done"
  end

end

    