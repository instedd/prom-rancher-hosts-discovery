require "rancher"
require "logger"

OUTPUT = ENV["OUTPUT"]? || "hostnames.json"

log = Logger.new(STDOUT)
previous_results = nil

loop do
  begin
    Rancher::Client.new do |client|
      projects = client.list_projects

      results = projects.data.each
        .reject { |p| p.state == "inactive" }
        .map do |p|
          domains = p.load_balancer_services
            .data
            .flat_map(&.lb_config.port_rules)
            .map(&.hostname?)
            .compact_map(&.itself)
            .reject(&.empty?)
            .reject(&.starts_with?("*"))
            .uniq
          {labels: {env: p.name}, targets: domains}
        end
        .to_a

      if results != previous_results
        log.info "Writing results to #{OUTPUT}"
        File.write OUTPUT, results.to_json
        previous_results = results
      end
    end
  rescue ex
    log.error ex
  end

  sleep 60
end
