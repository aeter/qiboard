require 'haml'
require 'sinatra'
require 'sqlite3'

DATABASE = SQLite3::Database.new "db.sqlite"
DATABASE.results_as_hash = true

get '/' do
  params["query"] = "select * from jobs limit 1" unless params["query"]
  @jobs = DATABASE.execute(params["query"])

  haml :index
end
