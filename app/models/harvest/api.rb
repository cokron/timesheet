module Harvest
  class API
    include HTTParty
    base_uri 'https://api.harvestapp.com/v2/'

    def initialize(account_id:, access_token:)
      @options = {
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Harvest-Account-Id' => account_id,
          'User-Agent' => account_id
        }
      }
    end

    def authenticated?
      self.class.get('/users/me', @options).success?
    end

    def clients
      JSON.parse(self.class.get('/clients', @options).body)['clients']
    end

    # https://help.getharvest.com/api-v2/timesheets-api/timesheets/time-entries/
    def time_entries(client_id:)
      current_page = 0
      response = nil
      entries = []

      while current_page == 0 || response['total_pages'] > current_page
        current_page += 1
        response = fetch_entries(client_id, current_page)
        entries.push(*response['time_entries'])
      end
      entries.reverse
    end

    private

    def fetch_entries(client_id, page)
      JSON.parse(self.class.get('/time_entries', @options.deep_merge(
        query: {
          client_id: client_id,
          page: page
        }
      )).body)
    end
  end
end