require 'haml'
require 'sinatra'
require 'sqlite3'

DATABASE = SQLite3::Database.new "db.sqlite"
DATABASE.results_as_hash = true

get '/' do
  # such security. wow.
  @query = params["query"].to_s.strip.downcase.start_with?("select") ? params["query"] : "SELECT * FROM jobs LIMIT 1"
  @jobs = DATABASE.execute(@query)

  haml :index
end
