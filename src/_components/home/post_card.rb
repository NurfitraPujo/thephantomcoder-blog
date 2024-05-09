class Home::PostCard < Bridgetown::Component
  def initialize(date:, title:, summary:, url:, tags: '')
    @date = date
    @title = title
    @summary = summary
    @url = url
    @tags = tags
  end

  def truncated_summary
    @summary.size > 300 ? "#{@summary[0...350]...}" : @summary
  end

  def truncated_title
    @title.size > 60 ? "#{@title[0...60]}..." : @title
  end

  def tags
    @tags.map { |t| "#".concat(t) }
  end
end
