PRAGMA foreign_keys = ON;

create table users(
  id         integer primary key,
  created_at date    not null
);

create table user_names(
  user_id integer,
  updated_at  date not null,
  name        string not null,

  primary key(user_id, updated_at),
  foreign key(user_id) references users(id)
);

create table user_screen_names(
  user_id     integer,
  updated_at  date not null,
  screen_name string not null,

  primary key(user_id, updated_at),
  foreign key(user_id) references users(id)
);

create table user_locations(
  user_id     integer,
  updated_at  date not null,
  location    string,

  primary key(user_id, updated_at),
  foreign key(user_id) references users(id)
);

create table user_descriptions(
  user_id integer,
  updated_at  date not null,
  description string,

  primary key(user_id, updated_at),
  foreign key(user_id) references users(id)
);

create table user_websites(
  user_id integer,
  updated_at  date not null,
  url         string,

  primary key(user_id, updated_at),
  foreign key(user_id) references users(id)
);

create table user_protected_changes(
  user_id integer,
  updated_at  date not null,
  protected   boolean not null,

  primary key(user_id, updated_at),
  foreign key(user_id) references users(id)
);

create table clients(
  name       string primary key,
  url        string not null
);

create table tweets(
  id          integer primary key,
  created_at  date    not null,
  text        string  not null,
  client_name string  not null,
  user_id     integer not null,

  foreign key(user_id) references users(id),
  foreign key(client_name) references clients(name)
);

create table tweet_hashtags(
  text     string,
  tweet_id integer,
  indices  integer,

  primary key(text, tweet_id, indices),
  foreign key(tweet_id) references tweets(id)
);

create table tweet_symbols(
  text      string,
  tweet_id integer,
  indices   integer,

  primary key(text, tweet_id, indices),
  foreign key(tweet_id) references tweets(id)
);

create table tweet_mentions(
  text      string,
  tweet_id integer,
  indices   integer,
  user_id   integer not null,

  primary key(text, tweet_id, indices),
  foreign key(tweet_id) references tweets(id)
);

create table tweet_urls(
  url          string,
  expanded_url string,
  display_url  string,
  tweet_id     integer,
  indices      string,

  primary key(url, tweet_id, indices),
  foreign key(tweet_id) references tweets(id)
);
