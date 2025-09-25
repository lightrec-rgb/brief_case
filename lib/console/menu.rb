module Console
  module Menu
    #
    # --------- Tiny helpers ---------
    #
    def say(msg = "")
      puts(msg)
    end

    def ask(prompt)
      print("#{prompt}: ")
      STDIN.gets&.chomp
    end

    def yes?(prompt)
      ans = ask("#{prompt} (y/N)")
      ans.to_s.strip.downcase.start_with?("y")
    end

    #
    # --------- Bootstrapping helpers ---------
    #
    def ensure_global_case_card!
      return if CaseCard.exists?

      holder = Card.where(kind: "Case").first
      unless holder
        t = CardTemplate.joins(:case_detail).first or raise "Need at least one case to create CaseCard"
        holder = Card.create!(user: t.user, subject: t.subject, card_template: t, kind: t.kind, name: t.kind)
      end

      placeholder = Case.first || holder.card_template.case_detail
      CaseCard.create!(card: holder, case: placeholder)
    end

    def ensure_cards_for_subject(user:, subject:)
      needed_ids = subject.card_templates.owned_by(user).joins(:case_detail).pluck(:id)
      existing_ids = Card.where(user:, subject: subject).pluck(:card_template_id)
      (needed_ids - existing_ids).each do |tid|
        t = CardTemplate.find(tid)
        Card.create!(user:, subject: subject, card_template: t, kind: t.kind, name: t.kind)
      end
    end

    #
    # --------- Menu entry point ---------
    #
    def run_menu!(user = nil)
      user ||= User.first or raise "No users exist. Create a user first."
      trap("INT") { say("\nBye!"); exit(0) }

      loop do
        say "\n=== Brief-Case Console ==="
        say "User: #{user.email}"
        say "1) Subjects"
        say "2) Cases"
        say "3) Sessions"
        say "q) Quit"
        print "> "

        case STDIN.gets&.chomp
        when "1" then subjects_menu(user)
        when "2" then cases_menu(user)
        when "3" then sessions_menu(user)
        when "q", "Q" then say("Bye!"); break
        else say "Unknown option."
        end
      end
    end

    def subjects_menu(user)
      loop do
        say "\n--- Subjects ---"
        say "1) List subjects (hierarchy)"
        say "2) Add subject"
        say "3) Edit subject"
        say "4) Delete subject"
        say "b) Back"
        print "> "

        case STDIN.gets&.chomp
        when "1" then list_subjects(user)
        when "2" then add_subject(user)
        when "3" then edit_subject(user)
        when "4" then delete_subject(user)
        when "b", "B" then break
        else say "Unknown option."
        end
      end
    end

    def cases_menu(user)
      loop do
        say "\n--- Cases ---"
        say "1) List cases in a subject"
        say "2) Add case to a subject"
        say "3) Edit case"
        say "4) Delete case"
        say "b) Back"
        print "> "

        case STDIN.gets&.chomp
        when "1" then list_cases(user)
        when "2" then add_case(user)
        when "3" then edit_case(user)
        when "4" then delete_case(user)
        when "b", "B" then break
        else say "Unknown option."
        end
      end
    end

    def sessions_menu(user)
      loop do
        say "\n--- Sessions ---"
        say "1) Start a new session"
        say "2) Continue a session"
        say "3) Show recent sessions"
        say "4) Delete a session"
        say "5) Delete all completed sessions"
        say "b) Back"
        print "> "

        case STDIN.gets&.chomp
        when "1" then start_session(user)
        when "2" then continue_session(user)
        when "3" then show_recent_sessions(user)
        when "4" then delete_session(user)
        when "5" then delete_all_completed_sessions(user)
        when "b", "B" then break
        else say "Unknown option."
        end
      end
    end
    #
    # --------- Subjects (simple CRUD) ---------
    #
    def subjects_for(user)
      user.subjects.order(:name)
    end

    def pick_subject(user)
      subs = subjects_for(user).to_a
      if subs.empty?
        say "No subjects yet."
        return nil
      end
      say "\nSubjects:"
      subs.each_with_index { |s, i| say "#{i+1}) #{s.name} (id=#{s.id})" }
      idx = ask("Choose subject number").to_i - 1
      subs[idx] rescue nil
    end

    def list_subjects(user)
      say "\nYour subjects (hierarchy):"
      arranged = user.subjects.arrange(order: :name)
      print_subject_tree(arranged)
    end

    def print_subject_tree(nodes, prefix = "")
      nodes.each do |subject, children|
        say "#{prefix}- #{subject.name} (id=#{subject.id})"
        # recursively print children with an indent
        print_subject_tree(children, prefix + "  ")
      end
    end

    def add_subject(user)
      say "\nAdd subject"
      name = ask("Name")
      parent = nil
      if yes?("Attach to a parent?")
        parent = pick_subject(user)
      end
      subj = user.subjects.new(name: name)
      subj.parent = parent if parent
      subj.save ? say("Created: #{subj.name} (id=#{subj.id})") : say("Failed: #{subj.errors.full_messages.to_sentence}")
    end

    def edit_subject(user)
      subject = pick_subject(user) or return say "No selection."
      say "\nEditing '#{subject.name}'"
      new_name = ask("New name (leave blank to keep)")
      subject.name = new_name unless new_name.to_s.strip.empty?
      if yes?("Change parent?")
        subject.parent = pick_subject(user)
      end
      subject.save ? say("Updated.") : say("Failed: #{subject.errors.full_messages.to_sentence}")
    end

    def delete_subject(user)
      subject = pick_subject(user) or return say "No selection."
      return say "Cancelled." unless yes?("Delete '#{subject.name}'?")
      subject.destroy ? say("Deleted.") : say("Failed: #{subject.errors.full_messages.to_sentence}")
    end

    #
    # --------- Cases (via CardTemplate + Case) ---------
    #
    def entries_for(user, subject)
      CardTemplate.owned_by(user)
                  .for_subject(subject)
                  .for_kind("Case")
                  .left_joins(:case_detail)
                  .includes(:case_detail)
                  .order(Arel.sql("LOWER(COALESCE(cases.case_name, '')) ASC"))
    end

    def pick_entry(user, subject)
      ents = entries_for(user, subject).to_a
      if ents.empty?
        say "No cases under this subject."
        return nil
      end
      say "\nCases:"
      ents.each_with_index do |e, i|
        name = e.case_detail&.case_name || "(untitled)"
        say "#{i+1}) entry ##{e.id}: #{name}"
      end
      idx = ask("Choose case number").to_i - 1
      ents[idx] rescue nil
    end

    def list_cases(user)
      subject = pick_subject(user) or return
      say "\nCases in '#{subject.name}':"
      entries_for(user, subject).each do |e|
        c = e.case_detail
        say "- entry ##{e.id}: #{c&.case_name || '(untitled)'} — #{c&.full_citation || 'no citation'}"
      end
    end

    def add_case(user)
      subject = pick_subject(user) or return
      say "\nAdd case to '#{subject.name}'"
      case_name       = ask("Case name")
      case_short_name = ask("Short name (optional)")
      full_citation   = ask("Full citation (optional)")
      say "Enter Material Facts. Finish with a single '.' on its own line."
      material_facts = read_multiline
      say "Enter Issue. Finish with '.'"
      issue = read_multiline
      say "Enter Key Principle. Finish with '.'"
      key_principle = read_multiline

      entry = CardTemplate.new(user: user, subject: subject, kind: "Case")
      entry.build_case_detail(
        case_name: case_name,
        case_short_name: case_short_name,
        full_citation: full_citation,
        material_facts: material_facts,
        issue: issue,
        key_principle: key_principle
      )

      if entry.save
        say "Created case '#{entry.case_detail.case_name}' (entry ##{entry.id})"
        ensure_cards_for_subject(user:, subject:)
      else
        say "Failed: #{entry.errors.full_messages.to_sentence}"
      end
    end

    def edit_case(user)
      subject = pick_subject(user) or return
      entry = pick_entry(user, subject) or return
      c = (entry.case_detail || entry.build_case_detail)

      say "\nEditing case (entry ##{entry.id})"
      new_name = ask("Case name (blank = keep '#{c.case_name}')")
      c.case_name = new_name unless new_name.to_s.strip.empty?

      new_short = ask("Short name (blank = keep '#{c.case_short_name}')")
      c.case_short_name = new_short unless new_short.to_s.strip.empty?

      new_cite = ask("Full citation (blank = keep '#{c.full_citation}')")
      c.full_citation = new_cite unless new_cite.to_s.strip.empty?

      if yes?("Edit Material Facts?")
        say "Enter Material Facts. Finish with '.'"
        c.material_facts = read_multiline
      end
      if yes?("Edit Issue?")
        say "Enter Issue. Finish with '.'"
        c.issue = read_multiline
      end
      if yes?("Edit Key Principle?")
        say "Enter Key Principle. Finish with '.'"
        c.key_principle = read_multiline
      end

      if yes?("Move to a different subject?")
        if (new_subj = pick_subject(user))
          entry.subject = new_subj
        end
      end

      if entry.save && c.save
        say "Updated."
        ensure_cards_for_subject(user:, subject: entry.subject)
      else
        say "Failed: #{(entry.errors.full_messages + c.errors.full_messages).uniq.to_sentence}"
      end
    end

    def delete_case(user)
      subject = pick_subject(user) or return
      entry = pick_entry(user, subject) or return
      name = entry.case_detail&.case_name || "(untitled)"
      return say "Cancelled." unless yes?("Delete case '#{name}' (entry ##{entry.id})?")
      entry.destroy ? say("Deleted.") : say("Failed: #{entry.errors.full_messages.to_sentence}")
    end

    def read_multiline
      lines = []
      while (line = STDIN.gets)
        line = line.chomp
        break if line == "."
        lines << line
      end
      lines.join("\n")
    end

    #
    # --------- Sessions (simple) ---------
    #
    def start_session(user)
      ensure_global_case_card!
      subject = pick_subject(user) or return
      ensure_cards_for_subject(user:, subject:)

      items = Card.where(user:, subject: subject).joins(card_template: :case_detail).to_a
      return say "No study items for this subject." if items.empty?

      # >>> Add this prompt <<<
      count = ask("How many cards? (blank = all)").to_i
      if count > 0 && count < items.size
        items = items.sample(count)   # randomly pick N cards
      end

      sess = user.sessions.create!(subject: subject, name: "Console #{Time.now.to_i}")
      sess.build_from_items!(items: items, name: sess.name)
      run_session(sess)
    end

    def continue_session(user)
      say "\nRecent sessions:"
      list = user.sessions.order(created_at: :desc).limit(20)
      if list.empty?
        say "- none -"; return
      end
      list.each { |s| say "- ##{s.id} #{s.name} [#{s.status}] #{s.done_count}/#{s.total_count}" }
      id = ask("Enter session id").to_i
      sess = user.sessions.find_by(id:) or return say "Not found."
      run_session(sess)
    end

    def run_session(sess)
      sess.start! if sess.status == "draft"
      say "\n--- Running: #{sess.name} ---"
      while (si = sess.prepare_current_item!)
        say "\n(#{si.position}/#{sess.total_count})"
        say "Q: #{si.question}"
        say "Press Enter to show the answer..."
        STDIN.gets
        say "A: #{si.answer}"
        si.mark_seen!
        correct = yes?("Did you get it right?")
        si.mark_done!(correct: correct)
        sess.advance!(correct: correct)
      end
      say "\nDone: #{sess.done_count}/#{sess.total_count} items. Status=#{sess.status}"
    end

    def show_recent_sessions(user)
      say "\nRecent sessions:"
      list = user.sessions.order(created_at: :desc).limit(20)
      if list.empty?
        say "- none -"
      else
        list.each do |s|
          say "- ##{s.id} #{s.name} [#{s.status}] #{s.done_count}/#{s.total_count}"
        end
      end
    end

    def delete_session(user)
      show_recent_sessions(user)
      id = ask("Enter session id to delete").to_i
      sess = user.sessions.find_by(id: id)
      return say "Not found." unless sess

      count = sess.session_items.count
      return say "Cancelled." unless yes?("Delete session ##{id} (#{sess.name})? This will remove #{count} item(s).")

      begin
        sess.destroy!
        say "Deleted session ##{id}."
      rescue => e
        say "Failed to delete: #{e.message}"
      end
    end

    def delete_all_completed_sessions(user)
      count = user.sessions.where(status: "completed").count
      return say "No completed sessions." if count.zero?
      return say "Cancelled." unless yes?("Delete #{count} completed session(s)?")
      user.sessions.where(status: "completed").find_each(&:destroy!)
      say "Deleted #{count} session(s)."
    end
  end
end
