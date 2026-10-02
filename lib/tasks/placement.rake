namespace :placement do
  desc "Import content/placement/*.yaml as a new draft form: bin/rails 'placement:import[2026-10 study]'"
  task :import, [ :name ] => :environment do |_task, args|
    form = Placement::Import.call(name: args.fetch(:name))
    missing = form.placement_passages.where(section: "listening").reject { _1.audio.attached? }.map(&:tier)
    puts "Draft form ##{form.id} \"#{form.name}\": #{form.placement_questions.count} questions, " \
         "1 writing task with #{form.placement_writing_anchors.count} anchors, " \
         "#{form.placement_speaking_tasks.count} speaking tasks with #{form.placement_speaking_anchors.count} anchors, " \
         "#{form.placement_rubric_descriptors.count} rubric descriptors"
    puts "Listening audio missing for tiers #{missing.join(', ')}: add content/placement/audio/listening-<tier>.mp3 " \
         "and re-import before activating" if missing.any?
  end

  desc "Serve a draft form to new learners, retiring the current one: bin/rails 'placement:activate[2026-10 study]'"
  task :activate, [ :name ] => :environment do |_task, args|
    PlacementForm.find_by!(name: args.fetch(:name)).activate!
    puts "Active: #{args[:name]}"
  end
end
