#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'json'
require 'open-uri'

require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def json_at(url)
  JSON.parse(open(url).read, symbolize_names: true)[:objects]
end

term = {
  id: 10,
  name: 'X Legislatura',
  start_date: '2011-11-28',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

PARTIES_URL = 'http://proyectocolibri.es/api/v1/party/'
PERSONS_URL = 'http://proyectocolibri.es/api/v1/groupmember/'

parties = json_at(PARTIES_URL)
party = ->(api_url) { 
  parties.find { |p| p[:id].to_s == api_url.split('/').last.to_s }[:name]
}

persons = json_at(PERSONS_URL)
persons.each do |mp|
  data = { 
    id: mp[:member][:congress_id],
    name: "#{mp[:member][:name]}, #{mp[:member][:second_name]}",
    family_name: mp[:member][:name],
    given_name: mp[:member][:second_name],
    party: party.(mp[:party]),
    party_id: mp[:party].split('/').last,
    area: mp[:member][:division],
    start_date: mp[:member][:inscription_date],
    end_date: mp[:member][:termination_date],
    email: mp[:member][:email],
    twitter: mp[:member][:twitter],
    term: mp[:term],
    source: mp[:member][:congress_web],
  }
  ScraperWiki.save_sqlite([:id, :term], data)
end
puts "Added #{persons.count} records"

