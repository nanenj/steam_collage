require 'httparty'
require 'json'
require 'rio'
require 'trollop'
require 'RMagick'
include Magick

steam_url_base = "http://steamcommunity.com/id/"
steam_url_games = "/games?tab=all"

opts = Trollop::options do
  opt :no_download, "Do not download game images", :default => true
  opt :id, "Steam profile ID to target", :type => :string,  :required => true
  opt :width, "Width of collage in game images", :default => 7
  opt :html, "Output an HTML file", :default => false
  opt :outfile, "Output image file", :type => :string
end

opts[:download] = !opts[:no_download]
opts[:outfile] ||= "#{opts[:id]}.jpg"

steam_url = steam_url_base + opts[:id] + steam_url_games

response = HTTParty.get(steam_url)

json_games = nil

games_list = response.body.split('\n')
games_list.each do |line|
  if line=~/var rgGames = (.*);/
     json_games = line.match(/var rgGames = (.*);/).captures[0]
  end 
end

gamehash = JSON.parse(json_games)

gamehash.each_slice(opts[:width]) do |batch|
  batch.each do |item|
    puts "<img src='#{item['logo']}'>"
  end
  puts "<br />"
end

image = Magick::ImageList.new
gamehash.each do |game|
    if opts[:download]
      if File.exists?("images/#{File.basename(game["logo"])}")
        puts " -- [S] #{game["name"]} - #{File.basename(game["logo"])} exists, skipping."
      else
        puts " -- [D] #{game["name"]} - #{File.basename(game["logo"])}"
        rio("images/#{File.basename(game["logo"])}") < rio(game["logo"]) unless opts[:no_download]
      end
    else
      puts "-- [S] #{game["name"]} - #{File.basename(game["logo"])} --no-download"
    end
    
   image.read("images/#{File.basename(game['logo'])}")
end

rows = gamehash.count / opts[:width]
rows = rows.to_i
rows = rows + 1

coimage = image.montage { 
  self.background_color = "black"
  self.border_width = 0
  self.tile = Magick::Geometry.new(7,rows)
  self.geometry = '184x69+0+0'
}

coimage.write(opts[:outfile])
