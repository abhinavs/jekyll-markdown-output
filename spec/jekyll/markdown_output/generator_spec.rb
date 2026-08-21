# frozen_string_literal: true

RSpec.describe Jekyll::MarkdownOutput do
  describe ".config_for" do
    it "returns defaults when no markdown_output key is set" do
      site = instance_double(Jekyll::Site, config: {})
      config = described_class.config_for(site)
      expect(config["enabled"]).to eq(true)
      expect(config["collections"]).to eq(["posts"])
      expect(config["pages"]).to eq(true)
      expect(config["page_extensions"]).to eq([".md", ".markdown"])
      expect(config["html_to_markdown"]).to eq(false)
      expect(config["extension"]).to eq(".md")
      expect(config["include_title_heading"]).to eq(true)
    end

    it "merges user overrides on top of defaults" do
      site = instance_double(Jekyll::Site, config: {
        "markdown_output" => {
          "enabled"          => false,
          "collections"      => %w[notes],
          "frontmatter_keys" => %w[title url],
        },
      })
      config = described_class.config_for(site)
      expect(config["enabled"]).to eq(false)
      expect(config["collections"]).to eq(%w[notes])
      expect(config["frontmatter_keys"]).to eq(%w[title url])
      # Untouched keys keep defaults.
      expect(config["pages"]).to eq(true)
    end
  end
end
