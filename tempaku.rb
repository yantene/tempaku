#!/usr/bin/env ruby

require 'bundler/setup'
require 'twitter'
require 'sequel'
require 'optparse'
require 'yaml'
require 'rexml/document'
require './list_tweet_receiver'

# パラメタオプションの解析
params = ARGV.getopts('', 'verbose')
$verbose = params['verbose']

# 設定ファイルを読み込む
config = YAML.load_file('./config.yaml')

# since_id の作成
since_id = -> tweets_dir do
  YAML.load_file(
    Dir.glob(File.join(Dir.glob(File.join(tweets_dir, '*')).max, '*')).max
  ).id
end.call(config['tweets_dir']) rescue nil

# TweetReceiver を作成
twitter = ListTweetReceiver.new(
  config['twitter_auth'],
  config['dest_list'],
  since_id
)

# データベースに接続
db = Sequel.sqlite('twitter.db')

loop do
  # ツイートを保存
  twitter.receive do |tweet|

    puts "#{tweet.user.screen_name}: #{tweet.text}"

    if db[:users].where(id: tweet.user.id).count == 0
      db[:users].insert(
        id: tweet.user.id,
        created_at: tweet.user.created_at
      )
      puts "user_idが#{tweet.user.id}番の人は初めてなのでusersにインサート"
    end

    unless db[:user_names].where(user_id: tweet.user.id).
      order(Sequel.desc(:updated_at)).get(:name) == tweet.user.name
      db[:user_names].insert(
        user_id: tweet.user.id,
        updated_at: tweet.created_at,
        name: tweet.user.name
      )
      puts "#{tweet.user.name}さんに名前変わったみたいなのでuser_namesにインサート"
    end

    unless db[:user_screen_names].where(user_id: tweet.user.id).
      order(Sequel.desc(:updated_at)).get(:screen_name) == tweet.user.screen_name
      db[:user_screen_names].insert(
        user_id: tweet.user.id,
        updated_at: tweet.created_at,
        screen_name: tweet.user.screen_name
      )
      puts "#{tweet.user.screen_name}さんに名前変わったみたいなのでuser_screen_namesにインサート"
    end

    unless db[:user_locations].where(user_id: tweet.user.id).
      order(Sequel.desc(:updated_at)).get(:location) == tweet.user.location
      if tweet.user.location.nil?
        db[:user_locations].insert(
          user_id: tweet.user.id,
          updated_at: tweet.created_at
        )
        puts 'location nil!!!'
      else
        db[:user_locations].insert(
          user_id: tweet.user.id,
          updated_at: tweet.created_at,
          location: tweet.user.location
        )
      end
      puts "#{tweet.user.location}に居住地変わったみたいなのでuser_locationsにインサート"
    end

    unless db[:user_descriptions].where(user_id: tweet.user.id).
      order(Sequel.desc(:updated_at)).get(:description) == tweet.user.description
      if tweet.user.description.nil?
        db[:user_descriptions].insert(
          user_id: tweet.user.id,
          updated_at: tweet.created_at
        )
        puts 'description nil!!!'
      else
        db[:user_descriptions].insert(
          user_id: tweet.user.id,
          updated_at: tweet.created_at,
          description: tweet.user.description
        )
      end
      puts "#{tweet.user.description}に自己紹介変わったみたいなのでuser_descriptionsにインサート"
    end

    unless db[:user_websites].where(user_id: tweet.user.id).
      order(Sequel.desc(:updated_at)).get(:url) == tweet.user.website.to_s
      if tweet.user.website.nil?
        db[:user_websites].insert(
          user_id: tweet.user.id,
          updated_at: tweet.created_at
        )
        puts 'website nil!!!'
      else
        db[:user_websites].insert(
          user_id: tweet.user.id,
          updated_at: tweet.created_at,
          url: tweet.user.website.to_s
        )
      end
      puts "#{tweet.user.website.to_s}にウェブページ変わったみたいなのでuser_urlsにインサート"
    end

    unless db[:user_protected_changes].where(user_id: tweet.user.id).
      order(Sequel.desc(:updated_at)).get(:protected) == tweet.user.protected?
      db[:user_protected_changes].insert(
        user_id: tweet.user.id,
        updated_at: tweet.created_at,
        protected: tweet.user.protected?
      )
      puts "#{tweet.user.protected? ? '鍵付き' : '鍵なし'}になったみたいなのでuser_protected_changesにインサート"
    end

    # クライアント名とURLを取り出す
    client_name, client_url = -> source do
      a = REXML::Document.new(source).elements['a']
      name = a.text
      url  = a.attributes['href']
      [name, url]
    end.call(tweet.source)
  end
end
