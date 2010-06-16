# spliter.rb

# Copyright (c) UnaMesa Association 2004-2008
# License: Creative Commons Attribution ShareAlike 3.0 License http://creativecommons.org/licenses/by-sa/3.0/
require 'splitter'
require 'tiddler2Jekyll'
#require 'iconv'
#require 'open-uri'
#require 'net/http'

class Splitter2Jekyll < Splitter

private
	def writeTiddler(tiddler, recipes)
		dirname = @dirname
		tiddlerFilename = tiddler.created + tiddler.title.to_s.gsub(/[ <>]/,"_").gsub(/\t/,"%09").gsub(/#/,"%23").gsub(/%/,"%25").gsub(/\*/,"%2a").gsub(/,/,"%2c").gsub(/\//,"%2f").gsub(/:/,"%3a").gsub(/</,"%3c").gsub(/>/,"%3e").gsub(/\?/,"%3f")
		#tiddlerFilename = @conv.iconv(tiddlerFilename)
		if(tiddler.tags =~ /systemConfig/)
			dirname = @dirname
			if(@@usesubdirectories)
				dirname = File.join(@dirname, "plugins")
				if(!File.exists?(dirname))
					Dir.mkdir(dirname)
				end
			end
			targetfile = File.join(dirname, tiddlerFilename += ".js")
			File.open(targetfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.contents
			end
			File.open(targetfile + ".meta", File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
				out << tiddler.to_meta
			end
			recipes["plugins"] << "tiddler: #{tiddlerFilename}\n"
		else
			if(tiddler.tags =~ /systemServer/)
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["feeds"], "feeds")
			elsif(tiddler.tags =~ /systemTheme/)
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["themes"], "themes")
			elsif(@@tagsubdirectory && tiddler.tags =~ Regexp.new(@@tagsubdirectory))
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["tags"], @@tagsubdirectory)
			elsif(Tiddler.isShadow?(tiddler.title))
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["shadows"], "shadows")
			else
				writeTiddlerToSubDir(tiddler, tiddlerFilename, recipes["content"], "content")
			end
		end
		recipes["main"] << "tiddler: #{tiddlerFilename}.textile\n"
		if(!@@quiet)
			puts "Writing: #{tiddler.title}"
		end
	end

	def writeTiddlerToSubDir(tiddler, tiddlerFilename, recipe, subdir)
		dirname = @dirname
		if(@@usesubdirectories)
			dirname = File.join(@dirname, subdir)
			if(!File.exists?(dirname))
				Dir.mkdir(dirname)
			end
		end
		targetfile = File.join(dirname, tiddlerFilename += ".textile")
		File.open(targetfile, File::CREAT|File::TRUNC|File::RDWR, 0644) do |out|
			out << tiddler.to_div("tiddler",false)
		end
		recipe << "tiddler: #{tiddlerFilename}\n"
	end

	def readStoreArea(recipes)
		open(@filename) do |file|
			tiddlerCount = 0
			start = false
			line = file.gets
			begin
				line = file.gets
			end while(line && line !~ /<div id="storeArea">/)
			line = line.sub(/.*<div id="storeArea">/, "").strip
			begin
				if(line =~ /<div ti.*/)
					tiddlerCount += 1
					tiddler = Tiddler2Jekyll.new
					line = tiddler.read_div(file,line)
					writeTiddler(tiddler, recipes)
				else
					line = file.gets
				end
			end while(line && line !~ /<!--STORE-AREA-END-->/ && line !~ /<!--POST-BODY-START-->/ && line !~ /<div id="shadowArea">/)
			return tiddlerCount
		end
	end

public
	def Splitter2Jekyll.extractTiddlers(filename,titles)
		out = Array.new
		found = Array.new
		open(filename) do |file|
			start = false
			line = file.gets
			begin
				line = file.gets
			end while(line && line !~ /<div id="storeArea">/)
			line = line.sub(/.*<div id="storeArea">/, "").strip
			begin
				if(line =~ /<div ti.*/)
					tiddler = Tiddler2Jekyll.new
					line = tiddler.read_div(file,line)
					if titles.include?(tiddler.title)
						out.push(tiddler)
						found.push(tiddler.title)
					end
				else
					line = file.gets
				end
			end while(line && line !~ /<!--STORE-AREA-END-->/ && line !~ /<!--POST-BODY-START-->/ && line !~ /<div id="shadowArea">/)
		end
		if out.length == titles.length
			return out
		else
			STDERR.puts("Tiddlers #{(titles-found).to_s} not found in #{filename}")
		end
	end
end
