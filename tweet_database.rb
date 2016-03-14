require 'sequel'
require 'rexml/document'

class TweetDatabase
  def initialize(db)
    @db = Sequel.connect(db)
  end

  def add(tweet)
    # ユーザ情報の追加
    add_user(tweet.user.id, tweet.user.created_at)
    change_user_name(tweet.user.id, tweet.created_at, tweet.user.name)
    change_user_screen_name(tweet.user.id, tweet.created_at, tweet.user.screen_name)
    change_user_location(tweet.user.id, tweet.created_at, tweet.user.location)
    change_user_description(tweet.user.id, tweet.created_at, tweet.user.description)
    change_user_website(tweet.user.id, tweet.created_at, tweet.user.website&.to_s)
    change_user_protected_flg(tweet.user.id, tweet.created_at, tweet.user.protected?)

    # クライアント情報の追加
    client_name, client_url = -> source do
      a = REXML::Document.new(source).elements['a']
      name = a.text
      url  = a.attributes['href']
      [name, url]
    end.call(tweet.source)
    add_client(client_name, client_url)

    # ツイート情報の追加
    add_tweet(tweet.id, tweet.user.id)
    set_tweet_body(tweet.id, tweet.text, tweet.created_at, client_name)
    tweet.hashtags.each do |hashtag|
      set_tweet_hashtag(tweet.id, hashtag.text, hashtag.indices.first)
    end
    tweet.symbols.each do |symbol|
      set_tweet_symbol(tweet.id, symbol.text, symbol.indices.first)
    end
    tweet.user_mentions.each do |mention|
      add_user(mention.id, nil)
      change_user_name(mention.id, tweet.created_at, mention.name)
      change_user_screen_name(mention.id, tweet.created_at, mention.screen_name)

      set_tweet_mention(tweet.id, mention.id, mention.indices.first)
    end
    tweet.urls.each do |url|
      set_tweet_url(tweet.id, url.indices.first,
                    url.url.to_s,
                    url.expanded_url.to_s,
                    url.display_url.to_s)
    end
    unless tweet.in_reply_to_status_id.nil?
      add_user(tweet.in_reply_to_user_id)
      change_user_screen_name(tweet.in_reply_to_user_id,
                              tweet.created_at,
                              tweet.in_reply_to_screen_name)
      add_tweet(tweet.in_reply_to_status_id, tweet.in_reply_to_user_id)
      set_tweet_reply(tweet.id, tweet.in_reply_to_status_id)
    end
  end

  def print_all_users
    get_users.map do |user|
      [user[:id], {
        created_at: user[:created_at],
        name: get_user_name_history(user[:id]),
        screen_name: get_user_screen_name_history(user[:id]),
        location: get_user_location_history(user[:id]),
        description: get_user_description_history(user[:id]),
        website: get_user_website_history(user[:id]),
        protected_flg: get_user_protected_flg_history(user[:id])
      }]
    end.to_h
  end

  def get_tweet(tweet_id)
    
  end

  def last_tweet_id
    @db[:tweets].max(:id)
  end

  private

  # users

  def get_user(id)
    @db[:users].where(id: id).first
  end

  def get_users
    @db[:users].all
  end

  def add_user(id, created_at = nil)
    user = get_user(id)
    if user.nil?
      # 過去にデータの無いユーザ
      if created_at.nil?
        @db[:users].insert(id: id)
      else
        @db[:users].insert(id: id, created_at: created_at)
      end
    elsif user[:created_at].nil? && !created_at.nil?
      # 過去にデータは存在するが、そこにアカウント作成日時の無いユーザ
      @db[:users].where(id: id).update(created_at: created_at)
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # user names

  def get_latest_user_name(id)
    @db[:user_names].where(user_id: id).order(Sequel.desc(:changed_at)).get(:name)
  end

  def get_user_name_history(id)
    @db[:user_names].where(user_id: id).order(Sequel.desc(:changed_at)).all.
                     map{|e| [e[:changed_at], e[:name]]}.to_h
  end

  def change_user_name(id, changed_at, name)
    unless name == get_latest_user_name(id)
      @db[:user_names].insert(
        user_id: id,
        changed_at: changed_at,
        name: name
      )
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # user screen names

  def get_latest_user_screen_name(id)
    @db[:user_screen_names].where(user_id: id).order(Sequel.desc(:changed_at)).get(:screen_name)
  end

  def get_user_screen_name_history(id)
    @db[:user_screen_names].where(user_id: id).order(Sequel.desc(:changed_at)).all.
                            map{|e| [e[:changed_at], e[:screen_name]]}.to_h
  end

  def change_user_screen_name(id, changed_at, screen_name)
    unless get_latest_user_screen_name(id) == screen_name
      @db[:user_screen_names].insert(
        user_id: id,
        changed_at: changed_at,
        screen_name: screen_name
      )
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # user locations

  def get_latest_user_location(id)
    @db[:user_locations].where(user_id: id).order(Sequel.desc(:changed_at)).get(:location)
  end

  def get_user_location_history(id)
    @db[:user_locations].where(user_id: id).order(Sequel.desc(:changed_at)).all.
                         map{|e| [e[:changed_at], e[:location]]}.to_h
  end

  def change_user_location(id, changed_at, location = nil)
    unless get_latest_user_location(id) == location
      if location.nil?
        @db[:user_locations].insert(user_id: id, changed_at: changed_at)
      else
        @db[:user_locations].insert(
          user_id: id,
          changed_at: changed_at,
          location: location
        )
      end
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # user descriptions

  def get_latest_user_description(id)
    @db[:user_descriptions].where(user_id: id).order(Sequel.desc(:changed_at)).get(:description)
  end

  def get_user_description_history(id)
    @db[:user_descriptions].where(user_id: id).order(Sequel.desc(:changed_at)).all.
                            map{|e| [e[:changed_at], e[:description]]}.to_h
  end

  def change_user_description(id, changed_at, description = nil)
    unless @db[:user_descriptions].where(user_id: id).count != 0 &&
           get_latest_user_description(id) == description
      if description.nil?
        @db[:user_descriptions].insert(user_id: id, changed_at: changed_at)
      else
        @db[:user_descriptions].insert(
          user_id: id,
          changed_at: changed_at,
          description: description
        )
      end
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # user websites

  def get_latest_user_website(id)
    @db[:user_websites].where(user_id: id).order(Sequel.desc(:changed_at)).get(:url)
  end

  def get_user_website_history(id)
    @db[:user_websites].where(user_id: id).order(Sequel.desc(:changed_at)).all.
                        map{|e| [e[:changed_at], e[:url]]}.to_h
  end

  def change_user_website(id, changed_at, url = nil)
    unless @db[:user_websites].where(user_id: id).count != 0 &&
           get_latest_user_website(id) == url
      if url.nil?
        @db[:user_websites].insert(user_id: id, changed_at: changed_at)
      else
        @db[:user_websites].insert(
          user_id: id,
          changed_at: changed_at,
          url: url
        )
      end
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # user protected flag

  def get_latest_user_protected_flg(id)
    @db[:user_protected_changes].where(user_id: id).order(Sequel.desc(:changed_at)).get(:protected)
  end

  def get_user_protected_flg_history(id)
    @db[:user_protected_changes].where(user_id: id).order(Sequel.desc(:changed_at)).all.
                                 map{|e| [e[:changed_at], e[:protected]]}.to_h
  end

  def change_user_protected_flg(id, changed_at, protected_flg)
    unless @db[:user_protected_changes].where(user_id: id).count != 0 &&
           get_latest_user_protected_flg(id) == protected_flg
      @db[:user_protected_changes].insert(
        user_id: id,
        changed_at: changed_at,
        protected: protected_flg
      )
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # clients

  def client_exist?(name)
    @db[:clients].where(name: name).count == 1
  end

  def get_clients
    @db[:clients].all
  end

  def add_client(name, url)
    @db[:clients].insert(name: name, url: url) unless client_exist?(name)
  rescue Sequel::UniqueConstraintViolation => ex
  end

  # tweets

  def tweet_exist?(id)
    @db[:tweets].where(id: id).count == 1
  end

  def get_tweets
    @db[:tweets].all
  end

  def add_tweet(id, user_id)
    unless tweet_exist?(id)
      @db[:tweets].insert(
        id: id,
        user_id: user_id
      )
    end
  rescue Sequel::UniqueConstraintViolation => ex
  end

  def set_tweet_body(tweet_id, text, created_at, client_name)
    @db[:tweet_bodies].insert(
      tweet_id: tweet_id,
      text: text,
      created_at: created_at,
      client_name: client_name
    )
  rescue Sequel::UniqueConstraintViolation => ex
  end

  def set_tweet_reply(tweet_id, reply_tweet_id)
    @db[:tweet_replies].insert(
      tweet_id: tweet_id,
      reply_tweet_id: reply_tweet_id
    )
  rescue Sequel::UniqueConstraintViolation => ex
  end

  def set_tweet_hashtag(tweet_id, text, indice)
    @db[:tweet_hashtags].insert(
      tweet_id: tweet_id,
      indice: indice,
      text: text
    )
  rescue Sequel::UniqueConstraintViolation => ex
  end

  def set_tweet_symbol(tweet_id, text, indice)
    @db[:tweet_symbols].insert(
      tweet_id: tweet_id,
      indice: indice,
      text: text
    )
  rescue Sequel::UniqueConstraintViolation => ex
  end

  def set_tweet_mention(tweet_id, user_id, indice)
    @db[:tweet_mentions].insert(
      tweet_id: tweet_id,
      indice: indice,
      user_id: user_id
    )
  rescue Sequel::UniqueConstraintViolation => ex
  end

  def set_tweet_url(tweet_id, indice, url, expanded_url, display_url)
    @db[:tweet_urls].insert(
      tweet_id: tweet_id,
      indice: indice,
      url: url,
      expanded_url: expanded_url,
      display_url: display_url
    )
  rescue Sequel::UniqueConstraintViolation => ex
  end
end
