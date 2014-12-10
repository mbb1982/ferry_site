require 'scraperwiki'
require 'nokogiri'
require 'mechanize'
agent = Mechanize.new

all_page = agent.get("http://ferrysite.dk/ferrycompany.php?Rid=86")

all_page.links_with(:href=>/ferry.php/).each{ |link|
  ferry_page = link.click  #agent.get("http://ferrysite.dk/ferry.php?id=8502406&lang=en")
  encoding = ferry_page.encoding()
  
  name = ferry_page.search("center h2").inner_html.encode("UTF-8")
  item={:name=>name}
  
  puts name
  
  ferry_page.search("table tr").each{ |row|
    key=row.children[0].inner_html.encode("UTF-8")
    value=row.children[1].inner_html.encode("UTF-8")
    
    if key == "Former names"
      value.split(/<br>/).each{|line|
        if tokens = /^(.*) \((.*)\-(.*)\) - (.*)/.match(line.gsub(/<.*?>/,""))
          former_name = {:name=>tokens[1],:name_from=>tokens[2],:name_to=>tokens[3],:operator=>tokens[4],:key=>line.gsub(/<.*?>/,"")}
          ScraperWiki::save_sqlite([:name,:name_from,:name_to,:operator],former_name,"former_names")
        end
      }
    end
    
    unless ["Former names","Former owners","Sister ships","Notes"].include?(key)
      key.gsub!(/ /,"_")
      item[key]=value
    end
  }
  ScraperWiki::save_sqlite(['IMO'],item,"ferries")
}




