namespace :scenarios do
  desc "Freeze content/scenarios/*.yaml into new active versions where the content changed: bin/rails scenarios:import"
  task import: :environment do
    created = Scenario.import_all!
    if created.empty?
      puts "No changes: every scenario file matches its active version."
    else
      created.each { puts "Active: #{_1.key} (version ##{_1.id}, #{CefrLevel.label(_1.level)}, #{_1.turn_limit} turns)" }
    end

    # Also catches a voice version imported while the agent was down.
    Scenario.where(status: "active").select(&:needs_opening_audio?).each do |scenario|
      trace = scenario.voice_opening!
      puts "Opening voiced: #{scenario.key} (#{trace.fetch('latency_ms')} ms, US$#{trace.fetch('cost_usd')})"
    end
  end
end
