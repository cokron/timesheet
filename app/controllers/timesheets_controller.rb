class TimesheetsController < ApplicationController
  def show
    @clients = harvest_api.clients.sort_by{|c| c['name'].downcase}
    @users = harvest_api.users.sort_by{|c| c['first_name']}
    @selected_client = @clients.find {|c| c['id'].to_s == params.dig(:filter, :client_id) } || @clients.first
    @selected_user = @users.find {|c| c['id'].to_s == params.dig(:filter, :user_id) } || nil

    ago = (ENV["MONTH"] || "0").to_i
    month = ago.months.ago.to_date
    puts "Time"
    puts month.acts_like?(:time)
    timespan = {from: month.beginning_of_month, to: month.end_of_month}

    filter_params = timespan.merge(@selected_user ? {user_id: @selected_user['id']} : {client_id: @selected_client['id']})
    puts "filter params are: " + filter_params.inspect

    #.select {|e| e['project']['name'] == 'SunTed WebBox'}
    #.select {|e| e['project']['name'] == 'Rentenbank Offboarding'}
    #.select {|e| e['project']['name'] == 'DialogOnline'}


    @time_entries =
      harvest_api
      .time_entries(filter_params)
      .sort_by {|e| e['spent_date'] + e['started_time']}
      .map {|e|
        {
          'date' => e['spent_date'],
          'time' => e['started_time'],
          'project' => e['project']['name'],
          'client' => e['client']['name'],
          'task' => e['task']['name'],
          'notes' => e['notes'],
          'hours' => e['rounded_hours'],
          'billable' => e['billable'],
          'user' => e['user']['name'],
        }
      }
      .group_by {|e| [e['date'], e['client'], e['billable'], e['notes']] }
      .map {|_g, entries|
        entries.first.merge(
          'hours' => entries.sum{|e| e['hours'] }
        )
      }.sort_by {|e| e['date'] + e['time']}
          #.reject{|e| e['date'].start_with?("2020-04")}

    @total_hours_billable = @time_entries.select{|e| e['billable']}.sum{|e| e['hours'] }
    @total_hours_non_billable = @time_entries.select{|e| !e['billable']}.sum{|e| e['hours'] }
  end
end
