#!/usr/bin/env ruby

require 'bundler/setup'
require 'twitter'
require 'optparse'
require 'yaml'
require './list_tweet_receiver'

# パラメタオプションの解析
params = ARGV.getopts('verbose')
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

loop do
  puts 'ツイートを受信します' if $verbose
  new_tweets = twitter.new_tweets
  puts "#{new_tweets.size} ツイートを受信しました"

  # ツイートを保存
  new_tweets.each do |tweet|
    puts "#{tweet.user.name}: #{tweet.text}({tweet.id})" if $verbose

    # 保存先のパスを生成
    path = File.join(
      config['tweets_dir'],
      tweet.created_at.getlocal("+09:00").strftime('%F'),
      "#{tweet.id}.tweet"
    )

    # ディレクトリが存在していなければ作成
    FileUtils.mkdir_p(File.dirname(path))

    # 保存
    File.write(path, tweet.to_yaml)
  end

  # 流速に応じてスリープ
  sleep -> ts do
    # tweets per second
    tps = ts.size / (ts.first.created_at - ts.last.created_at)

    # 1 リクエストで受信できる最大ツイート数 x 8 に達するまでの秒数を
    # 現在の TL の流速から計算
    ListTweetReceiver::MAX_RECEIVE_SIZE * 0.8 / tps
  end.call(new_tweets).tap{|t| puts "#{t}秒休みます..."}
end
