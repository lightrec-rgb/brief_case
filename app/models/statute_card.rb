class StatuteCard
  def initialize(card)
    @card = card
  end

  # prepare the question and answer for session_item
  def build_pair
    our_statute = @card.statute_detail
    return { question: nil, answer: nil } unless our_statute

    titles = [
      our_statute.act_short_name,
      our_statute.act_name,
    ].compact_blank

    return { question: nil, answer: nil } if titles.empty?

    candidates = titles.flat_map do |t|
      [
        [ "What does #{our_statute.provision_ref} of #{t} provide?", our_statute.provision_text ],
        [ "Which Act and section contains this wording:\n\n\"#{our_statute.provision_text}\"", "#{our_statute.act_name} — #{our_statute.provision_ref}" ]
      ]
    end

    q, a = candidates.sample
    { question: q, answer: a }
  end
end
