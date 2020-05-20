# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'colorize'

# Provides a way to update iOS Assets with new ones
class IOSAssetUpdater
  # Copies image files (.jpg, .png) from a source, and update corresponding
  # assets in an iOS project folder.
  # Names have to match exactly for the update to take place, but the file
  # extensions can be different.
  # If necessary, Contents.json is updated to reflect the changes.
  # Params:
  # +source+:: Source folder containing images
  # +destination+:: Destination folder, tipically an iOS project
  def self.update(source, destination)
    if source.empty? || destination.empty?
      log('You must provide source and destination folders'.light_red)
      return
    end

    log("Searching image assets (png,jpg) in #{source}".light_blue)

    source_files = Dir["#{source}/**/*.{jpg,png}"]
    destination_files = Dir["#{destination}/**/*.{jpg,png}"]

    not_found = []

    source_files.each do |source_file_path|
      search_file_extension = File.extname(source_file_path)
      search_file_name = File.basename(source_file_path, search_file_extension)

      destination_file_path = find_path(search_file_name, destination_files)

      if destination_file_path.nil? || destination_file_path.empty?
        not_found.push(source_file_path)
        next
      end

      log_separator

      log("#{'Copying ->'.light_green} #{source_file_path}")

      destination_folder = File.dirname(destination_file_path)

      FileUtils.cp(source_file_path, destination_folder)

      source_file_basename = File.basename(source_file_path)
      destination_file_basename = File.basename(destination_file_path)

      if extension_equal?(source_file_basename, destination_file_basename)
        log("#{'File extensions are equal ->'.light_green} "\
          'No need for updating Contents.json')
        next
      end

      log('File extensions are different. Updating Contents.json'.light_green)

      contents_json_file_path = "#{destination_folder}/Contents.json"
      contents_json_file = File.read(contents_json_file_path)
      contents_json = JSON.parse(contents_json_file)

      image_json = contents_json['images'].find do |content|
        content['filename'].match(search_file_name)
      end
      image_json['filename'] = File.basename(source_file_path)

      File.open(contents_json_file_path, 'w') do |f|
        f.write(JSON.pretty_generate(contents_json))
      end

      File.delete(destination_file_path)

      log("Deleted outdated file -> #{destination_file_path}".light_red)
    end

    log_not_found(not_found)
  end

  def self.find_path(search_file_name, destination_files)
    destination_files.find do |file|
      file.include?("#{search_file_name}.jpg") ||
        file.include?("#{search_file_name}.png")
    end
  end

  def self.extension_equal?(source_file_path, destination_file_path)
    source_file_path_basename = File.basename(source_file_path)
    destination_file_path_basename = File.basename(destination_file_path)

    source_file_path_basename.eql?(destination_file_path_basename)
  end

  def self.log_not_found(not_found)
    return if not_found.nil? || not_found.empty?

    log("The following #{not_found.length} files were not found:".yellow)
    not_found.each do |not_found_path|
      log("▸ #{not_found_path}")
    end
  end

  def self.log_separator
    log('---'.cyan)
  end

  def self.log(msg)
    time = Time.new
    prefix = "[#{time.strftime('%H:%M:%S')}]: "
    puts("#{prefix}#{msg}")
  end
end
