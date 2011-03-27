class ContributionsController < SubdomainController
  def index
    people_columns = [
      :id, :first_name, :last_name
    ].map { |attr| "people.#{attr}" }.join(', ')
    aggregations = [
      :count, :sum
    ].map { |aggr| "#{aggr}(contributions.amount) AS contributions_#{aggr}" }.
      join(', ')

    @people = Person.joins(:roles).
      where('roles.chamber_id' => @state.chambers).
      joins(:contributions).
      group(people_columns).
      select("#{people_columns}, #{aggregations}")


  end
end
