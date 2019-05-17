require 'json'
require 'rss'
require "sqlite3"

class Collector
  def initialize
    @db = DB.new
  end

  def run
    File.open("#{current_dir}/sources.json") do |feeds|
      JSON.load(feeds).each do |feed|
        rss = parse_rss(feed)
        next unless rss
        rss.items.each do |item|
          rss.feed_type == "atom" ? handle_atom(feed, item) : handle_rss(feed, item)
        end
      end
    end
  end

  private

  def handle_atom(feed, item)
    @db.save({"feed_url" => feed["url"], "feed_name" => feed["name"], "title" => item.title&.content, "content"=> item.content&.content, "link" => item.link.href, "pub_date" => item.published&.content&.to_date.to_s, "created_at" => Time.now.utc.to_s})
  end

  def handle_rss(feed, item)
    @db.save({"feed_url" => feed["url"], "feed_name" => feed["name"], "title" => item.title, "content" => item.description, "link" => item.link, "pub_date" => item.respond_to?(:pubDate) ? item.pubDate&.to_date.to_s : "", "created_at" => Time.now.utc.to_s})
  end

  def parse_rss(feed)
    log "Parsing feed: #{feed['name']}"
    RSS::Parser.parse(feed["url"], do_validate=false)
  rescue OpenURI::HTTPError, RSS::Error, Errno::ECONNREFUSED => e
    log "Error: #{e.message}"
  end

  def current_dir
    File.expand_path File.dirname(__FILE__)
  end

  def log(message)
    puts "#{Time.now.utc} | #{message}"
  end
end

class DB
  def initialize
    @db = SQLite3::Database.new "db.sqlite"
    rows = @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS jobs (
        feed_url varchar(200),
        feed_name varchar(100),
        title varchar(200),
        content text,
        link text,
        pub_date varchar(30),
        created_at varchar(30),
        UNIQUE (link)
      );
    SQL
  end

  def save(item)
    @db.execute(
      "INSERT OR IGNORE INTO jobs (feed_url, feed_name, title, content, link, pub_date, created_at) values (?, ?, ?, ?, ?, ?, ?)", 
       [ item["feed_url"], item["feed_name"], item["title"], item["content"], item["link"], item["pub_date"], item["created_at"] ]
    )
  end
end

def main
  Collector.new.run
  exit 0 # EXIT_SUCCESS
end

main
