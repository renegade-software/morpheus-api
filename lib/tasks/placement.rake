namespace :placement do
  desc "Import content/placement/*.yaml as a new draft form: bin/rails 'placement:import[2026-10 study]'"
  task :import, [ :name ] => :environment do |_task, args|
    name = args.fetch(:name)
    form = Placement::Import.call(name: name)
    missing = form.placement_passages.where(section: "listening").reject { _1.audio.attached? }.map(&:tier)

    puts "Draft form ##{form.id} \"#{form.name}\": #{form.placement_questions.count} questions, " \
         "1 writing task with #{form.placement_writing_anchors.count} anchors, " \
         "#{form.placement_speaking_tasks.count} speaking tasks with #{form.placement_speaking_anchors.count} anchors, " \
         "#{form.placement_rubric_descriptors.count} rubric descriptors"

    if missing.any?
      puts "\n⚠️  Listening audio missing for tiers: #{missing.join(', ')}"
      puts "To fix this without deleting the draft:"
      puts "  1. Add the files to: content/placement/audio/listening-<tier>.mp3"
      puts "  2. Run: bin/rails 'placement:attach_audio[#{name}]'"
    end
  end

  desc "Retroactively attach missing audio files to an existing draft form"
  task :attach_audio, [ :name ] => :environment do |_task, args|
    form = PlacementForm.find_by!(name: args.fetch(:name))
    missing_passages = form.placement_passages.where(section: "listening").reject { _1.audio.attached? }

    if missing_passages.empty?
      puts "All listening passages for '#{form.name}' already have audio attached."
      next
    end

    audio_dir = Rails.root.join("content", "placement", "audio")

    missing_passages.each do |passage|
      audio_file = audio_dir.join("listening-#{passage.tier}.mp3")

      if audio_file.exist?
        passage.audio.attach(io: audio_file.open, filename: audio_file.basename.to_s, content_type: "audio/mpeg")
        puts "✅ Attached audio to tier #{passage.tier}"
      else
        puts "❌ Still missing: #{audio_file}"
      end
    end
  end

  desc "Serve a draft form to new learners, retiring the current one: bin/rails 'placement:activate[2026-10 study]'"
  task :activate, [ :name ] => :environment do |_task, args|
    PlacementForm.find_by!(name: args.fetch(:name)).activate!
    puts "Active: #{args[:name]}"
  end

  desc "Destroy a draft form (will abort if user answers exist): bin/rails 'placement:destroy[2026-10 study]'"
  task :destroy, [ :name ] => :environment do |_task, args|
    name = args.fetch(:name)
    form = PlacementForm.find_by(name: name)

    if form.nil?
      puts "⚠️  Could not find a form named '#{name}'."
      next
    end

    begin
      form.destroy
      puts "✅ Successfully destroyed draft form '#{name}'."
    rescue ActiveRecord::DeleteRestrictionError => e
      puts "\n⛔️ ABORTED: Cannot delete '#{name}'!"
      puts "This form already has active user submissions (answers) attached to it."
      puts "Rails blocked the deletion to prevent accidental data loss."
      puts "Error details: #{e.message}\n"
    end
  end
end
