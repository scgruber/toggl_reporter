#!/usr/bin/env ruby

# This script generates a weekly report of tasks recorded in Toggl

require 'date'
require 'optparse'
require 'json'
require 'cgi'

$options = {
  :api_key => nil,
  :start => DateTime.iso8601((Date.today - 7).iso8601),
  :end => DateTime.iso8601(Date.today.iso8601),
  :threshold => 300,
  :include => [],
  :exclude => [],
}

OptionParser.new do |opts|
  opts.on('-k', '--api-key KEY', 'The user\'s Toggl API key (required)', String) do |k|
    $options[:api_key] = k
  end
  opts.on('--start DATE', 'Start date for time entries to consider (default: 7 days ago)', String) do |d|
    $options[:start] = DateTime.iso8601(d)
  end
  opts.on('--end DATE', 'End date for time entries to consider (default: today)', String) do |d|
    $options[:end] = DateTime.iso8601(d)
  end
  opts.on('-t', '--threshold SECS', 'Drop all activities with a shorter duration (default: 300)', Integer) do |s|
    $options[:threshold] = s
  end
  opts.on('-i', '--include P1,P2,P3', 'Include only these projects in summary', Array) do |ps|
    $options[:include] = ps
  end
  opts.on('-e', '--exclude P1,P2,P3', 'Exclude these projects from summary', Array) do |ps|
    $options[:exclude] = ps
  end
end.parse!

abort 'Must provide a Toggl API key!' unless $options[:api_key]

def api_get(endpoint, params={})
  curl_user = "#{$options[:api_key]}:api_token"
  query_params = params.to_a.map { |k, v| "#{k}=#{CGI.escape v}" }.join('&')
  JSON.parse `curl -s -u #{curl_user} -X GET https://www.toggl.com/api/v8/#{endpoint}?#{query_params}`
end

time_entries = api_get('time_entries', :start_date => $options[:start].iso8601, :end_date => $options[:end].iso8601)
projects = api_get("workspaces/#{time_entries.first['wid']}/projects").group_by { |proj| proj['id'] }

activities = {}
time_entries.each do |te|
  if activities[te['description']]
    activities[te['description']]['duration'] += te['duration']
  else
    activities[te['description']] = {
      'project' => projects[te['pid']].first['name'],
      'duration' => te['duration'],
    }
  end
end

nontrivial_activities = activities.reject { |_, v| v['duration'] < $options[:threshold] }

grouped_activities = nontrivial_activities.group_by { |_, v| v['project'] }

grouped_activities.each do |proj, acts|
  next if (!$options[:include].empty? && !$options[:include].include?(proj)) || $options[:exclude].include?(proj)
  puts "#{proj}:"
  acts.each do |desc, info|
    puts "  * [#{info['duration'] / 60}m] #{desc}"
  end
end
