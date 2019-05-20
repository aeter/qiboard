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
    @db.save({"feed_url" => feed["url"], "feed_name" => feed["name"], "tags" => Tagger.new(item.content&.content).tags, "title" => item.title&.content, "content"=> item.content&.content, "link" => item.link.href, "pub_date" => item.published&.content&.to_date.to_s, "created_at" => Time.now.utc.to_s})
  end

  def handle_rss(feed, item)
    @db.save({"feed_url" => feed["url"], "feed_name" => feed["name"], "tags" => Tagger.new(item.description).tags, "title" => item.title, "content" => item.description, "link" => item.link, "pub_date" => item.respond_to?(:pubDate) ? item.pubDate&.to_date.to_s : "", "created_at" => Time.now.utc.to_s})
  end

  def parse_rss(feed)
    log "Parsing feed: #{feed['name']}"
    RSS::Parser.parse(feed["url"], do_validate=false)
  rescue OpenSSL::SSL::SSLError, OpenURI::HTTPError, RSS::Error, Errno::ECONNREFUSED => e
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
        tags text,
        pub_date varchar(30),
        created_at varchar(30),
        UNIQUE (link)
      );
    SQL
  end

  def save(item)
    @db.execute(
      "INSERT OR IGNORE INTO jobs (feed_url, feed_name, title, content, link, tags, pub_date, created_at) values (?, ?, ?, ?, ?, ?, ?, ?)", 
       [ item["feed_url"], item["feed_name"], item["title"], item["content"], item["link"], item["tags"], item["pub_date"], item["created_at"] ]
    )
  end
end


class Tagger
  def initialize(text)
    @text_downcased = text.to_s.downcase
  end

  def tags
    [tech, salary, remote, equity].flatten.select { |t| !t.to_s.empty? }.join(",")
  end

  private

  def tech
    # extremely simple parsing, possible false positives
    # basically trying to parse some more interesting or popular technologies
    tech = []
    [
      " ai ", "android", "angular", "assembler", "c++", "clojure", "coffeescript",
      "django", "elm", "erlang", "flask", "godot", "golang", "java ", "javascript",
      "laravel", "linux", "lisp", "lua", "machine learning", "mysql", "node",
      "nosql", "perl", "php", "postgresql", "python", "rails","react",
      "redis", "ruby", "rust ", "sqlite", "swift", "vue", "webgl", "websocket",
    ].each do |t| 
      tech << t if @text_downcased.include?(t)
    end 
    tech
  end

  def salary
	  # again, very basic regex - and sometimes gives false positives.
    salary = @text_downcased.scan(/(\$?\£?\€?\d+(?:k|K))/u).flatten.last
    salary = "" if salary.to_s.downcase == "401k" # this is USA's pensions fund name, not a salary value
    [salary]
  end

  def remote
    remote = @text_downcased.include?("remote") ? "remote" : ""
    [remote]
  end

  def equity
    equity = @text_downcased.include?("equity") ? "equity" : ""
    [equity]
  end
end

def main
  Collector.new.run
  exit 0 # EXIT_SUCCESS
end

main
