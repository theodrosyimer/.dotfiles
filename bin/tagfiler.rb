#!/usr/bin/env ruby
# encoding: utf-8
# tag primary folders =Tagname
# target them with #Tagname
# tag subfolders with @nickname
# target them with :nickname
# if no tagged folder exists but there's a matching folder name, that's used
# otherwise it will create folders based on :tags
# :tags can be strung together :bt:Drafts:testing for nesting
# Only one #Tag and one :path should exist in a file's tags

require 'logger'
require 'fileutils'

logtarget = File.expand_path('~/tagfiler')
unless File.exists?(logtarget)
	FileUtils.mkdir_p(logtarget)
else
	unless File.directory?(logtarget)
		STDERR.puts "~/tagfiler log folder is unable to be created."
		raise "Error creating ~/tagfiler"
	end
end
log = Logger.new(File.expand_path('~/tagfiler/TagFiler.log'),10,1024000)

file_path = ARGV[0] || nil

if file_path.nil?
	puts "Usage: #{__FILE__} file"
	puts "Tag ~/Dropbox/Writing with =Writing"
	puts "Tag the folder ~/Dropbox/Writing/myblog with @myblog"
	puts "Tag ~/Desktop/blogpost.txt with #Writing and :myblog"
	puts "Run: #{File.basename(__FILE__)} ~/Desktop/blogpost.txt"
	puts
	targets= %x{mdfind 'kMDItemUserTags == "=*"' -0 | xargs -L1 -0 mdls -raw -name kMDItemUserTags | grep "=" | tr -d '."' | sed 's/^ *//'}.split("\n")
	puts "Primary targets available: " + targets.map{|t| t.sub(/^=/,'#')}.join(", ")
	exit 1
end

target = false

tags = %x{mdls -name 'kMDItemUserTags' -raw "#{file_path}"|tr -d "()\n"}.split(',').map {|tag| tag.strip.gsub(/"(.*?)"/,"\\1")}

primary_tag = nil
tags.each {|tag|
	if tag =~ /^#/
		primary_tag = tag.gsub(/^#/,"=")
		break
	end
}
if primary_tag.nil?
	log.info("Error: No primary tag found for #{file_path}")
	raise "No primary tag found for #{file_path}"
	exit
end
primary_target = %x{mdfind "((kMDItemUserTags == '#{primary_tag}'cd) && (kMDItemContentTypeTree == 'public.folder'))"|awk 'NR>1{exit};1'}.strip

if primary_target == ""
	log.info("Error: No target found for #{primary_tag} on #{file_path}")
	raise "No target found for #{primary_tag} on #{file_path}"
	exit
end

good_tags = tags.delete_if {|tag| tag =~ /^[^:]/ }
if good_tags.empty?
	log.info("Error: No :tags found for #{file_path}")
else

	good_tags.each {|tag|

		found_target = %x{mdfind -onlyin "#{primary_target}" "((kMDItemUserTags == '#{tag.sub(/^:/,"@")}'cd) && (kMDItemContentTypeTree == 'public.folder'))"|awk 'NR>1{exit};1'}.strip
		if File.directory?(found_target)
			primary_target = found_target
			break
		else
			tag_parts = tag.scan(/(:[^:]+)/)

			tag_parts.each {|tag|

				root = tag[0].to_s.sub(/^:/,"@")
				puts "Scanning for #{root} in #{primary_target}"
				sub_target = %x{mdfind -onlyin "#{primary_target}" "((kMDItemUserTags == '#{root}'cd) && (kMDItemContentTypeTree == 'public.folder'))"|awk 'NR>1{exit};1'}.strip

				if sub_target == ""
					puts "No subtarget found, scanning #{primary_target} for directory matches"
					found = false
					Dir.glob(File.join(primary_target,"*")).each do |f|
						if f =~ /#{root.sub(/^@/,'')}/i and File.directory?(f)
							puts "found matching folder #{f}"
							primary_target = f
							found = true
						end
					end

					unless found
						new_dir = File.join(primary_target, root.sub(/^@/,''))
						puts "#{root} not found, creating #{new_dir}"
						unless File.exists?(new_dir)
							FileUtils.mkdir_p(new_dir)
							%x{xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><array><string>#{root}</string></array></plist>' "#{new_dir}"}
							puts "Created #{new_dir}, now primary target"
							primary_target = new_dir
						else
							unless File.directory?(new_dir)
								log.error("#{primary_target} already exists and is not a directory")
								Process.exit 1
							end
						end
					end
				else
					puts "Found #{sub_target}"
					primary_target = sub_target
					next
				end

			} if tag_parts[0].length > 0

		end
	}
end
target_file = File.join(primary_target,File.basename(file_path))
"Preparing to move #{file_path} to #{target_file}"
while File.exists?(target_file)
	filename = File.basename(target_file,File.extname(target_file))
	filename += "_00" unless filename =~ /_\d{2,}$/
	target_file = File.join(primary_target,filename.next + File.extname(target_file))
end
if primary_target
	%x{/bin/mv "#{file_path}" "#{target_file}"}
	out = "#{file_path} => #{target_file}"
	log.info(out)
	puts out
else
	log.error("Error filing #{file_path}")
	raise "Error filing #{file_path}"
end
