class CaseCard 
  
  def initialize(card) 
    @card = card
  end

  # prepare the question and answer for session_item
  def build_pair
    our_case = @card.case_detail
    return { question: nil, answer: nil } unless our_case

    titles = [
      our_case.case_name,
      our_case.full_citation,
      our_case.case_short_name
    ].compact_blank

    return { question: nil, answer: nil } if titles.empty?

    candidates = titles.flat_map do |t|
      [
        ["What is the key principle in #{t}?",         our_case.key_principle],
        ["What are the material facts in #{t}?",       our_case.material_facts],
        ["What was the issue to be resolved in #{t}?", our_case.issue]
      ]
    end

    q, a = candidates.sample
    { question: q, answer: a }
  end
end