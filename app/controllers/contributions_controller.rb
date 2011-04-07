class ContributionsController < SubdomainController
  def index
    people_columns = [
      :id, :first_name, :last_name, :suffix, :photo_file_name
    ].map { |attr| "people.#{attr}" }.join(', ')
    aggregations = [
      :count, :sum, :avg
    ].map { |aggr| "#{aggr}(contributions.amount) AS contributions_#{aggr}" }.
      join(', ')
    party_column = <<-EOF
      CASE
        WHEN MAX(roles.party) = MIN(roles.party)
        THEN MAX(roles.party)
        ELSE 'Multiple'
      END AS party
    EOF

    @people = Person.joins(:roles).
      where('roles.chamber_id' => @state.chambers).
      joins(:contributions).
      group(people_columns).
      select("#{people_columns}, #{aggregations}, #{party_column}")
  end

  def person
    extra_people_columns = {
      :district_name => 'current_district_name_for(people.id)',
      :party => 'current_party_for(people.id)'
    }.map { |name, value| "#{value} AS #{name}" }.join(', ')

    @person = Person.where(:id => params[:person_id]).
      select("people.*, #{extra_people_columns}").
      first

    render :layout => nil
  end
end
