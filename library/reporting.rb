class Reporting

  def initialize(options)
    @base_dir = options[:base_dir]
    @project_id = options[:project_id]
    @project = options[:project]

    create_errors_folder
    make_errors_csv
    create_logs_folder

    @error_log = Logger.new(errors_log_path)
    @info_log = Logger.new(info_log_path)
  end

  def create_errors_folder
    Dir.chdir(@base_dir)
    Dir.mkdir("errors") unless Dir.exist?("errors")
    Dir.chdir("#{@base_dir}/errors")
    Dir.mkdir(@project_id.to_s, 0777)  unless Dir.exist?(@project_id.to_s)
  end

  def create_logs_folder
    Dir.chdir(@base_dir)
    Dir.mkdir("logs") unless Dir.exist?("logs")
    Dir.chdir("#{@base_dir}/logs")
    Dir.mkdir(@project_id.to_s, 0777)  unless Dir.exist?(@project_id.to_s)
  end

  def errors_log_path
    "#{@base_dir}/logs/#{@project_id}/errors.log"
  end

  def info_log_path
    "#{@base_dir}/logs/#{@project_id}/info.log"
  end

  def errors_csv_path
    "#{@base_dir}/errors/#{@project_id}/errors.csv"
  end

  def info_output(text)
    puts text.green
    @info_log.info(text)
  end

  def error_output(text)
    puts text.red
    @error_log.error(text)
  end

  def make_errors_csv
    if @project.longitudinal
      CSV.open(errors_csv_path, "wb") { |csv| csv << ["record_id", "redcap_event_name", "instrument", "field", "case_report_form_value", "export_form_value", "url"] }
    else
      CSV.open(errors_csv_path, "wb") { |csv| csv << ["record_id", "instrument", "field", "case_report_form_value", "export_form_value", "url"] }
    end
  end

  def add_error_to_file(record:, instrument:, field:, case_report_value:, export_value:, url:)
    CSV.open(errors_csv_path, "a+") do |csv|
      csv << csv_error_row(record: record,
                           instrument: instrument,
                           field: field,
                           case_report_value: case_report_value,
                           export_value: export_value,
                           url:  url)
    end
  end

  def csv_error_row(record:, instrument:, field:, case_report_value:, export_value:, url:)
    if @project.longitudinal
      [record[0], record["redcap_event_name"], instrument, field, case_report_value, export_value, url]
    else
      [record[0], instrument, field, case_report_value, export_value, url]
    end
  end

end