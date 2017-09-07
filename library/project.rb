class Project

  attr_reader :id
  attr_reader :data
  attr_reader :data_dictionary
  attr_reader :longitudinal

  attr_reader :browser
  attr_reader :agent

  attr_accessor :event_cols

  attr_accessor :event_forms
  attr_accessor :calc_fields

  attr_reader :active_records

  attr_reader :define_my_events

  def initialize(**options)
    @id = options[:id]

    @browser = options[:browser]
    @agent = @browser.agent

    @data = options[:data]

    @data_dictionary = options[:data_dictionary]
    @longitudinal = options[:longitudinal]

    @define_my_events = {}

    @instrument_mappings = []

    @event_cols = {}
    @active_records = {}

    @event_forms = options[:event_forms]
    @base_dir = options[:base_dir]

    load_parser_for_redcap_version

    @calc_fields = fetch_calc_fields
    @table = get_table

    longitudinal_only_methods if @longitudinal

    get_active_records
  end

  private

  def longitudinal_only_methods
    @event_form_table = get_event_form_table
    get_events
    get_event_cols
  end

  def load_parser_for_redcap_version
    begin
      #Dynamically load the proper version parsing based upon the version listed by end user
      file_name = "redcap_#{@browser.redcap_version.parameterize.delete("-")}"
      klass = file_name.titlecase.delete(' ')

      #Dynamically extend the class
      require "#{@base_dir}/library/redcap_versions/#{file_name}"
      extend(Kernel.const_get(klass))
    rescue
      throw "You must have the correct version parser in order for this script to work."
    end
  end

end