module SubjectsHelper
  # returns array of [label, id] with nesting dashes
  def subject_options_for_select(user)
    tree = user.subjects.arrange(order: :name)
    build_subject_pairs(tree)
  end

  def subject_deletable?(subject)
    subject.children.none? && subject.card_templates.none?
  end

  private

  def subject_breadcrumb(subject)
    subject.path.map(&:name).join(" › ")
  end

  def subtree_case_count(subject, counts_hash)
    subject.subtree_ids.sum { |id| counts_hash[id] || 0 }
  end

  def build_subject_pairs(nodes, depth = 0)
    nodes.flat_map do |subject, children|
      label = ("— " * depth) + subject.name
      [ [ label, subject.id ] ] + build_subject_pairs(children, depth + 1)
    end
  end
end
