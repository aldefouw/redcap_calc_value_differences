require 'active_support/inflector'
require 'pry'
require 'csv'
require 'watir'
require 'logger'
require 'colorize'
require 'nokogiri'
require 'mechanize'
require 'parallel'

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

    options = options.merge(path: @path,
                            base_dir: @base_dir)

    @export_data = ExportData.new(options)

    @browser = Browser.new(options)

    @project = Project.new(
        base_dir: @base_dir,
        id: options[:project_id],
        data: @export_data.data_cols,
        event_forms: @export_data.event_form_cols,
        data_dictionary: @export_data.data_dictionary_cols,
        longitudinal: @export_data.longitudinal_project?,
        browser: @browser
    )

    @reporting = Reporting.new(options.merge(project: @project))

    @analyzer = Analyzer.new(base_dir: @base_dir,
                             browser: @browser,
                             reporting: @reporting,
                             project: @project,
                             path: @path)

  end

  def run
    @analyzer.find_differences
  end

end