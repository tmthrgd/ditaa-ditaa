require "fileutils"
require "tempfile"
require "digest/sha1"

module Ditaa
	class DitaaDiagram
		Defaults = {
			:antialias => true,
			:debug => false,
			:separation => true,
			:encoding => "utf-8",
			:round => false,
			:scale => 1.0,
			:shadows => true,
			:tabs => 8,
			:verbose => false
		}.freeze
		
		Flags = %w[antialias debug separation round shadows verbose].freeze
		FloatOptions = %w[scale].freeze
		IntegerOptions = %w[tabs].freeze
		StringOptions = %w[encoding].freeze
		
		NumberOptions = (FloatOptions + IntegerOptions).freeze
		ValueOptions = (NumberOptions + StringOptions).freeze
		Options = (Flags + ValueOptions).freeze
		
		FloatOptions.each { |key| define_method(key) { @options[key.to_sym].to_f } }
		IntegerOptions.each { |key| define_method(key) { @options[key.to_sym].to_i } }
		(Options - NumberOptions).each { |key| define_method(key) { @options[key.to_sym] } }
		
		attr_reader :site
		
		attr_accessor :content
		alias_method :source, :content
		
		# relative_destination MUST be to be overridden by a subclass
		# or set before write is called
		attr_accessor :relative_destination
		alias_method :url, :relative_destination
		
		# This is included to satisfy:
		# https://github.com/jekyll/jekyll/blob/c4a2ac2c4bfc4952ac73f4f69722718c2ec0c744/lib/jekyll/site.rb#L351
		# In reality DitaaDiagramTag has no meaningful path but DitaaDiagramPage does
		attr_reader :relative_path, :path
		
		def initialize site, options = { }
			unless system "which ditaa >/dev/null 2>&1"
				STDERR.puts "You are missing an executable required for jekyll-ditaa. Please run:"
				STDERR.puts " $ [sudo] apt-get install ditaa"
				raise Errors::FatalException.new "Missing dependency: ditaa"
			end
			
			@site, @options = site, options.dup
			
			merge_site_options
			
			@options.merge!(self.class::Defaults) { |_, option, _| option }
			@options.keep_if { |key, _| self.class::Options.include? key.to_s }
		end
		
		def imgtag
			%(<img src="#{url}" />)
		end
		alias_method :output, :imgtag
		
		def destination dest
			File.join *[dest, relative_destination].compact
		end
		
		def output_ext
			File.extname relative_destination
		end
		
		def write?
			true
		end
		
		def write dest
			dest_path = destination dest
			
			FileUtils.mkdir_p File.dirname dest_path
			
			Tempfile.open("ditaa", encoding: encoding) do |tmp|
				tmp.write source
				tmp.close
				
				IO.popen ["ditaa", *ditaa_arguments, tmp.path, dest_path] { |out| puts out.read nil if debug || verbose }
			end
			
			File.exist? dest_path
		end
		
		def to_s
			content || ""
		end
		
		def to_liquid
			{
				"url" => url,
				
				"content" => content,
				"output" => output,
				
				"ditaa" => Jekyll::Utils.stringify_hash_keys(@options)
			}
		end
		
		def merge_site_options
			unless site.config["ditaa"].nil?
				@options.merge!(Jekyll::Utils.symbolize_hash_keys site.config["ditaa"]) { |_, option, _| option }
			end
			
			@options[:encoding] ||= site.config["encoding"]
			
			# Legacy: config option
			if @options[:debug].nil? && !site.config["ditaa_debug_mode"].nil?
				@options[:debug] = site.config["ditaa_debug_mode"].to_s.eql? "true"
			end
		end
		private :merge_site_options
		
		def ditaa_arguments
			args = [ ]
			
			args << "-v" if verbose
			args << "-A" unless antialias
			args << "-d" if debug
			args << "-E" unless separation
			args << "-e" << encoding if encoding
			args << "-r" if round
			args << "-s" << scale.to_s if scale && !scale.eql?(1.0)
			args << "-S" unless shadows
			args << "-t" << tabs.to_s if tabs && !tabs.eql?(8)
			args << "-o"
			
			args
		end
		private :ditaa_arguments
	end
	
	class PageDitaaDiagram < DitaaDiagram
		def initialize site, page
			@page = page
			
			unless @page.data["ditaa"].nil?
				options = Jekyll::Utils.symbolize_hash_keys @page.data["ditaa"]
			end
			
			super site, options || { }
		end
		
		%w[content relative_path path url].each do |key|
			define_method(key) { @page.send key }
		end
		
		undef_method :content=
		alias_method :source, :content
		
		def relative_destination
			return @page.destination "" if @page.permalink
			File.join @page.dir, "#{@page.basename}#{output_ext}"
		end
		undef_method :relative_destination=
		
		def destination dest
			@page.permalink ? @page.destination(dest) : super
		end
		
		def output_ext
			@page.permalink ? @page.output_ext : ".png"
		end
		
		def mtime
			File.stat(path).mtime.to_i
		end
		
		def write dest
			dest_path = destination dest
			File.exist?(dest_path) && mtime < File.stat(dest_path).mtime.to_i ? false : super
		end
		
		def to_liquid
			@page.to_liquid.merge super
		end
	end
	
	class TagDitaaDiagram < DitaaDiagram
		Defaults = DitaaDiagram::Defaults.merge({
			:dirname => "/images/ditaa",
			:name => "ditaa-%{hash}.png"
		}).freeze
		
		StringOptions = (%w[dirname name] + DitaaDiagram::StringOptions).freeze
		
		ValueOptions = (NumberOptions + StringOptions).freeze
		Options = (Flags + ValueOptions).freeze
		
		undef_method :content=
		
		def initialize site, content, options = { }
			@content = content
			
			super site, options
		end
		
		def source
			source = content.dup
			
			source.gsub! '\n', "\n"
			source.gsub! /^$\n/, ""
			source.gsub! /^\[\"\n/, ""
			source.gsub! /\"\]$/, ""
			source.gsub! /\\\\/, "\\"
			
			source
		end
		
		def hash
			@hash ||= Digest::SHA1.hexdigest "#{content}#{ditaa_arguments * " "}"
		end
		
		def dir
			@options[:dirname] % { :hash => hash }
		end
		
		def name
			@options[:name] % { :hash => hash }
		end
		
		def relative_destination
			File.join *[dir, name].compact
		end
		undef_method :relative_destination=
		alias_method :url, :relative_destination
		
		def write dest
			dest_path = destination dest
			File.exist?(dest_path) && dest_path.include?(hash) ? false : super
		end
		
		def merge_site_options
			super
			
			# Legacy: config option
			unless site.config["ditaa_output_directory"].nil?
				@options[:dirname] ||= site.config["ditaa_output_directory"]
			end
		end
		private :merge_site_options
	end
end

module Jekyll
	# Unfortunately Converter doesn't work here as we can't return a string
	# nor are we actually responsible for writing the file
	class DitaaGenerator < Generator
		priority :highest
		
		def generate site
			site.pages -= pages = site.pages.select { |page| page.ext.casecmp(".ditaa").zero? }
			site.static_files.push *pages.map { |page| Ditaa::PageDitaaDiagram.new site, page }
		end
	end
	
	class Tags::DitaaBlock < Liquid::Block
		def initialize tag_name, markup, tokens
			super
			
			@attributes = parse_attributes markup
		end
		
		def render context
			site = context.registers[:site]
			
			# Unforunately this will not be included in the site_payload that
			# is avaliable to liquid because site_payload is evaluated long
			# before this diagram is added
			site.static_files << diagram = Ditaa::TagDitaaDiagram.new(site, super, @attributes)
			
			case @attributes[:return] && @attributes[:return].downcase
			when "uri", "url", "href" then diagram.url
			else diagram.imgtag
			end
		end
		
		def parse_attributes markup
			# Legacy: Command-line (style) parsing
			begin
				require "trollop"
				
				attributes = Trollop::Parser.new do
					opt :verbose, nil, { :long => "verbose", :short => "v" }
					opt :antialias, nil, { :default => true, :long => "no-antialias", :short => "A" }
					opt :debug, nil, { :long => "debug", :short => "d" }
					opt :separation, nil, { :default => true, :long => "no-separation", :short => "E" }
					opt :encoding, nil, { :type => :string, :long => "encoding", :short => "e" }
					opt :round, nil, { :long => "round-corners", :short => "r" }
					opt :scale, nil, { :type => :float, :long => "scale", :short => "s" }
					opt :shadows, nil, { :default => true, :long => "no-shadows", :short => "S" }
					opt :tabs, nil, { :type => :integer, :long => "tabs", :short => "t" }
				end.parse markup.split " "
				
				attributes.keep_if { |key, _| attributes.has_key? :"#{key}_given" }
			rescue LoadError
				if markup =~ /(?<=\s|^)(?:-\w|--\w+)(?=\s|$)/
					STDERR.puts "You are missing an executable required for command-line parsing in jekyll-ditaa. Please run:"
					STDERR.puts " $ [sudo] gem install trollop"
				end
			rescue Trollop::CommandlineError => err
				STDERR.puts "Command-line parsing error: #{err.message}"
				STDERR.puts "Command-line arguments will be ignored."
			rescue Trollop::VersionNeeded, Trollop::HelpNeeded
			end
			
			attributes ||= { }
			
			# boolean key|no-key options
			attributes.merge! Hash[markup.scan(/(?<=\s|^)(no-)?(\w+)(?=\s|$)/i).map { |falsey, key| [key.to_sym, !falsey] }]
			
			# key:value options
			attributes.merge! Hash[markup.scan(Liquid::TagAttributes).map { |key, value| [key.to_sym, value] }]
			
			attributes
		end
		private :parse_attributes
	end
end

Liquid::Template.register_tag "ditaa", Jekyll::Tags::DitaaBlock

# Kramdown codeblock support
begin
	require "kramdown"
	
	class Jekyll::Site
		# Markdown support is added with a converter, by adding site here
		# we guarantee it will be available to Kramdown::Converter::Html
		alias_method :super_converters, :converters
		def converters
			@has_patched ||= begin
				config["kramdown"] ||= { }
				config["kramdown"][:__site__] = self
				
				true
			end
			
			super_converters
		end
	end
	
	class Kramdown::Converter::Html
		alias_method :super_convert_codeblock, :convert_codeblock
		def convert_codeblock el, indent
			attr = el.attr.dup
			klass = attr["class"]
			
			unless attr.delete "ditaa"
				unless klass && klass.gsub!(/(?<=\s|^)(?:language-)?ditaa(?=\s|$)/i, "")
					return super_convert_codeblock el, indent
				end
				
				attr.delete "class" if klass.to_s.empty?
			end
			
			site = @options[:__site__]
			
			arguments = { }
			
			unless klass.to_s.empty?
				# Class attribute boolean key|no-key options
				flags = Hash[klass.scan(/(?<=\s|^)(no-)?(\w+)(?=\s|$)/i).map { |falsey, key| [key.to_sym, !falsey] }]
				flags.keep_if { |key, _| Ditaa::TagDitaaDiagram::Flags.include? key }
				flags.each_key { |key| klass.gsub! /(?:\s|^)(no-)?#{Regexp.escape key}(?:\s|$)/i, "" }
				arguments.replace flags
				
				attr.delete "class" if flags.length.nonzero? && klass.empty?
			end
			
			# IAL flags
			arguments.merge! Hash[Ditaa::TagDitaaDiagram::Flags.map do |key|
				[key.to_sym,
					case attr.delete key
					when /^(?:true|1|#{Regexp.escape key})$/i then true
					when /^(?:false|0)$/i then false
					else next
					end
				]
			end]
			
			# IAL options
			arguments.merge! Hash[Ditaa::TagDitaaDiagram::ValueOptions.map { |key| [key.to_sym, attr.delete(key) || next] }]
			
			# Unforunately this will not be included in the site_payload that
			# is avaliable to liquid because site_payload is evaluated long
			# before this diagram is added
			site.static_files << diagram = Ditaa::TagDitaaDiagram.new(site, el.value, arguments)
			
			attr["src"] = diagram.url
			"#{" " * indent}<img#{html_attributes attr} />\n"
		end
	end
rescue LoadError
end