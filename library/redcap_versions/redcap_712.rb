module Redcap712

  def event_row
    @table.search('thead').search('tr')[0]
  end

  def header
    @table.search('thead').search('tr')[1]
  end

  def number_of_cols(col)
    col[1][:cols].to_i - 1
  end

  def record_id(tr)
    tr.search('td > a').text
  end

  def minimum_row
    @longitudinal ? 1 : 0
  end

  def event_forms(event)
    event[1][:forms]
  end

  def field_count(instrument)
    instrument[1].count
  end

  def get_table
    @agent.get("#{@browser.redcap_url}/redcap_v#{@browser.redcap_version}/DataEntry/record_status_dashboard.php?pid=#{@id}&num_per_page=1000&pagenum=ALL") do |page|
      return page.parser.search('table')[2]
    end
  end

  def get_event_form_tables
    tables = []

    @arms.each do |arm|
      @agent.get("#{@browser.redcap_url}/redcap_v#{@browser.redcap_version}/Design/define_events.php?pid=#{@id}&arm=#{arm}") do |page|
        tables << page.parser.search('table')[1]
      end
    end

    tables
  end

  def get_events
    @event_form_tables.each do |form_table|
      tds = {}

      form_table.search('tr[class=nodrop] > td').each_with_index do |td, index|
        tds[td.text] = index
      end

      name_index = tds["Event Name"]
      key_index = tds["Event Name"] + 2

      form_table.search('tr').each_with_index do |tr, index|
        if form_table.search('tr').count != (index + 1) && index != 0

          key = tr.search('td')[key_index].children.first.text
          name = tr.search('td')[name_index].text
          value = tr.attributes["id"].value.split("design_")[1]

          @define_my_events[key] = { name: name, id: value }
        end
      end
    end
  end

  def get_event_cols
    event_row.search('th').each_with_index do |th, i|
      if th.attributes.key?("colspan")

        if @arms.count > 1
          current_text = th.text.split("(Arm ")[0].strip
          current_arm = th.text.split("(Arm ")[1].split(":")[0].to_i
        else
          current_text = th.text
          current_arm = 1
        end

        num_of_cols = th.attributes["colspan"].value.to_i

        @event_forms.each_with_index do |form, index|
          current_event = @define_my_events[form["unique_event_name"]]
          arm = form["unique_event_name"].split("_arm_")[1].to_i

          if current_text == current_event[:name] && current_arm == arm
            @event_cols[form["unique_event_name"]] = { arm: arm, cols: num_of_cols, name: current_event[:name] }
          end
        end
      end
    end

    header.search('th').each { |th| @instrument_mappings << th.text.strip.delete("'").downcase.parameterize.underscore }

    @event_cols.each_with_index do |e, index|
      e[1][:index] = index
    end

    #Sort by the arm first and then the index (just like the table headers)
    @event_cols = @event_cols.sort_by { |k|  [ k[1][:arm], k[1][:index] ] }.to_h

    count = 0

    @event_cols.each_with_index do |e|
      e[1][:forms] = []
      (0..number_of_cols(e)).each { e[1][:forms] << { count = count + 1 => @instrument_mappings[count - 1] } }
    end
  end

  def find_active_records(id:, instrument:)
    @table.search('tr').each_with_index do |tr, c|
      if c > minimum_row

        @active_records[record_id(tr)] = {} unless @active_records.key?(record_id(tr))

        td = tr.search('td')[id]
        img = td.search('a > img')

        unless img.nil?
          unless img.first.nil?
            circle_type = td.search('a > img').first.attributes.first[1].value.split("/").last
            if circle_type == "circle_gray.png"
              puts "."
            else
              @active_records[record_id(tr)][id] = [] unless @active_records[record_id(tr)].key?(id)
              @active_records[record_id(tr)][id] = instrument
              puts "/"
            end
          end
        end
      end
    end
  end

  def longitudinal_analysis
    @event_cols.each do |event|
      event_forms(event).each { |e| find_active_records(id: e.first[0].to_i, instrument: e.first[1]) }
    end
  end

  def standard_analysis
    @calc_fields.each_with_index do |instrument, i|
      find_active_records(id: i + 1, instrument: instrument[0]) if field_count(instrument) > 0
    end
  end

  def get_active_records
    @longitudinal ? longitudinal_analysis : standard_analysis
  end

  def fetch_calc_fields
    f = {}
    @data_dictionary.each do |c|
      if f.key?(c[1]) && c[3] == "calc"
        f[c[1]].push c[0]
      elsif c[3] == "calc"
        f[c[1]] = []
        f[c[1]].push c[0]
      end
    end
    f
  end

end