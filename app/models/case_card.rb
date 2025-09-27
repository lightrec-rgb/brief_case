class CaseCard
  # === Generate a Question / Answer pair for a case ===

  # Constructor to store passed in card for later use
  def initialize(card)
    @card = card
  end

  # Method that returns a question and an answer
  # Fetch the associated case record
  # Build an array of possible strings (case name, short name, full citation)
  # For each item in the array, loop through each possible question
  def build_pair
    our_case = @card.case_detail
    return { question: nil, answer: nil } unless our_case

    titles = [
      our_case.case_name,
      our_case.full_citation
    ].compact_blank

    return { question: nil, answer: nil } if titles.empty?

    candidates = titles.flat_map do |t|
      [
        [ "What is the key principle in #{t}?",         our_case.key_principle ],
        [ "What are the material facts in #{t}?",       our_case.material_facts ],
        [ "What was the issue to be resolved in #{t}?", our_case.issue ]
      ].reject { |_q, a| a.blank? }
    end

    # Pick a random question and answer and return them
    q, a = candidates.sample
    { question: q, answer: a }
  end
end
