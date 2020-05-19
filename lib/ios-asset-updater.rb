require 'fileutils'
require 'json'
require 'colorize'

class IOSAssetUpdater
	def self.update(source, destination)
		if source.empty? or destination.empty?
			log("You must provide source and destination folders".light_red)
			return
		end

		log("Searching image assets (png,jpg) in #{source}".light_blue)

		source_files = Dir["#{source}/**/*.{jpg,png}"]
		destination_files = Dir["#{destination}/**/*.{jpg,png}"]

		not_found = []

		source_files.each do |source_file_path|
			search_file_name = File.basename(source_file_path, File.extname(source_file_path))

			destination_file_path = destination_files.find { |file|
				file.include?("#{search_file_name}.jpg") or file.include?("#{search_file_name}.png")
			}

			if destination_file_path.nil? or destination_file_path.empty?
				not_found.push(source_file_path)
				next
			end

			logSeparator()

			log("#{"Copying ->".light_green} #{source_file_path}")

			destination_folder = File.dirname(destination_file_path)

			FileUtils.cp(source_file_path, destination_folder)

			source_file_path_basename = File.basename(source_file_path)
			destination_file_path_basename = File.basename(destination_file_path)

			if source_file_path_basename.eql?(destination_file_path_basename)
				log("#{"File extensions are equal ->".light_green} No need for updating Contents.json")
				next
			end

			log("File extensions are different. Updating Contents.json".light_green)

			contents_json_file_path = "#{destination_folder}/Contents.json"
			contents_json_file = File.read(contents_json_file_path)
			contents_json = JSON.parse(contents_json_file)

			image_json = contents_json["images"].find { |content| content["filename"].match(search_file_name) }
			image_json["filename"] = File.basename(source_file_path)

			File.open(contents_json_file_path, "w") do |f|
			    f.write(JSON.pretty_generate(contents_json))
			end

			File.delete(destination_file_path)

			log("Deleted outdated file -> #{destination_file_path}".light_red)
		end

		return if not_found.nil? or not_found.empty?

		log("The following #{not_found.length} files were not found:".yellow)
		not_found.each do |not_found_path|
			log("▸ #{not_found_path}")
		end
	end

	def self.logSeparator
		log("---".cyan)
	end

	def self.log(msg)
		time = Time.new
		prefix = "[#{time.strftime("%H:%M:%S")}]: "
		puts("#{prefix}#{msg}")
	end
end