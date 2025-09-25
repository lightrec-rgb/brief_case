module SessionsHelper
  # Return a human-friendly label for a session's enum status
  def session_status_label(session)
    return "Completed"        if session.completed?
    return "Paused"           if session.paused?
    return "Active"           if session.in_progress?
    return "Not yet started"  if session.draft?
    session.status.to_s.humanize
  end

  # Render a visual badge for each session status
  def session_status_badge(session)
    label = session_status_label(session)

    tone =
      case label
      when "Completed"        then "bg-[#F1F5F9] text-[#334155] ring-[#E2E8F0]"
      when "Paused"           then "bg-[#F5F5F4] text-[#44403C] ring-[#E7E5E4]"
      when "Active"           then "bg-[#FFF7E6] text-[#8A5A00] ring-[#FFE0A3]"
      when "Not yet started"  then "bg-[#F3E8FF] text-[#6B21A8] ring-[#E9D5FF]"
      else                          "bg-gray-100 text-gray-800 ring-gray-200"
      end

    classes = [
      "inline-flex items-center",
      "rounded-full",
      "px-3 py-1",
      "text-sm font-medium",
      "ring-1 ring-inset",
      tone
    ].join(" ")

    content_tag(:span, label, class: classes, role: "status", aria: { label: label })
  end
end
