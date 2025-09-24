class ProvisionCard
  def initialize(card)
    @card = card
  end

  # prepare the question and answer for session_item
  def build_pair
    prov = @card.provision_detail
    return { question: nil, answer: nil } unless prov

    titles = [
      prov.act_short_name,
      prov.act_name
    ].compact_blank

    return { question: nil, answer: nil } if titles.empty?

    candidates = titles.flat_map do |t|
      [
        [ "What does #{prov.provision_ref} of #{t} provide?", prov.provision_text ],
        [ "Which Act and section contains this wording:\n\n\"#{prov.provision_text}\"", "#{prov.act_name} — #{prov.provision_ref}" ]
      ]
    end

    q, a = candidates.sample
    { question: q, answer: a }
  end
end
