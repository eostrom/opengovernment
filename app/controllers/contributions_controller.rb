class ContributionsController < SubdomainController
  def index
    people_columns = [
      :id, :first_name, :middle_name, :last_name, :suffix, :photo_file_name
    ].map { |attr| "people.#{attr}" }.join(', ')
    aggregations = [
      :count, :sum, :avg
    ].map { |aggr| "#{aggr}(contributions.amount) AS contributions_#{aggr}" }.
      join(', ')
    extra_people_columns = {
      :district_name => 'current_district_name_for(people.id)',
      :party => 'current_party_for(people.id)'
    }.map { |name, value| "#{value} AS #{name}" }.join(', ')
    
    @people = Person.joins(:roles).
      where('roles.chamber_id' => @state.chambers).
      joins(:contributions).
      group(people_columns).
      includes([:chamber, :addresses]).
      select("#{people_columns}, #{extra_people_columns}, #{aggregations}")

    @people_json = @people.to_json(
      :include => :addresses,
      :methods => [
        :full_name, :permalink, :official_name, :district_name,
        :photo_url_pattern, :contributing_industries
      ])
  end
end
