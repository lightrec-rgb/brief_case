module SubjectsHelper
  # Turn the subject list into a nested tree sorted by name
  # Convert the tree into a list of pairs to use in a select
  def subject_options_for_select(user)
    tree = user.subjects.arrange(order: :name)
    build_subject_pairs(tree)
  end

  # Return true if a subect has no children and no card templates
  # Indicate whether safe to delete
  def subject_deletable?(subject)
    subject.children.none? && subject.card_templates.none?
  end

  private

  # Build a breadcrumb string for subjects and children
  def subject_breadcrumb(subject)
    subject.path.map(&:name).join(" › ")
  end

  # Add up the counts of cases and provisions for a subject and all its children
  def subtree_case_count(subject, counts_hash)
    subject.subtree_ids.sum { |id| counts_hash[id] || 0 }
  end

  # Flatten the nested subject tree for use in a dropdown
  def build_subject_pairs(nodes, depth = 0)
    nodes.flat_map do |subject, children|
      label = ("— " * depth) + subject.name
      [ [ label, subject.id ] ] + build_subject_pairs(children, depth + 1)
    end
  end
end
