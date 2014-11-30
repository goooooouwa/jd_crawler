require 'mechanize'
require 'pry'

module Runner
  URL_PREFIX = "http://d.360buy.com/area/get?fid="
  ROOT_NODE_CONTAINER = []
  CHILDREN_NODE_CONTAINER = []
  NODE_BLACK_LIST = []
  MAX_HEIGHT = 1
  USE_BLACK_LIST = false
  AGENT = Mechanize.new

  def self.get_page_until_succeed(url)
    begin
      puts "[GET] #{url.inspect}"
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

  def self.find_and_save_all_children(parent, parent_height)
    if USE_BLACK_LIST and NODE_BLACK_LIST.include?(parent)
      puts "[SKIPPED] Childless parent skipped."
      return
    end

    parse_result = get_page_then_parse_until_succeed("#{URL_PREFIX}#{parent['id']}")
    if parse_result.class == Array and not parse_result.empty?
      # 1. got all children of parent
      puts "[CHILDREN] Got all children of parent."
      children_array = parse_result
      children_array.map { |child| child["parent_id"] = parent["id"] }
      CHILDREN_NODE_CONTAINER.concat(children_array)

      children_height = parent_height + 1
      if (children_height >= 0) and (children_height < MAX_HEIGHT)
        # NOTE this should not happen since MAX_HEIGHT is set to 1
        binding.pry
        children_array.each do |child|
          find_and_save_all_children(child, children_height)
        end
      end
    elsif (parse_result.class == Hash) or (parse_result.class == Array and parse_result.empty?)
      # 2. got one child or an empty array which indicates the parent has no child.
      # NOTE we assume if a node has no child, then the node's siblings have no child too.
      # This is to optimize the traversing since the majority of time is spent on checking childless nodes.
      puts "[CHILDLESS] Parent has no child."
      unless parent["parent_id"].nil?
        parent_siblings = ROOT_NODE_CONTAINER.select { |node| node["parent_id"] == parent["parent_id"] }
        NODE_BLACK_LIST.concat(parent_siblings)
      end
    else
      # 3. unknown
      puts "oops"
      binding.pry
    end
  end

  def self.run
    puts "---------START-----------"
    ROOT_NODE_CONTAINER.concat(JSON.parse(File.open("./root_nodes.json").read()))
    if MAX_HEIGHT > 0
      ROOT_NODE_CONTAINER.each do |root_node|
        puts "root: #{root_node}"
        find_and_save_all_children(root_node, 0)
      end
    end

    File.open("./jd_areas.json", "w") do |file|
      file.write JSON.generate(CHILDREN_NODE_CONTAINER)
    end
    if USE_BLACK_LIST
      File.open("./node_black_list.json", "w") do |file|
        file.write JSON.generate(NODE_BLACK_LIST)
      end
    end
    puts "----------END-----------"
  end
end

Runner.run
