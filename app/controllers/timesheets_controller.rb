class TimesheetsController < ApplicationController
  def show
    @clients = harvest_api.clients.sort_by{|c| c['name']}
    @selected_client = @clients.find {|c| c['id'].to_s == params.dig(:filter, :client_id) } || @clients.first
    @time_entries =
      harvest_api
      .time_entries(client_id: @selected_client['id'])
      .sort_by {|e| e['spent_date'] + e['started_time']}
      .map {|e|
        {
          'date' => e['spent_date'],
          'project' => e['project']['name'],
          'task' => e['task']['name'],
          'notes' => e['notes'],
          'hours' => e['rounded_hours'],
          'billable' => e['billable'],
        }
    }
      .group_by {|e| [e['date'], e['task'], e['notes'], e['billable']] }
      .map {|_g, entries|
        entries.first.merge(
          'hours' => entries.sum{|e| e['hours'] }
        )
    }
          #.reject{|e| e['date'].start_with?("2020-04")}
    @total_hours_billable = @time_entries.select{|e| e['billable']}.sum{|e| e['hours'] }
    @total_hours_non_billable = @time_entries.select{|e| !e['billable']}.sum{|e| e['hours'] }
  end
end
