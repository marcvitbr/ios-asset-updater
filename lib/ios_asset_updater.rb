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
      return false
    end

    log("Searching image assets (png,jpg) in #{source}".light_blue)

    source_files = files_in_dir(source)
    source_hash = create_hash(source_files)

    destination_files = files_in_dir(destination)
    destination_hash = create_hash(destination_files)

    not_found = []

    source_files.each do |source_file_path|
      source_file = source_hash[source_file_path]

      destination_file_path = find_path(source_file[:name], destination_files)

      if destination_file_path.nil? || destination_file_path.empty?
        not_found.push(source_file_path)
        next
      end

      destination_file = destination_hash[destination_file_path]

      copy(source_file_path, destination_file[:dir])

      if extension_equal?(source_file[:basename], destination_file[:basename])
        log("#{'File extensions are equal ->'.light_green} "\
          'No need for updating Contents.json')
        next
      end

      update_contents_json(source_file, destination_file)

      delete(destination_file_path)
    end

    log_not_found(not_found)

    return true
  end

  def self.files_in_dir(dir)
    Dir["#{dir}/**/*.{jpg,png}"]
  end

  def self.create_hash(files)
    new_hash = {}
    files.each do |file|
      properties = {}
      properties[:extension] = File.extname(file)
      properties[:basename] = File.basename(file)
      properties[:name] = File.basename(file, properties[:extension])
      properties[:dir] = File.dirname(file)
      properties[:contents_path] = "#{properties[:dir]}/Contents.json"

      new_hash[file] = properties
    end
    new_hash
  end

  def self.find_path(search_file_name, destination_files)
    destination_files.find do |file|
      file.include?("#{search_file_name}.jpg") ||
        file.include?("#{search_file_name}.png")
    end
  end

  def self.copy(source, destination)
    log_separator
    log("#{'Copying ->'.light_green} #{source}")
    FileUtils.cp(source, destination)
  end

  def self.extension_equal?(source_file_path, destination_file_path)
    source_file_path_basename = File.basename(source_file_path)
    destination_file_path_basename = File.basename(destination_file_path)

    source_file_path_basename.eql?(destination_file_path_basename)
  end

  def self.update_contents_json(source_file, destination_file)
    log('File extensions are different. Updating Contents.json'.light_green)

    contents_json_file = File.read(destination_file[:contents_path])
    contents_json = JSON.parse(contents_json_file)

    image_json = contents_json['images'].find do |content|
      content['filename'].match(destination_file[:basename])
    end

    image_json['filename'] = source_file[:basename]

    File.open(destination_file[:contents_path], 'w') do |f|
      f.write(JSON.pretty_generate(contents_json))
    end
  end

  def self.delete(path)
    File.delete(path)
    log("Deleted outdated file -> #{path}".light_red)
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
