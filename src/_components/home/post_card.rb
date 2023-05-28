class Home::PostCard < Bridgetown::Component
  def initialize(date:, title:, summary:, url:)
    @date = date
    @title = title
    @summary = summary
    @url = url
  end

  def truncated_summary
    @summary.size > 300 ? "#{@summary[0...300]...}" : @summary
  end

  def truncated_title
    @title.size > 60 ? "#{@title[0...60]}..." : @title
  end
end
