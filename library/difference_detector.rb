require 'active_support/inflector'
require 'pry'
require 'csv'
require 'watir'
require 'logger'
require 'colorize'
require 'nokogiri'
require 'mechanize'
require 'parallel'
require 'highline'

require "#{Dir.getwd}/library/browser"
require "#{Dir.getwd}/library/project"
require "#{Dir.getwd}/library/analyzer"
require "#{Dir.getwd}/library/reporting"
require "#{Dir.getwd}/library/export_data"

class DifferenceDetector

  attr_reader :project_id

  include ActiveSupport::Inflector

  def initialize(**options)
    @project_id = options[:project_id]
    @path = "project_exports/#{@project_id}"
    @base_dir = Dir.getwd
    @save_form_on_difference = options[:save_form_on_difference] || false

    are_you_sure_you_want_to_save?

    options = options.merge(path: @path,
                            base_dir: @base_dir)

    @export_data = ExportData.new(options)

    @browser = Browser.new(options)


    project_options = {
        base_dir: @base_dir,
        id: options[:project_id],
        data: @export_data.data_cols,
        event_forms: @export_data.event_form_cols,
        data_dictionary: @export_data.data_dictionary_cols,
        longitudinal: @export_data.longitudinal_project?,
        browser: @browser
    }

    project_options = project_options.merge(arms: @export_data.arms) if @export_data.longitudinal_project?

    @project = Project.new(project_options)



    @reporting = Reporting.new(options.merge(project: @project))

    @analyzer = Analyzer.new(base_dir: @base_dir,
                             browser: @browser,
                             reporting: @reporting,
                             project: @project,
                             path: @path,
                             save_form_on_difference: @save_form_on_difference)

  end

  def run
    @analyzer.find_differences
  end

  private

  def are_you_sure_you_want_to_save?
    if @save_form_on_difference
      cli = HighLine.new
      cli.choose do |menu|
        menu.prompt = "Are you sure you want to save each Case Report Form that you encounter a dicrepant value for?  (NOTE: This is NOT easily reversible.)"
        menu.choice("Yes")
        menu.choices("No") { abort "Please change 'save_form_on_difference' to false and re-run this script." }
        menu.default = "Yes"
      end
    end
  end

end