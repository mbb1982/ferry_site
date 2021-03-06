require 'scraperwiki'
require 'nokogiri'
require 'mechanize'
agent = Mechanize.new

all_page = agent.get("http://ferrysite.dk/ferryname.php")

link_done ={}

all_page.links_with(:href=>/ferry.php/).each{ |link|
  
  next if link_done.has_key?(link.href)
  
  link_done[link.href]=1
  
  ferry_page = link.click  #agent.get("http://ferrysite.dk/ferry.php?id=8502406&lang=en")
  encoding = ferry_page.encoding()
  
  name = ferry_page.search("center h2").inner_html.encode("UTF-8")
  item={:name=>name}
  
  puts name
  imo = "99999999999"
  ferry_page.search("table tr").each{ |row|
    key=row.children[0].inner_html.encode("UTF-8")
    value=row.children[1].inner_html.encode("UTF-8")
    
    
    if key == "IMO"
      imo=value
    end
    
    if key == "GT"
      if  gt_split=/(?:(.*) \/ )?(\d+)/.match(value.gsub(/\./,""))
        if gt_split[1]
          item[:ex_gt]=gt_split[1]
        end
        value=gt_split[2].to_i
      end
    end
    
    if key == "Former names"
      value.split(/<br>/).each{|line|
        if tokens = /^(.*) \((.*)\-(.*)\) - (.*)/.match(line.gsub(/<.*?>/,""))
          former_name = {:imo=>imo,:name=>tokens[1],:name_from=>tokens[2],:name_to=>tokens[3],:operator=>tokens[4],:key=>line.gsub(/<.*?>/,"")}
          ScraperWiki::save_sqlite([:imo,:name,:name_from,:name_to,:operator],former_name,"former_names")
        end
      }
    end
    
    unless ["Former names","Former owners","Sister ships","Notes"].include?(key)
      key.gsub!(/ /,"_")
      if value.class==String
        value=value.gsub(/<.*?>/,"")
      end
      item[key]=value
    end
  }
  ScraperWiki::save_sqlite(['IMO'],item,"ferries")
}




