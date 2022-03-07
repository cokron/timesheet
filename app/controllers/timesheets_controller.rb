class TimesheetsController < ApplicationController
  def show
    @clients = harvest_api.clients.sort_by{|c| c['name']}
    @users = harvest_api.users.sort_by{|c| c['first_name']}
    @selected_client = @clients.find {|c| c['id'].to_s == params.dig(:filter, :client_id) } || @clients.first
    @selected_user = @users.find {|c| c['id'].to_s == params.dig(:filter, :user_id) } || nil

    timespan = {from: DateTime.new(2020,3,1,0,0,0), to: DateTime.new(2021,12,31,23,59,59)}

    filter_params = timespan.merge(@selected_user ? {user_id: @selected_user['id']} : {client_id: @selected_client['id']})

    @time_entries =
      harvest_api
      .time_entries(filter_params)
      .select {|e| e['project']['name'] != 'Intern'}
      .sort_by {|e| e['spent_date'] + e['started_time']}
      .map {|e|
        {
          'date' => e['spent_date'],
          'project' => e['project']['name'],
          'client' => e['client']['name'],
          'task' => e['task']['name'],
          'notes' => e['notes'],
          'hours' => e['hours'], #e['rounded_hours'],
          'billable' => e['billable'],
        }
    }
      .group_by {|e| [e['date'], e['client'], e['billable']] }
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
