require 'nokogiri'
require 'net/http'
require 'open-uri'

ids=12_000_000...12_005_000
chunks=1000

epost_query = { db: 'pubmed', id: ids.to_a.join(',') }
epost_url= URI.parse 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/epost.fcgi'

epost_response = Net::HTTP.post_form(epost_url, epost_query)
epost_doc = Nokogiri::XML(epost_response.body)
query_key = epost_doc.css('QueryKey').text
webenv= epost_doc.css('WebEnv').text
p 'Got a query_keya and WebEnv'
p query_key, webenv

ids.each_slice(chunks) do |s|
  start = ids.min-s.min
  system "curl 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&query_key=#{query_key}&WebEnv=#{webenv}&retmax=#{chunks}&retstart=#{start}&retmode=xml' > pub-#{s.min}-#{s.max}.xml"
end
