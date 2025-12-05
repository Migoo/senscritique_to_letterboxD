#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'csv'
require 'time'

class SensCritiqueExporter
  GRAPHQL_URL = 'https://apollo.senscritique.com/'

  # Query avec otherUserInfos et pagination
  COLLECTION_QUERY = <<~GRAPHQL
    query UserCollection($username: String!, $universe: String!, $limit: Int!, $offset: Int!) {
      user(username: $username) {
        collection(universe: $universe, action: RATING, limit: $limit, offset: $offset) {
          total
          products {
            title
            yearOfProduction
            directors {
              name
            }
            otherUserInfos(username: $username) {
              rating
              dateDone
            }
          }
        }
      }
    }
  GRAPHQL

  def initialize(username)
    @username = username
    @movies = []
  end

  def export_to_csv(filename = 'senscritique_movies.csv')
    puts "Fetching movies for user: #{@username}..."
    fetch_all_movies

    if @movies.empty?
      puts "No movies found for user #{@username}"
      return
    end

    write_csv(filename)
    puts "\n✓ Exported #{@movies.count} movies to #{filename}"
  end

  private

  def fetch_all_movies
    offset = 0
    limit = 50
    total = nil

    loop do
      print "."
      $stdout.flush
      response = make_graphql_request(offset, limit)

      unless response
        puts "\nError fetching data."
        break
      end

      if response['errors']
        puts "\nGraphQL errors: #{response['errors'].map { |e| e['message'] }.join(', ')}"
        break
      end

      user = response.dig('data', 'user')
      unless user
        puts "\nUser '#{@username}' not found or profile is private."
        break
      end

      collection = user['collection']

      # Get total on first iteration
      total ||= collection['total']

      products = collection&.dig('products') || []

      break if products.empty?

      products.each do |product|
        @movies << parse_movie(product)
      end

      # Check if we've loaded all movies
      offset += limit
      break if offset >= total

      sleep(0.3) # Be nice to the API
    end

    if @movies.empty?
      puts "\nNo rated movies found. The profile might be private or contain no ratings."
      puts "Try adding ratings to your movies on SensCritique first."
    end
  end

  def make_graphql_request(offset, limit)
    uri = URI(GRAPHQL_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    # User-Agent mis à jour
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    request['Origin'] = 'https://www.senscritique.com'
    request['Referer'] = "https://www.senscritique.com/"

    request.body = {
      operationName: 'UserCollection',
      query: COLLECTION_QUERY,
      variables: {
        username: @username,
        universe: 'movie',
        limit: limit,
        offset: offset
      }
    }.to_json

    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else
      puts "\nHTTP #{response.code}: #{response.body[0..200]}"
      nil
    end
  rescue StandardError => e
    puts "\nError: #{e.message}"
    nil
  end

  def parse_movie(product)
    # Structure products avec otherUserInfos :
    # product contient 'otherUserInfos' avec 'rating' et 'dateDone'
    user_infos = product['otherUserInfos'] || {}
    directors = product['directors'] || []

    {
      title: product['title'],
      year: product['yearOfProduction'],
      directors: directors.map { |d| d['name'] }.join(', '),
      rating10: user_infos['rating'],
      watched_date: format_date(user_infos['dateDone'])
    }
  end

  def format_date(date_str)
    return nil if date_str.nil? || date_str.empty?
    Time.parse(date_str).strftime('%Y-%m-%d')
  rescue ArgumentError
    date_str
  end

  def write_csv(filename)
    CSV.open(filename, 'w', write_headers: true, headers: %w[Title Year Directors Rating10 WatchedDate]) do |csv|
      @movies.each do |movie|
        csv << [
          movie[:title],
          movie[:year],
          movie[:directors],
          movie[:rating10],
          movie[:watched_date]
        ]
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  username = ARGV[0] || 'migoo'
  output_file = ARGV[1] || 'senscritique_movies.csv'

  puts "SensCritique Exporter"
  puts "-" * 40

  exporter = SensCritiqueExporter.new(username)
  exporter.export_to_csv(output_file)
end