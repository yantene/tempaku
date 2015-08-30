require 'twitter'

class ListTweetReceiver
  MAX_RECEIVE_SIZE = 100

  def initialize(rest_client, list, since_id = nil)
    @rest = if Hash === rest_client
              # Hash ならその情報を利用してクライアントを作成
              Twitter::REST::Client.new(rest_client)
            else
              # そうでなければそれをそのままクライアントとする
              rest_client
            end

    @list = @rest.list(*list.split('/'))

    @since_id = since_id
  end

  def new_tweets
    tweets = []

    loop do
      # 前回までに取得されたツイートの中で最新のものの tweet_id (@since_id) から，
      # 今回取得したツイートの中で最も古いものの tweet_id - 1 までを取得する．
      new_tweets = receive_tweets(
        @since_id, tweets.first && tweets.map(&:id).min - 1
      )
      tweets.push(*new_tweets)

      # 取得目標 (@since_id) がない場合，
      # あるいは新規に取得したツイートがない場合はループを抜ける．
      break if @since_id.nil? || new_tweets.empty?
    end

    # 新たなツイートの取得があれば， @since_id の値を更新する．
    @since_id = tweets.map(&:id).max unless tweets.empty?
    tweets
  end

  def receive_tweets(since_id = nil, max_id = nil)
    puts "#{since_id}から#{max_id}まで取得しようとしてみます" if $verbose

    # オプションを指定
    opts = { count: MAX_RECEIVE_SIZE, include_rts: 'false' }
    opts[:max_id] = max_id if max_id
    opts[:since_id] = since_id if since_id

    # ツイートの取得
    begin
      @rest.list_timeline(@list, opts).tap { |ts|
        unless ts.empty?
          puts "#{ts.first.id}から#{ts.last.id}まで取得しました" if $verbose
        end
      }
    rescue => e
      puts "#{e}が発生しました．60秒待ちます．" if $verbose
      sleep 60
      retry
    end
  end
end
