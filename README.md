# jekyll-markdown-output

A Jekyll plugin that emits a `.md` sibling for every post (or any document in a configured collection), so AI agents, LLM crawlers, and other machine consumers can fetch clean Markdown instead of parsing HTML.

For a post rendered at `/foo`, this plugin also writes `/foo.md` containing:

- a small YAML frontmatter block (title, date, url, summary, tags, category, author)
- the post's source Markdown with Liquid rendered

No HTML conversion. No layout chrome. No nav, footer, theme toggles, or analytics scripts.

### Before / after

```
_site/
  foo.html              <- as before
  foo.md                <- new: clean Markdown, same URL
  posts/
    hello.html
    hello.md
```

Agents fetching `/foo.md` get the source content with a small frontmatter block. Browsers fetching `/foo` get the rendered HTML, untouched.

## Why

Agents that read your site spend tokens parsing HTML and stripping boilerplate. Serving a `.md` twin is the smallest change that gives them the actual content. It is the same pattern used by Anthropic's docs, Stripe, and a growing set of agent-friendly sites.

## Install

Add to your `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-markdown-output"
end
```

Then in `_config.yml`:

```yaml
plugins:
  - jekyll-markdown-output
```

## Configure

Defaults are sensible for a typical blog. Override via `_config.yml`:

```yaml
markdown_output:
  enabled: true                      # set false to disable globally
  collections: [posts]               # which collections to mirror
  pages: true                        # also mirror site.pages
  page_extensions: [.md, .markdown]  # which page sources count as Markdown
  extension: .md                     # output extension
  include_title_heading: true        # prepend "# Title" to body
  frontmatter_keys:                  # which fields to include
    - title
    - date
    - url
    - summary
    - tags
    - category
    - author
```

`pages: true` (the default) emits `.md` for top-level Markdown files such
as `index.md`, `about.md`, `now.md`. HTML-sourced pages are skipped: if
you want a `.md` twin for a page, write it in Markdown.

### Per-document opt-out

Add to a single post's frontmatter to skip it:

```yaml
---
title: Draft thinking
markdown_output: false
---
```

## URL mapping

| Source URL | Generated file |
|---|---|
| `/foo`     | `/foo.md`           |
| `/a/foo`   | `/a/foo.md`         |
| `/foo/`    | `/foo/index.md`     |
| `/`        | `/index.md`         |

## Output shape

```markdown
---
title: Terminal is having a second life
date: '2025-09-12T00:00:00+05:30'
url: https://www.abhinav.co/terminal-second-life
summary: How agentic coding tools have pulled the terminal back to the centre of the developer workflow.
tags:
- Terminal
- Tools
category: technology
author: Abhinav Saxena
---

# Terminal is having a second life

For years the terminal was the place you only opened to run a build...
```

## How it works

The plugin registers a `:site, :post_write` hook that runs after Jekyll has finished its main build. For each document in the configured collections (and each Markdown-sourced page if `pages: true`), it reads the original source from disk, strips the frontmatter, optionally renders Liquid against the document context, and writes a `.md` file directly into `_site/`.

Because output goes through `File.write` rather than Jekyll's renderer, the file never passes through layouts, the Markdown-to-HTML converter, or any other plugin's hooks. The body stays as Markdown; Liquid (`{{ site.url }}`, `{% include %}`) resolves against the live site context.

## Compatibility

- Jekyll 3.7+ and 4.x
- Ruby 2.7+

### GitHub Pages

GitHub Pages restricts Jekyll plugins to a [whitelist](https://pages.github.com/versions/), and `jekyll-markdown-output` is not on it. If you host on GH Pages, you have two options:

1. Build the site yourself in CI (GitHub Actions, Netlify, Cloudflare Pages, Vercel) and deploy the built `_site/` to GH Pages, instead of relying on GH Pages' own Jekyll build.
2. Skip this plugin and serve `.html` only.

Cloudflare Pages, Netlify, Vercel, and self-hosted builds run the plugin without restriction.

## FAQ

**How is this different from `llms.txt`?**

`llms.txt` is one root file listing your content. This plugin emits a per-page `.md` next to each `.html`, so an agent that lands on `/foo` can fetch `/foo.md` directly without consulting an index. The two compose: ship both if you want.

**Why not just convert the rendered HTML back to Markdown?**

The HTML has already gone through layouts, includes, theme chrome, syntax highlighting wrappers, and possibly a markdown converter that drops information (smart quotes, ID anchors). Round-tripping is lossy. Reading the source is faithful.

**Will it slow my build down?**

No measurable cost on a site with hundreds of posts. The hook runs once after `:site, :post_write` and writes files in a tight loop.

## License

MIT. See `LICENSE`.
