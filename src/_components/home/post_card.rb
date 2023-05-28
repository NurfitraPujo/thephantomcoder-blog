class Home::PostCard < Bridgetown::Component
  def initialize(date:, title:, summary:, url:)
    @date = date
    @title = title
    @summary = summary
    @url = url
  end

  def truncated_summary
    @summary.size > 250 ? "#{@summary[0...250]...}" : @summary
  end

  def truncated_title
    @title.size > 40 ? "#{@title[0...40]}..." : @title
  end
end
