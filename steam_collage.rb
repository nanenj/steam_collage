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


opts[:api_key] ||= ENV['STEAM_WEB_API']
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

image = Magick::ImageList.new
images_skipped, images_cached, images_downloaded = [0, 0, 0]
gamehash.each do |game|
    if opts[:download]
      if File.exists?("images/#{File.basename(game["logo"])}")
        puts " -- [S] #{game["name"]} - #{File.basename(game["logo"])} exists, skipping."
	images_cached = images_cached + 1
      else
        puts " -- [D] #{game["name"]} - #{File.basename(game["logo"])}"
	if opts[:download]
          if rio("images/#{File.basename(game["logo"])}") < rio(game["logo"])
            images_downloaded = images_downloaded + 1
          end
        end
      end
    else
      puts "-- [S] #{game["name"]} - #{File.basename(game["logo"])} --no-download"
      images_skipped = images_skipped + 1
    end
    if opts[:download]
      image.read("images/#{File.basename(game['logo'])}")
    end
end
puts "Operation complete: #{images_cached} cached, #{images_downloaded} downloaded, #{images_skipped} skipped"
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
