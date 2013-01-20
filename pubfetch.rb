#!/usr/bin/env ruby
require 'nokogiri'
require 'net/http'
require 'open-uri'
if ARGV.length != 2
  puts 'Usage: pubfetch [start] [finish]

Downloads articles from PubMed in chunks of 1000 as XML. From id [start] to [finish]'
  raise ArgumentError
end


start = ARGV[0].to_i
finish = ARGV[1].to_i
ids = start...finish
chunks = 500

puts "Trying to register a query for ids within range '#{ids.to_s}'"

epost_query = { db: 'pubmed', id: ids.to_a.join(',') }
epost_url= URI.parse 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/epost.fcgi'

epost_response = Net::HTTP.post_form(epost_url, epost_query)
epost_doc = Nokogiri::XML(epost_response.body)
query_key = epost_doc.css('QueryKey').text
webenv= epost_doc.css('WebEnv').text
puts "Got a query_key (#{query_key}) and WebEnv (#{webenv})"

ids.each_slice(chunks) do |s|
  start = ids.min-s.min

  puts "="*80
  puts "Downloading a chunk of #{chunks} articles from #{s.min} to #{s.max}..."

  targetfile = "pub-#{s.min}-#{s.max}.xml"
  begin
    system "wget --output-document #{targetfile} 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&query_key=#{query_key}&WebEnv=#{webenv}&retmax=#{chunks}&retstart=#{start}&retmode=xml'"
    doc = Nokogiri.XML(File.open targetfile)
  end while doc.errors.size > 0
  sleep 20
end
