require 'scraperwiki'
require 'nokogiri'
require 'mechanize'
agent = Mechanize.new

all_page = agent.get("http://ferrysite.dk/ferrycompany.php?Rid=86")

all_page.links_with(:href=>/ferry.php/).each{ |link|
  ferry_page = link.click  #agent.get("http://ferrysite.dk/ferry.php?id=8502406&lang=en")
  name = ferry_page.search("center h2").inner_html
  item={:name=>name}
  
  puts name
  
  ferry_page.search("table tr").each{ |row|
    key=row.children[0].inner_html
    value=row.children[1].inner_html
    unless ["Former names","Former owners","Sister ships","Notes"].include?(key)
      key.gsub!(/ /,"_")
      item[key]=value
    end
  }
}

ScraperWiki::save_sqlite(['IMO'],item,"ferries")


