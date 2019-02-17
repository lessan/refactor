require 'active_support/core_ext/string/inflections'
require 'fileutils'

require_relative 'refactor/version'

module Refactor
  def self.highlight_changes(path, text, regex)
    line_num = 0
    text.each_line do |old_line|
      new_line = old_line.gsub(regex, "\e[33m\\0\e[0m")
      unless new_line == old_line
        puts "\e[36m#{path}:#{line_num}\e[0m #{new_line}"
      end
      line_num += 1
    end
  end

  def self.run(from, to)
    from_camelized = from.camelize
    from_dashed = from.dasherize
    from_humanized = from.humanize
    from_underscored = from.underscore
    to_camelized = to.camelize
    to_dashed = to.dasherize
    to_humanized = to.humanize
    to_underscored = to.underscore

    camelized_regex = /(?<=\b|_)#{Regexp.quote(from_camelized)}(?=\b|_)/
    dashed_regex = /(?<=\b|_)#{Regexp.quote(from_dashed)}(?=\b|_)/
    underscored_regex = /(?<=\b|_)#{Regexp.quote(from_underscored)}(?=\b|_)/
    humanized_regex = /#{Regexp.quote(from_humanized)}/i
    # TODO handle TitleCase

    # all files in current directory
    paths = Dir.glob('**/*')

    # ignore certain directories
    paths.reject! { |p| p =~ %r{\A(coverage|pkg|tmp|vendor)(\z|/)} }

    # do folders last, so the contents of files within each folder are also addressed
    paths = paths.partition { |p| File.file?(p) }.reduce(:+)

    paths.each do |old_path|

      # only check the basename so that the directory doesn't get renamed twice
      old_basename = File.basename(old_path)
      new_basename = old_basename.dup
      new_basename.gsub!(dashed_regex, to_dashed)
      new_basename.gsub!(underscored_regex, to_underscored)

      if new_basename == old_basename
        # no change
        new_path = old_path
      else
        # rename file
        new_path = File.join(File.dirname(old_path), new_basename)
        puts "#{old_path} –> #{new_path}"
        FileUtils.mv(old_path, new_path)
      end

      if File.file?(new_path)
        # replace within file
        old_text = File.read(new_path)
        # http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
        old_text.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

        new_text = old_text.dup
        highlight_changes(new_path, new_text, camelized_regex)
        new_text.gsub!(camelized_regex, to_camelized)
        highlight_changes(new_path, new_text, dashed_regex)
        new_text.gsub!(dashed_regex, to_dashed)
        highlight_changes(new_path, new_text, underscored_regex)
        new_text.gsub!(underscored_regex, to_underscored)
        highlight_changes(new_path, new_text, humanized_regex)
        new_text.gsub!(humanized_regex, to_humanized)

        unless new_text == old_text
          # rewrite existing file
          File.write(new_path, new_text)
        end
      end
    end
  end
end
