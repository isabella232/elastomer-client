require 'rubygems' unless defined? Gem
require 'bundler'
Bundler.require(:default, :development)

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"
  end
end

require 'minitest/spec'
require 'minitest/autorun'

# push the lib folder onto the load path
$LOAD_PATH.unshift 'lib'
require 'elastomer/client'

# we are going to use the same client instance everywhere!
# the client should always be stateless
$client_params = {
  :port => ENV['GH_ELASTICSEARCH_PORT'] || 9200,
  :read_timeout => 0.5,
  :open_timeout => 0.5,
  :opaque_id => true
}
$client = Elastomer::Client.new $client_params

# ensure we have an ElasticSearch server to test with
raise "No server available at #{$client.url}" unless $client.available?

# remove any lingering test indices from the cluster
MiniTest::Unit.after_tests do
  $client.cluster.indices.keys.each do |name|
    next unless name =~ /^elastomer-/i
    $client.index(name).delete
  end

  $client.cluster.templates.keys.each do |name|
    next unless name =~ /^elastomer-/i
    $client.template(name).delete
  end
end

# add custom assertions
require File.expand_path('../assertions', __FILE__)

# require 'elastomer/notifications'
# require 'pp'

# ActiveSupport::Notifications.subscribe('request.client.elastomer') do |name, start_time, end_time, transaction_id, payload|
#   $stdout.puts '-'*100
#   #$stdout.puts "-- #{payload[:action].inspect}"
#   pp payload #if payload[:action].nil?
# end
