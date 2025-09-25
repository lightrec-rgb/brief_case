class ProvisionCard
  # === Generate a Question / Answer pair for a provision ===

  # Constructor to store passed in card for later use
  def initialize(card)
    @card = card
  end

  # Method that returns a question and an answer
  # Fetch the associated provision record
  # Build an array of possible strings (short name, name)
  # For each item in the array, loop through each possible question
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

    # Pick a random question and answer and return them
    q, a = candidates.sample
    { question: q, answer: a }
  end
end
