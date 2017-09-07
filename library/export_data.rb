class ExportData

  def initialize(**options)
    @path = options[:path]
    @base_dir = options[:base_dir]
    @project_id = options[:project_id]
  end

  def data_file
    "#{@base_dir}/#{@path}/data.csv"
  end

  def data_cols
    if File.exist? data_file
      CSV.read data_file, :headers => true
    else
      throw "You need to add a data export file (data.csv) for project ID #{@project_id} to #{data_file}"
    end
  end

  def event_form_file
    "#{@base_dir}/#{@path}/event-forms.csv"
  end

  def event_form_cols
    if longitudinal_project?
      if File.exist? event_form_file
        CSV.read event_form_file, :headers => true
      else
        throw "You need to add an instrument mapping files (event-forms.csv) for project ID #{@project_id} to #{event_form_file}"
      end
    end
  end

  def data_dictionary_file
    "#{@base_dir}/#{@path}/data-dictionary.csv"
  end

  def data_dictionary_cols
    if File.exist? data_dictionary_file
      CSV.read data_dictionary_file, :headers => true
    else
      throw "You need to add a data dictionary (data-dictionary.csv) for project ID #{@project_id} to #{data_dictionary_file}"
    end
  end

  def longitudinal_project?
    data_cols.first.include?('redcap_event_name')
  end

end