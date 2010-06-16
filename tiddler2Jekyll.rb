require 'tiddler'


require 'cgi'
require 'open-uri'
require 'time'
require 'date'
require 'date/format'

class Tiddler2Jekyll < Tiddler
	
	public 
	def created
		y = @created[0..3]
		m = @created[4..5]
		d = @created[6..7]
		y + "-" + m + "-" + d + "-"
	end
	def to_div(subtype="tiddler",escapeHTML=true,compress=false)
		optimizeAttributeStorage = true if(subtype == "shadow")
		@usePre = true if(subtype == "shadow" && @@format =~ /preshadow/)
		@usePre = true if(subtype == "tiddler" && @@format =~ /pretiddler/)
		#out = "<div "
		out = "---\n"
		out << "layout: post\n"
		out <<  "title: \"#{@title}\"\n" 
		out << "modifier: \"#{@modifier}\"\n" if(@modifier)
		if(@usePre || optimizeAttributeStorage)
			out << "created: \"#{@created}\"\n" if(@created)
			out << "modified: \"#{@modified}\"\n" if(@modified && @modified != @created)
			out << "tags: [#{@tags.split.to_a.join(", ")}]\n" if(@tags)
		else
			out << "modified: \"#{@modified}\"\n" if(@modified)
			out << "created: \"#{@created}\"\n" if(@created)
			out << "tags: [#{@tags.split.to_a.join(", ")}]\n"
		end
		@extendedAttributes.each_pair { |key, value| out << "#{key}: \"#{value}\"\n" }
		out << "---\n"
		if(@usePre)
			out << "\n"
			lines = @contents
			lines = Ingredient.rhino(lines) if compress
			if(escapeHTML)
				lines = CGI::escapeHTML(lines)
			end
			lines = (lines.gsub("\r", "")).split("\n")
			last = lines.pop
			lines.each { |line| out << line << "\n" }
			out << last if(last)
			out << "\n"
		else
			@contents.each { |line| out << CGI::escapeHTML(line).gsub("\\", "\\s").sub("\n", "\\n").sub("\r", "") }
		end
		#out << "</div>\n"
	end
end