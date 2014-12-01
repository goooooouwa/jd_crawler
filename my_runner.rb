require 'mechanize'
require 'pry'

module Runner
  URL_PREFIX = "http://d.360buy.com/area/get?fid="
  NODE_CONTAINER = JSON.parse(File.open("./root_nodes.json").read())
  AGENT = Mechanize.new

  def self.get_page_until_succeed(url)
    begin
      puts "GET #{url.inspect}"
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
      puts "Parse result: #{parse_result.inspect}"
      return parse_result
    rescue => e
      puts e.inspect
      puts "Parse failed. Retrying..."
      get_page_then_parse_until_succeed(url)
    end
  end

  def self.find_and_save_all_children(parent)
    puts "Parent: #{parent}"
    parse_result = get_page_then_parse_until_succeed("#{URL_PREFIX}#{parent['id']}")
    if parse_result.class == Array and not parse_result.empty?
      puts "All children of parent found."
      NODE_CONTAINER.concat(parse_result.each { |child| child["parent_id"] = parent["id"] })
    end
  end

  def self.run
    puts "---------START-----------"
    NODE_CONTAINER.each { |node| find_and_save_all_children(node) }

    File.open("./jd_areas.json", "w") do |file|
      file.write JSON.generate(NODE_CONTAINER)
    end
    puts "----------END-----------"
  end
end

Runner.run
