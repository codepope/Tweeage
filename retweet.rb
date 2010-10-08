class Retweet < Action
  
  def action_name
    "retweet"
  end
  
  def action_label
    "RT"
  end
  
  def do_action(tweet)
    client = Twitter::Base.new($oauth)
    client.retweet(tweet.id)
    @done=true
  end
end
