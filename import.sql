PRAGMA foreign_keys = ON;

create table users(
  id         integer primary key,
  created_at date
);

create table user_names(
  user_id integer,
  changed_at  date not null,
  name        string not null,

  primary key(user_id, changed_at),
  foreign key(user_id) references users(id)
);

create table user_screen_names(
  user_id     integer,
  changed_at  date not null,
  screen_name string not null,

  primary key(user_id, changed_at),
  foreign key(user_id) references users(id)
);

create table user_locations(
  user_id     integer,
  changed_at  date not null,
  location    string,

  primary key(user_id, changed_at),
  foreign key(user_id) references users(id)
);

create table user_descriptions(
  user_id integer,
  changed_at  date not null,
  description string,

  primary key(user_id, changed_at),
  foreign key(user_id) references users(id)
);

create table user_websites(
  user_id integer,
  changed_at  date not null,
  url         string,

  primary key(user_id, changed_at),
  foreign key(user_id) references users(id)
);

create table user_protected_changes(
  user_id integer,
  changed_at  date not null,
  protected   boolean not null,

  primary key(user_id, changed_at),
  foreign key(user_id) references users(id)
);

create table clients(
  name       string primary key,
  url        string not null
);

create table tweets(
  id             integer primary key,
  user_id        integer not null,

  foreign key(user_id) references users(id)
);

create table tweet_bodies(
  tweet_id       integer primary key,
  text           string  not null,
  created_at     date    not null,
  client_name    string  not null,

  foreign key(tweet_id) references tweets(id),
  foreign key(client_name) references clients(name)
);

create table tweet_replies(
  tweet_id       integer primary key,
  reply_tweet_id integer,

  foreign key(tweet_id) references tweets(id),
  foreign key(reply_tweet_id) references tweets(id)
);

create table tweet_hashtags(
  tweet_id integer,
  indice  integer,
  text     string,

  primary key(tweet_id, indice),
  foreign key(tweet_id) references tweets(id)
);

create table tweet_symbols(
  tweet_id integer,
  indice   integer,
  text      string,

  primary key(tweet_id, indice),
  foreign key(tweet_id) references tweets(id)
);

create table tweet_mentions(
  tweet_id integer,
  indice   integer,
  user_id   integer not null,

  primary key(tweet_id, indice),
  foreign key(tweet_id) references tweets(id)
);

create table tweet_urls(
  tweet_id     integer,
  indice      string,
  url          string,
  expanded_url string,
  display_url  string,

  primary key(tweet_id, indice),
  foreign key(tweet_id) references tweets(id)
);
