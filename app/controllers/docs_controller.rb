# Serves the markdown in docs/ as pages under /docs, so the API and GML
# documentation lives on the site as well as in the repo.
class DocsController < ApplicationController
  def show
    @doc = DocsPage.find(params[:path])
    return render(template: "docs/missing", status: :not_found) if @doc.nil?

    # Agents and editors want the markdown itself: append .md to any docs URL.
    if request.path.end_with?(".md") || params[:format] == "md"
      return render(plain: @doc.markdown, content_type: "text/markdown")
    end

    response.headers["Link"] = %(<#{request.base_url}#{@doc.url_path}.md>; rel="alternate"; type="text/markdown")
    set_page_title @doc.title
  end

  # A plain-text index for crawlers and language models, per the llms.txt
  # convention. Served from the same file list as /docs, so it cannot drift.
  def llms
    @docs = DocsPage.all
    render plain: render_to_string(template: "docs/llms", formats: [:text]),
           content_type: "text/plain"
  end
end
