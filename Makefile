setup:
	bundle install --path vendor/bundle --binstubs

crontab:
	bundle exec whenever --update-crontab

crontab_rm:
	bundle exec whenever --clear-crontab

data:
	bundle exec ruby data/populate_db.rb

server:
	bundle exec ruby server.rb

.PHONY: data
