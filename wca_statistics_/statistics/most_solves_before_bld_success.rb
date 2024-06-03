require_relative "../core/grouped_statistic"

class MostSolvesBeforeBldSuccess < GroupedStatistic
  def initialize
    @title = "Most solves before getting a successful BLD attempt"
    @table_header = { "Attempts" => :right, "Person" => :left }
  end

  def query
    <<-SQL
      SELECT
        eventId event_id,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        value1, value2, value3, value4, value5
      FROM Results
      JOIN Persons person ON person.wca_id = personId AND person.subId = 1
      JOIN Competitions competition ON competition.id = competitionId
      JOIN RoundTypes round_type ON round_type.id = roundTypeId
      JOIN Events event ON event.id = eventId
      WHERE eventId IN ('333bf', '444bf', '555bf', '333mbf')
      ORDER BY competition.start_date, round_type.rank
    SQL
  end

  def transform(query_results)
    Events::BLD.map do |event_id, event_name|
      attempts_with_people = query_results
        .select { |result| result["event_id"] == event_id }
        .group_by { |result| result["person_link"] }
        .map do |person_link, results|
          attempts_before_success = results
            .map! { |result| (1..5).map { |n| result["value#{n}"] } }
            .flatten
            .select { |time| time == -1 || time > 0 } # Grab times only. Reject skipped and DNS sovles.
            .find_index { |time| time > 0 }
          [attempts_before_success, person_link]
        end
        .reject { |attempts_before_success, person_link| attempts_before_success.nil? }
        .sort_by! { |attempts_before_success, person_link| -attempts_before_success }
        .first(20)
      [event_name, attempts_with_people]
    end
  end
end
def transform(query_results)
    Events::BLD.map do |event_id, event_name|
      attempts_with_people = query_results
        .select { |result| result["event_id"] == event_id }
        .group_by { |result| result["person_link"] }
        .map do |person_link, results|
          attempts_before_success = results
            .map { |result| (1..5).map { |n| result["value#{n}"] } }
            .flatten
            .select { |time| time == -1 || time > 0 } # Grab times only. Reject skipped and DNS solves.
            .find_index { |time| time > 0 }
          [attempts_before_success, person_link]
        end
        .reject { |attempts_before_success, _| attempts_before_success.nil? }
        .sort_by! { |attempts_before_success, _| -attempts_before_success }
        .first(20)
      [event_name, attempts_with_people]
    end
  end

  def generate_html(transformed_data)
    html_content = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>#{@title}</title>
  <style>
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th, td {
      padding: 8px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background-color: #f2f2f2;
    }
  </style>
</head>
<body>
  <h1>#{@title}</h1>
HTML

    transformed_data.each do |event_name, attempts_with_people|
      html_content += <<-HTML
  <h2>#{event_name}</h2>
  <table>
    <thead>
      <tr>
        <th>Attempts</th>
        <th>Person</th>
      </tr>
    </thead>
    <tbody>
HTML

      attempts_with_people.each do |attempts_before_success, person_link|
        html_content += <<-HTML
      <tr>
        <td>#{attempts_before_success}</td>
        <td>#{person_link}</td>
      </tr>
HTML
      end

      html_content += <<-HTML
    </tbody>
  </table>
HTML
    end

    html_content += <<-HTML
</body>
</html>
HTML

    File.open("output.html", "w") { |file| file.write(html_content) }
  end
end

# Example usage
# Assuming you have a method to get query results, e.g., `fetch_query_results`
most_solves = MostSolvesBeforeBldSuccess.new
query_results = fetch_query_results(most_solves.query)  # Implement this method to get query results
transformed_data = most_solves.transform(query_results)
most_solves.generate_html(transformed_data)
