class Analyzer

  attr_reader :reporting

  def initialize(**options)
    @base_dir = options[:base_dir]
    @browser = options[:browser]
    @project = options[:project]
    @path = options[:path]
    @reporting = options[:reporting]
    @beginning_time = Time.now
    @save_form_on_difference = options[:save_form_on_difference]
  end

  def find_differences
    begin_analysis

    Parallel.map(data_chunks) do |chunk|
      setup
      check_data(chunk)
      teardown
    end

    end_analysis
  end

  private

  def begin_analysis
    @reporting.info_output("\n==== BEGIN ANALYSIS OF PROJECT ID #{@project.id} ====")
  end

  def data_chunks
    if @project.data.count > @browser.threads
      count = (@project.data.count / @browser.threads)
      @project.data.each_slice(count).to_a
    else
      [@project.data]
    end
  end

  def setup
    Thread.current[:driver] = Watir::Browser.new(:chrome, options: @browser.options)
    Thread.current[:driver].goto @browser.redcap_url
    Thread.current[:driver].text_field(:name, "username").set(@browser.authentication.username)
    Thread.current[:driver].text_field(:name, "password").set(@browser.authentication.password)
    Thread.current[:driver].button(:id,'login_btn').click
  end

  def teardown
    Thread.current[:driver].quit
    @reporting.info_output("This thread is closed.")
  end

  def end_analysis
    puts "Time elapsed #{(Time.now - @beginning_time)} seconds"
    @reporting.info_output("\n==== END ANALYSIS OF PROJECT ID #{@project.id} ====")
  end

  def non_nil_record(record)
    !record[0].nil?
  end

  def fields_in_record(instrument)
    fields(instrument).count > 0
  end

  def valid_instrument(record, instrument)
    (!@project.longitudinal || instrument_in_data_dictionary?(record, instrument))
  end

  def record_instruments(record)
    @project.active_records[record.first[1]].values
  end

  def form_with_calc_fields(record, instrument)
    non_nil_record(record) &&
        fields_in_record(instrument) &&
        record_instruments(record).include?(instrument_name(instrument)) &&
        valid_instrument(record, instrument)
  end

  def check_data(chunk)
    chunk.each do |record|
      if @project.active_records.key?(record.first[1])
        @project.calc_fields.each do |instrument|
          visit_case_report_form(record: record, instrument: instrument) if form_with_calc_fields(record, instrument)
        end
      end
    end
  end

  def evaluate_fields(record, instrument)
    fields(instrument).each do |field|
      begin
        @browser.close_alerts(record, field, instrument)
        evaluate_values(record, field, instrument)
      rescue Selenium::WebDriver::Error::UnhandledAlertError => e
        @browser.single_close_alert
        @reporting.error_output("UNAHNDLED ERROR - Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} | Exception: #{e} ")
      rescue
        @browser.single_close_alert
        @reporting.error_output("UNKNOWN RESCUE - Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field}  ")
      end
    end
  end

  def instrument_in_data_dictionary?(record, instrument)
    if @project.event_cols.nil?
      return false
    else
      @project.event_cols[record['redcap_event_name']][:forms].map{|m| m.first[1] }.include?(instrument_name(instrument))
    end
  end

  def evaluate_values(record, field, instrument)
    if values_are_equal?(case_report_form: case_report_value(field), data_file_value: record[field])

      value_match_response(record: record,
                           instrument: instrument,
                           field: field)
    else

      value_mismatch_response(record: record,
                              instrument: instrument,
                              field: field)
    end
  end

  def case_report_value(field)
    Thread.current[:driver].text_field(:name => field).value
  end

  def record_id(record)
    record.first[1]
  end

  def value_match_response(record:, instrument:, field:)
    @reporting.info_output("Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} OK")
  end

  def value_mismatch_response(record:, instrument:, field:)
    @reporting.error_output("VALUE MISMATCH - Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} | Case Report: #{case_report_value(field)}  | Data Export: #{record[field]}")

    @reporting.add_error_to_file(record: record,
                                 instrument: instrument_name(instrument),
                                 field: field,
                                 case_report_value: case_report_value(field),
                                 export_value: record[field],
                                 url: visit_url(record, instrument))

    save_form if @save_form_on_difference
  end

  def save_form
    click_save

    if successful_edit
      @reporting.info_output("Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} -- SUCCESSFULLY SAVED")
    else
      @reporting.error_output("Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} -- SAVE ERROR!")
    end
  end

  def click_save
    Thread.current[:driver].button(name: "submit-btn-saverecord").click
  end

  def successful_edit
    Thread.current[:driver].div(class: "darkgreen").text.include?("successfully edited")
  end

  def fields(instrument)
    instrument[1]
  end

  def instrument_name(instrument)
    instrument[0]
  end

  def visit_case_report_form(record:, instrument:)
    begin
      Thread.current[:driver].goto visit_url(record, instrument)
      Thread.current[:driver].windows.last.use

      evaluate_fields(record, instrument)

    rescue Selenium::WebDriver::Error::UnhandledAlertError => e
      @browser.single_close_alert
      @reporting.error_output("UNAHNDLED ERROR - Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} | Exception #{e} ")
    rescue
      @browser.single_close_alert
      @reporting.error_output("UNKNOWN RESCUE - Record: #{record[0]} - #{instrument_name(instrument)} / #{record["redcap_event_name"]} / #{field} ")
    end
  end

  def visit_url(record, instrument)
    if @project.longitudinal
      "#{@browser.redcap_url}/redcap_v#{@browser.redcap_version}/DataEntry/index.php?pid=#{@project.id}&id=#{record[0]}&page=#{instrument_name(instrument)}&event_id=#{@project.define_my_events[record["redcap_event_name"]][:id]}"
    else
      "#{@browser.redcap_url}/redcap_v#{@browser.redcap_version}/DataEntry/index.php?pid=#{@project.id}&id=#{record[0]}&page=#{instrument_name(instrument)}"
    end
  end

  def values_are_equal?(case_report_form:, data_file_value:)
    data_file_value.to_s == case_report_form
  end

end