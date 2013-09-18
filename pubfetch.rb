#!/usr/bin/env ruby
require 'nokogiri'
require 'net/http'
require 'open-uri'


def get_query_id(ids)
  puts "Trying to register a query for ids within range '#{ids.to_s}'"

  epost_query = { db: 'pubmed', id: ids.to_a.join(',') }
  epost_url= URI.parse 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/epost.fcgi'

  epost_response = Net::HTTP.post_form(epost_url, epost_query)
  epost_doc = Nokogiri::XML(epost_response.body)
  query_key = epost_doc.css('QueryKey').text
  webenv= epost_doc.css('WebEnv').text
  puts "Got a query_key (#{query_key}) and WebEnv (#{webenv})"
  return [query_key, webenv]
end

if ARGV.length != 2
  puts 'Usage: pubfetch [start] [finish]

Downloads articles from PubMed in chunks of 1000 as XML. From id [start] to [finish]'
  raise ArgumentError
end


start = ARGV[0].to_i
finish = ARGV[1].to_i
ids = start...finish
chunks = 100000

query_key, webenv = get_query_id(ids)

ids.each_slice(chunks) do |s|
  start = s.min-ids.min

  puts "="*80
  puts "Downloading a chunk of #{chunks} articles from #{s.min} to #{s.max}..."

  targetfile = "pub-#{s.min}-#{s.max}.xml"
  begin
    GC.start #manually triggering garbage collection
    system "wget --no-verbose --output-document #{targetfile} 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&query_key=#{query_key}&WebEnv=#{webenv}&retmax=#{chunks}&retstart=#{start}&retmode=xml'"
    doc = Nokogiri.XML(File.open targetfile)
    sleep 5
  end while doc.errors.size > 0 || doc.css('PubmedArticle').size < 1
  sleep 10
end
