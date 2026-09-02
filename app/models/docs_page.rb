# One markdown file under docs/, addressed by the slug in its URL, so the API
# and GML documentation lives on the site as well as in the repo.
#
# `/docs` and `/docs/api` resolve to the README.md in that directory, so a
# directory and a page can share a name without a special case.
class DocsPage
  ROOT = Rails.root.join("docs").realpath.freeze

  # filter_html because the source is trusted but has no reason to inject
  # markup; safe_links_only blocks javascript: hrefs.
  HTML_OPTIONS = { filter_html: true, safe_links_only: true, with_toc_data: true }.freeze
  EXTENSIONS = {
    fenced_code_blocks: true, tables: true, autolink: true,
    strikethrough: true, no_intra_emphasis: true
  }.freeze

  attr_reader :slug, :path

  def self.all
    Dir.glob("**/*.md", base: ROOT).sort.filter_map { |rel| find(rel.delete_suffix(".md")) }
  end

  # Returns nil rather than raising for anything that is not a real file inside
  # docs/. The slug reaches this straight from the URL, so a `..` in it must not
  # be able to read, say, config/master.key.
  def self.find(slug)
    slug = slug.to_s.delete_suffix(".md").delete_prefix("/").presence || "README"

    ["#{slug}.md", "#{slug}/README.md"].each do |relative|
      path = Pathname.new(File.expand_path(relative, ROOT))
      next unless path.to_s.start_with?("#{ROOT}/") && path.file?

      return new(slug, path)
    end
    nil
  end

  def initialize(slug, path)
    @slug = slug
    @path = path
  end

  # `/docs` rather than `/docs/README`, so the index has one address.
  def url_path
    slug == "README" ? "/docs" : "/docs/#{slug.delete_suffix('/README')}"
  end

  # Where the file actually sits, which is not `#{slug}.md` for a directory
  # index: /docs/api is served from docs/api/README.md.
  def repo_path
    path.relative_path_from(Rails.root).to_s
  end

  def markdown
    @markdown ||= path.read
  end

  # The first `# heading`, which every one of these files opens with.
  def title
    @title ||= markdown[/^#\s+(.+)$/, 1]&.strip || slug
  end

  # The first real paragraph after the title, for llms.txt. Headings, lists,
  # tables and code fences are skipped: several of these files open with one,
  # and a heading makes a useless summary.
  def summary
    @summary ||= begin
      body = markdown.split(/^#\s+.+$/, 2).last.to_s
      prose = body.split(/\n\s*\n/).map(&:strip).find do |block|
        block.present? && !block.start_with?("#", "-", "*", ">", "|", "```", "<")
      end
      prose.to_s.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1').tr("\n", " ").squish
    end
  end

  # Deployment and operations are for whoever runs the site, not for someone
  # reading the API. llms.txt keeps that split.
  def reference?
    slug.start_with?("api", "gml", "examples") || slug == "README"
  end

  def to_html
    self.class.renderer.render(rewrite_links(markdown))
  end

  # Redcarpet::Markdown holds no per-render state, so one instance is enough.
  def self.renderer
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(**HTML_OPTIONS), **EXTENSIONS)
  end

  private

  # These files are written to be read on GitHub too, so they link each other by
  # relative path (`api/uploading-gml.md`, `../gml/javascript-and-json.md`).
  # Those have to become site paths or every internal link 404s.
  #
  # Rewritten in the markdown rather than the rendered HTML because
  # safe_links_only drops a relative href before it ever becomes a link. It
  # keeps root-relative ones, which is what this produces.
  def rewrite_links(source)
    dir = File.dirname("#{slug}.md")

    source.gsub(/\]\(([^)\s]+\.md)(#[^)\s]*)?\)/) do
      target = Regexp.last_match(1)
      anchor = Regexp.last_match(2)
      next Regexp.last_match(0) if target.start_with?("http", "/")

      page = self.class.find(File.expand_path(target, "/#{dir}").delete_prefix("/"))
      page ? "](#{page.url_path}#{anchor})" : Regexp.last_match(0)
    end
  end
end
