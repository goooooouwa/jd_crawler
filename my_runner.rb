require 'mechanize'
require 'pry'

module Runner
  URL_PREFIX = "http://d.360buy.com/area/get?fid="
  ROOT_NODE_CONTAINER = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,42,43,84]
  NODE_CONTAINER = []
  ALLOWED_DEPTH = 1
  AGENT = Mechanize.new

  def self.get_page_until_succeed(url)
    begin
      puts "URL: #{url.inspect}"
      return AGENT.get(url)
    rescue => e
      puts e.inspect
      puts "Request failed. Retrying..."
      get_page_until_succeed(url)
    end
  end

  def self.get_page_then_parse_until_succeed(url)
    page = get_page_until_succeed(url)

    begin
      parse_result = JSON.parse(page.body)
      puts "Parse Result: #{parse_result.inspect}"
      return parse_result
    rescue => e
      puts e.inspect
      puts "Parse failed. Retrying..."
      get_page_then_parse_until_succeed(url)
    end
  end

  def self.find_and_save_all_children(parent_id, parent_depth)
    if (parent_depth >= 0) and (parent_depth <= ALLOWED_DEPTH)
      url = "#{URL_PREFIX}#{parent_id}"
      parse_result = get_page_then_parse_until_succeed(url)
      if parse_result.class == Array and not parse_result.empty?
        puts "Accepted"
        children_array = parse_result
        children_depth = parent_depth + 1
        NODE_CONTAINER.concat(children_array)
        children_array.each do |child|
          child["parent_id"] = parent_id
          find_and_save_all_children(child["id"], children_depth)
        end
      else
        puts "Rejected"
      end
    end
  end

  def self.run
    puts "---------START-----------"
    ROOT_NODE_CONTAINER.each do |root_node|
      find_and_save_all_children(root_node, 0)
    end
    File.open("./jd_areas.json", "w") do |file|
      file.write JSON.generate(NODE_CONTAINER)
    end
    puts "----------END-----------"
  end
end

Runner.run
