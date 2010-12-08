#!/usr/bin/ruby

require 'rubygems'
require "sinatra"
require 'twitter'
require 'oauth'
require 'erb'
require "twitter-text"
include Twitter::Autolink
require "./actionable"
require "./action"
require "./retweet"


configure do  
  Thread.abort_on_exception=true
  $oauth=nil
  $msg_queue=Queue.new
  $incoming_array=Array.new
  $action_array=Array.new
  
  oauth_keys={}
  oauth_consumer={}
  
  # First, lets get the app keys... you'll want to register with Twitter for these
  # until I obfuscate and add them
  #
  if FileTest::exists?('oauth_consumer.txt')
    File.open('oauth_consumer.txt') do |file|
      oauth_consumer=Marshal.load(file)
    end
  else
    puts "Missing API secret and key"
    puts "Enter secret:"
    oauth_consumer["consumer_secret"]=STDIN.readline.chomp
    puts "And now the key:"
    oauth_consumer["consumer_key"]=STDIN.readline.chomp
    
  	File.open('oauth_consumer.txt','w') do |file|
  		Marshal.dump(oauth_consumer,file)
  	end
  end
  
  # Ok, now we can get the user access keys
  #
  if FileTest::exists?('oauth_keys.txt')
  	File.open('oauth_keys.txt') do |file|
  		oauth_keys=Marshal.load(file)
  	end
  else

  	consumer = OAuth::Consumer.new(
  	  oauth_consumer["consumer_key"], 
  	  oauth_consumer["consumer_secret"], 
  	  {:site => 'http://twitter.com'}
  	)
 
  	request_token = consumer.get_request_token 
 
  	puts "Twitter App Authorize URL \n" + request_token.authorize_url
  	puts "Enter PIN:"
  	pin = STDIN.readline.chomp
 
  	access_token = request_token.get_access_token(:oauth_verifier => pin)
 
  	oauth_keys["access_token"]=access_token.token
  	oauth_keys["access_secret"]=access_token.secret

  	File.open('oauth_keys.txt','w') do |file|
  		Marshal.dump(oauth_keys,file)
  	end
  end

  Twitter.configure do |config|
    config.consumer_key = oauth_consumer["consumer_key"]
    config.consumer_secret = oauth_consumer["consumer_secret"]
    config.oauth_token = oauth_keys["access_token"]
    config.oauth_token_secret = oauth_keys["access_secret"]
  end
  
  producer=Thread.new do 
    client = Twitter::Client.new
    since_id=0
    loop do
      j=0
      if(since_id==0)
        tweets=client.home_timeline
      else
        tweets=client.home_timeline(:since_id=>since_id)
      end
      
      tweets.reverse_each do |tweet| 
        $msg_queue << tweet
        since_id=tweet.id if(tweet.id>since_id)
        j=j+1
      end
      puts "Added #{j}"
      sleep(30)
    end
  end
  
  consumer=Thread.new do
    loop do
      if $msg_queue.empty?
        sleep(1)
      else
        tweet=$msg_queue.pop
        # Hardwired rule here for now... This is where the rule system would apply
        if tweet.user.screen_name=='honlinenews' || tweet.user.screen_name=='Codepope'
          actionable=Actionable.new
          actionable.tweet=tweet
          actionable.action=Retweet.new
          $action_array << actionable
        else  
          $incoming_array << tweet
        end
      end
    end
  end
end

get '/' do
  erb :actionable
end

get '/drop/:tweet_id' do
  tweet_id=params[:tweet_id].to_i
   rslt=$action_array.select{ |action| action.tweet.id == tweet_id }
   $action_array.delete(rslt[0])
   redirect '/'
end

get '/ignore/:tweet_id' do
  tweet_id=params[:tweet_id].to_i
  $incoming_array.delete_if { |tweet| tweet.id == tweet_id }
  redirect '/'
end

get '/view/:tweet_id' do
  tweet_id=params[:tweet_id].to_i
  rslt=$incoming_array.select{ |tweet| tweet.id == tweet_id }
  rslt[0].inspect
end

get '/flush' do
  $incoming_array=[]
  redirect '/'
end

get '/actionable/:tweet_id' do
  tweet_id=params[:tweet_id].to_i
  rslt=$incoming_array.select{ |tweet| tweet.id == tweet_id }
  tweet=rslt[0]
  actionable=Actionable.new
  actionable.tweet=tweet
  actionable.action=Retweet.new
  $action_array << actionable
  $incoming_array.delete(tweet)
  redirect '/'
end

get '/action/:action_name/:tweet_id' do
  # Find the tweet
  tweet_id=params[:tweet_id].to_i
  rslt=$action_array.select{ |actionable| actionable.tweet.id == tweet_id }
  actionable=rslt[0]
  tweet=actionable.tweet
  action=actionable.action
  action.do_action(tweet)
  redirect '/'
end

get '/props/:tweet_id' do
  # Find the tweet
  tweet_id=params[:tweet_id].to_i
  rslt=$action_array.select{ |actionable| actionable.tweet.id == tweet_id }
  actionable=rslt[0]
  @tweet=actionable.tweet
  erb :props
end


