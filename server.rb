require 'haml'
require 'sinatra'
require 'sqlite3'

DATABASE = SQLite3::Database.new "db.sqlite"
DATABASE.results_as_hash = true

get '/' do
  @query = params["query"] ? params["query"] : "SELECT * FROM jobs LIMIT 1"
  @jobs = DATABASE.execute(@query)

  haml :index
end
