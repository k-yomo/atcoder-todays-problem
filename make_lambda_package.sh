cd `dirname $0`
bundle install --path vendor/bundle
zip -r post_todays_problem.zip post_todays_problem.rb vendor
