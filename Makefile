setup:
	gem install bundler --conservative
	bundle install

crontab:
	whenever --update-crontab

crontab_rm:
	whenever --clear-crontab

data:
	ruby data/populate_db.rb

server:
	ruby server.rb

.PHONY: data
