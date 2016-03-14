#!/usr/bin/env ruby

require 'bundler/setup'
require 'twitter'
require 'optparse'
require 'yaml'
require './list_tweet_receiver'
require './tweet_database'

# パラメタオプションの解析
params = ARGV.getopts('', 'verbose')
$verbose = params['verbose']

# 設定ファイルを読み込む
config = YAML.load_file('./config.yaml')

# データベースに接続
db = TweetDatabase.new(config['database'])

# TweetReceiver を作成
twitter = ListTweetReceiver.new(
  config['twitter_auth'],
  config['dest_list'],
  db.last_tweet_id
)

# ツイートを保存
twitter.receive do |tweet|
  db.add(tweet)
end
