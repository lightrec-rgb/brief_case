module SessionsHelper
  def session_status_badge(session)
    colors = {
      "draft"       => "bg-gray-100 text-gray-800",
      "in_progress" => "bg-blue-100 text-blue-800",
      "paused"      => "bg-yellow-100 text-yellow-800",
      "completed"   => "bg-green-100 text-green-800"
    }
    cls = "inline-block rounded px-2 py-0.5 text-xs #{colors[session.status] || 'bg-gray-100 text-gray-800'}"
    content_tag(:span, session.status.humanize, class: cls)
  end
end
