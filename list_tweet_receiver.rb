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

  def receive
    loop do
      # 新着ツイートを取得
      tweets = new_tweets

      # 各ツイートを yield
      tweets.each do |tweet|
        yield tweet
      end

      # 流速に応じてスリープ
      sleep -> ts do
        # 1 秒あたりのツイート数
        tps = ts.size / (ts.first.created_at - ts.last.created_at)

        # 1 リクエストで受信できる最大ツイート数 x 0.8 に達するまでの秒数を
        # 現在の TL の流速から計算
        MAX_RECEIVE_SIZE * 0.8 / tps
      end.call(tweets).tap{|t| puts "#{t}秒休みます..."}
    end
  end

  def new_tweets
    tweets = []

    loop do
      # 前回までに取得されたツイートの中で最新のものの tweet_id (@since_id) から，
      # 今回取得したツイートの中で最も古いものの tweet_id - 1 までを取得する．
      new_tweets = fetch(
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

  def fetch(since_id = nil, max_id = nil)
    puts "#{since_id ? "#{since_id}から" : ''}#{max_id ? "#{max_id}まで" : ''}取得してみます" if $verbose

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
