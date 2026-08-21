# frozen_string_literal: true

require "fileutils"

module Jekyll
  module MarkdownOutput
    DEFAULTS = {
      "enabled"               => true,
      "collections"           => ["posts"],
      "pages"                 => true,
      "page_extensions"       => [".md", ".markdown"],
      "html_to_markdown"      => false,
      "html_to_markdown_options" => MarkdownPage::DEFAULT_HTML_TO_MARKDOWN_OPTIONS,
      "extension"             => ".md",
      "include_title_heading" => true,
      "frontmatter_keys"      => MarkdownPage::DEFAULT_FRONTMATTER_KEYS,
    }.freeze

    def self.config_for(site)
      overrides = site.config["markdown_output"] || {}
      config = DEFAULTS.merge(overrides)
      config["html_to_markdown_options"] = DEFAULTS["html_to_markdown_options"].merge(
        overrides["html_to_markdown_options"] || {}
      )
      config
    end

    def self.write_all(site)
      config = config_for(site)
      return unless config["enabled"]

      written = 0

      Array(config["collections"]).each do |coll_name|
        collection = site.collections[coll_name.to_s]
        unless collection
          Jekyll.logger.warn("MarkdownOutput:", "collection '#{coll_name}' not found, skipping")
          next
        end
        collection.docs.each { |doc| written += 1 if write_one(site, doc, config) }
      end

      if config["pages"]
        exts = Array(config["page_extensions"]).map(&:downcase)
        exts.concat(%w[.html .htm]) if config["html_to_markdown"]
        site.pages.each do |page|
          next unless exts.include?(File.extname(page.path).downcase)
          written += 1 if write_one(site, page, config)
        end
      end

      Jekyll.logger.info("MarkdownOutput:", "wrote #{written} markdown file(s)")
    end

    def self.write_one(site, source, config)
      return false if source.data["markdown_output"] == false

      page = MarkdownPage.new(site, source, config)
      return false unless page.source_file?

      path = page.destination
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, page.to_s)
      true
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::MarkdownOutput.write_all(site)
end
