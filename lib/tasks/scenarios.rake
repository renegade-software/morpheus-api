namespace :scenarios do
  desc "Freeze content/scenarios/*.yaml into new active versions where the content changed: bin/rails scenarios:import"
  task import: :environment do
    created = Scenario.import_all!
    if created.empty?
      puts "No changes: every scenario file matches its active version."
    else
      created.each { puts "Active: #{_1.key} (version ##{_1.id}, #{CefrLevel.label(_1.level)}, #{_1.turn_limit} turns)" }
    end

    Scenario.where(status: "active").select(&:needs_opening_audio?).each do |scenario|
      trace = scenario.voice_opening!
      puts "Opening voiced: #{scenario.key} (#{trace.fetch('model')}, #{trace.fetch('latency_ms')} ms, " \
           "US$#{trace.fetch('cost_usd')})"
    end
  end

  # The import voices an opening only once, with whichever agent is live, so openings voiced before an agent
  # upgrade keep the old model's audio until they're re-voiced.
  desc "Re-voice the opening of every active voice scenario with the agent's current model: bin/rails scenarios:revoice"
  task revoice: :environment do
    Scenario.where(status: "active").select { _1.mode == "voice" }.each do |scenario|
      scenario.opening_audio.purge
      trace = scenario.voice_opening!
      puts "Opening re-voiced: #{scenario.key} (#{trace.fetch('model')}, #{trace.fetch('latency_ms')} ms, " \
           "US$#{trace.fetch('cost_usd')})"
    end
  end
end
