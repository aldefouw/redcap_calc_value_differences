require 'mechanize'
require "#{Dir.getwd}/library/authentication"

class Browser

  attr_reader :options
  attr_reader :threads
  attr_reader :redcap_url
  attr_reader :redcap_version
  attr_reader :agent
  attr_reader :project_id
  attr_reader :threads

  attr_accessor :authentication

  attr_reader :events_page

  def initialize(**options)
    @options = options[:browser_options]
    @threads = options[:threads] || 1
    @redcap_url = options[:redcap_url]
    @redcap_version = options[:redcap_version]
    @project_id = options[:project_id]

    @authentication = Authentication.new(base_dir: options[:base_dir])

    start_agent_and_login
  end

  def single_close_alert
    begin
      Thread.current[:driver].alert.close if Thread.current[:driver].alert.exists?
    rescue UnknownObjectException
      error_output("NO ALERT WINDOW FOR SINGLE CLOSE.")
    end
  end

  def close_alerts(record, field, instrument)
    begin
      Thread.current[:driver].alert.close if Thread.current[:driver].alert.exists?
    rescue
      error_output("NO ALERT WINDOW WAS PRESENT? Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field}")
    end
  end

  private

  def start_agent_and_login
    @agent = Mechanize.new

    @agent.get("https://redcap.medicine.wisc.edu") do |page|
      login = page.form do |f|
        f.fields[0].value = @authentication.username
        f.fields[1].value = @authentication.password
      end.submit
    end
  end

end