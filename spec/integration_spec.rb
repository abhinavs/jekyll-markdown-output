# frozen_string_literal: true

RSpec.describe "Jekyll site build with jekyll-markdown-output" do
  let(:built) { build_site }
  let(:site) { built[0] }
  let(:dest) { built[1] }

  after { FileUtils.rm_rf(dest) }

  it "writes a .md sibling for each non-opted-out post" do
    expect(dest.join("greetings/2024/01/01/hello.md")).to exist
    expect(dest.join("2024/02/02/with-liquid.md")).to exist
    expect(dest.join("2024/04/04/no-liquid.md")).to exist
  end

  it "skips posts that opt out via markdown_output: false" do
    expect(dest.join("2024/03/03/opted-out.md")).not_to exist
    # The HTML version still exists - we only suppress the .md twin.
    expect(dest.join("2024/03/03/opted-out.html")).to exist
  end

  it "writes a .md sibling for Markdown-sourced pages" do
    expect(dest.join("index.md")).to exist
    expect(dest.join("about/index.md")).to exist
  end

  it "does not mirror HTML-sourced pages" do
    expect(dest.join("contact.html")).to exist
    expect(dest.join("contact.md")).not_to exist
    expect(dest.join("terms.htm")).to exist
    expect(dest.join("terms.md")).not_to exist
  end

  it "renders Liquid in the body by default" do
    full = read_dest(dest, "2024/02/02/with-liquid.md")
    body = full.split(/^---\s*$/, 3)[2]
    expect(body).to include("Site URL is https://example.com.")
    expect(body).not_to include("{{ site.url }}")
  end

  it "honors render_with_liquid: false in document frontmatter" do
    full = read_dest(dest, "2024/04/04/no-liquid.md")
    body = full.split(/^---\s*$/, 3)[2]
    expect(body).to include("Raw {{ site.url }} should not be substituted.")
  end

  it "emits clean YAML frontmatter (no Ruby object graphs)" do
    %w[
      greetings/2024/01/01/hello.md
      2024/02/02/with-liquid.md
      2024/04/04/no-liquid.md
      about/index.md
      index.md
    ].each do |rel|
      body = read_dest(dest, rel)
      expect(body).not_to include("!ruby/object"), "#{rel} contained a Ruby object graph"
      expect(body).not_to include("&1"),            "#{rel} contained YAML anchors"
    end
  end

  it "includes expected frontmatter keys for posts" do
    body = read_dest(dest, "greetings/2024/01/01/hello.md")
    fm = YAML.safe_load(body.split(/^---\s*$/, 3)[1], permitted_classes: [Date, Time, Symbol])
    expect(fm).to include(
      "title"    => "Hello World",
      "url"      => "https://example.com/greetings/2024/01/01/hello.html",
      "summary"  => "A first post.",
      "tags"     => %w[intro test],
      "category" => "greetings",
      "author"   => "Test Author",
    )
    expect(fm["date"]).to be_a(String)
    expect(fm["date"]).to match(/\A2024-01-01T/)
  end

  it "prepends a title heading to the body" do
    body = read_dest(dest, "greetings/2024/01/01/hello.md")
    expect(body).to match(/^# Hello World$/)
  end
end

RSpec.describe "Configuration overrides" do
  it "respects enabled: false" do
    _, dest = build_site("markdown_output" => { "enabled" => false })
    expect(Dir.glob(dest.join("**/*.md"))).to be_empty
  ensure
    FileUtils.rm_rf(dest) if dest
  end

  it "respects pages: false (only collections are mirrored)" do
    _, dest = build_site("markdown_output" => { "enabled" => true, "pages" => false })
    expect(dest.join("greetings/2024/01/01/hello.md")).to exist
    expect(dest.join("about/index.md")).not_to exist
    expect(dest.join("index.md")).not_to exist
  ensure
    FileUtils.rm_rf(dest) if dest
  end

  it "uses a custom extension" do
    _, dest = build_site("markdown_output" => { "enabled" => true, "extension" => ".txt" })
    expect(dest.join("greetings/2024/01/01/hello.txt")).to exist
    expect(dest.join("greetings/2024/01/01/hello.md")).not_to exist
  ensure
    FileUtils.rm_rf(dest) if dest
  end

  it "converts .html and .htm source pages to Markdown when enabled" do
    _, dest = build_site("markdown_output" => { "enabled" => true, "html_to_markdown" => true })

    contact = read_dest(dest, "contact.md")
    expect(contact).to include("This page is **HTML**, not Markdown.")
    expect(contact).to include("[support](https://example.com/support)")
    expect(contact).not_to include("{{ site.url }}")
    expect(contact).not_to include("<p>")
    expect(read_dest(dest, "terms.md")).to include("Terms and **conditions**.")
  ensure
    FileUtils.rm_rf(dest) if dest
  end

  it "narrows frontmatter_keys" do
    _, dest = build_site("markdown_output" => {
      "enabled"          => true,
      "frontmatter_keys" => %w[title url],
    })
    body = File.read(dest.join("greetings/2024/01/01/hello.md"))
    fm = YAML.safe_load(body.split(/^---\s*$/, 3)[1], permitted_classes: [Date, Time, Symbol])
    expect(fm.keys).to contain_exactly("title", "url")
  ensure
    FileUtils.rm_rf(dest) if dest
  end

  it "warns and continues when a configured collection is missing" do
    expect(Jekyll.logger).to receive(:warn).with("MarkdownOutput:", /not found/).at_least(:once).and_call_original
    expect(Jekyll.logger).to receive(:info).at_least(:once).and_call_original
    _, dest = build_site("markdown_output" => {
      "enabled"     => true,
      "collections" => %w[posts nonexistent],
    })
    # Posts still mirror.
    expect(dest.join("greetings/2024/01/01/hello.md")).to exist
  ensure
    FileUtils.rm_rf(dest) if dest
  end
end
