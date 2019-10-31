require "rancher"
require "logger"

OUTPUT = ENV["OUTPUT"]? || "hostnames.json"

log = Logger.new(STDOUT)

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

    results_json = results.to_json
    unless File.exists?(OUTPUT) && File.read(OUTPUT) == results_json
      log.info "Writing results to #{OUTPUT}"
      File.write OUTPUT, results_json
    end
  end
rescue ex
  log.error ex
end
