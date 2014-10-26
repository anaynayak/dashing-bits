require "httparty"

class Errbit

  attr_reader :api_key, :base_uri, :response

  def initialize(options)
    @api_key     = options[:api_key]
    @base_uri    = options[:base_uri]
    @response    = HTTParty.get(errbit_path).parsed_response
  end

  def projects
    ErrbitErrors.from_response(response).per_app.map do |app, errors|
      {
        name: app,
        errors: errors.unresolved.size,
        date: errors.last_date,
        status: errors.unresolved.size == 0 ? "green" : "red"
      }
    end
  end

  private

  def errbit_path
    "#{base_uri}/api/v1/problems?auth_token=#{api_key}&start_date=00:00&end_date=23:59"
  end

  class ErrbitErrors
    attr_reader :records
    def initialize(records)
      @records = records
    end

    def resolved
      records.select {|r| r.resolved}
    end

    def unresolved
      records - resolved
    end

    def self.from_response(response)
      records = response.collect {|r|
        ErrbitRecord.new(r)
      }
      ErrbitErrors.new(records)
    end

    def last_date
      records.sort_by {|x| x.date}.first.date
    end

    def per_app
      errors = records.group_by { |v| v.app}.map {|k, v|
        [k, ErrbitErrors.new(v)]
      }.flatten
      Hash[*errors]
    end

  end

  class ErrbitRecord
    attr_reader :record
    def initialize(record)
      @record = record
    end

    def app
      "#{record['app_name']} #{record['environment']}"
    end

    def where
      record["where"]
    end

    def resolved
      record["resolved"]
    end

    def message
      record["message"]
    end

    def date
      Time.parse(record["last_notice_at"]).utc
    end

    def to_hash
      {
        app: app,
        where: where,
        resolved: resolved,
        message: message,
        date: date
      }
    end
  end
end
