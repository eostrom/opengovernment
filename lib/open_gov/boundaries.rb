module OpenGov
  class Boundaries < Resources
    CONGRESS_FIPS_CODE = '99' # The special FIPS code used for federal/congressional data

    AREA_CONGRESSIONAL_DISTRICT = 'cd' # Abbreviations for geographic area codes (ga)
    AREA_STATE_UPPER = 'su'
    AREA_STATE_LOWER = 'sl'

    VINTAGE = '06' # Which census datasets will we fetch?
    CONGRESS = '110' # See filename conventions at http://www.census.gov/geo/www/cob/filenames.html

    # The special vintage parameter being used for state upper/lower files right now
    # I don't know why it is so.

    ALT_VINTAGE = 'd11'

    # These are just templates - to be evaluated per-state.
    CENSUS_SHP_URL = 'http://www.census.gov/geo/cob/bdy/#{ga}/#{ga}#{vintage_or_congress}shp/'
    CENSUS_SHP_FN = '#{ga}#{fips_code}_#{vintage}_shp.zip'

    # TODO: Update these in June for new 2011 data
    CENSUS_STATES_URL = 'http://www.census.gov/geo/cob/bdy/st/st00shp/st99_d00_shp.zip'
    STATES_VINTAGE = '00'
    CENSUS_STATES_SHPFN = "st99_d#{STATES_VINTAGE}.shp"

    AT_LARGE_LSADS = ['c1', 'c4'].freeze

    def fetch
      FileUtils.mkdir_p(Settings.shapefiles_dir)
      Dir.chdir(Settings.shapefiles_dir)

      fetch_us_congress
      fetch_state_boundaries
      
      # Get state legislature files, when available
      State.loadable.find(:all, :conditions => "fips_code is not null").each do |state|
        fetch_one(state)
      end
    end
    
    def fetch_one(state)
      FileUtils.mkdir_p(Settings.shapefiles_dir)
      Dir.chdir(Settings.shapefiles_dir)

      {"upper" => AREA_STATE_UPPER, "lower" => AREA_STATE_LOWER}.each do |name, house|

        # Unicameral states don't have lower house files.
        unless state.unicameral == true && house == AREA_STATE_LOWER
          process_one(house, state.fips_code, "#{state.name} #{name} house")
        end
      end
    end

    def fetch_us_congress
      FileUtils.mkdir_p(Settings.shapefiles_dir)
      Dir.chdir(Settings.shapefiles_dir)

      # Get the federal data.
      process_one(AREA_CONGRESSIONAL_DISTRICT, CONGRESS_FIPS_CODE, "US Congress")
    end

    def fetch_state_boundaries
      FileUtils.mkdir_p(Settings.shapefiles_dir)
      Dir.chdir(Settings.shapefiles_dir)

      puts "---------- Downloading state boundary shapefile"
      shpfile = download(CENSUS_STATES_URL, :unzip => true)
    end

    def import_states
      # Import the single shapefile for state boundaries
      shpfile = File.join(Settings.shapefiles_dir, CENSUS_STATES_SHPFN)

      unless File.exists?(shpfile)
        puts "File not found: #{shpfile}"
        return
      end
      
      OpenGov::Shapefile.process(shpfile, :drop_table => true)

      table_name = File.basename(shpfile, '.shp')
      puts "Migrating #{table_name} table into state_boundaries"

      arTable = Class.new(ActiveRecord::Base) do
        set_table_name table_name
      end

      # IDs are always 
      StateBoundary.delete_all
      
      arTable.find(:all).each do |shape|
        state = State.find_by_fips_code(shape.state.to_i)

        # puts "#{shape.state}: #{state.abbrev}"

        s = StateBoundary.new(
          :state_id => state.id,
          :vintage => STATES_VINTAGE,
          :fips_code => shape.state.to_i,
          :lsad => shape.lsad,
          :region => shape.region,
          :division => shape.division,
          :geom => shape.the_geom
        )
        
        s.save!
      end
    end

    def import_districts
      Dir.glob(File.join(Settings.shapefiles_dir, '{sl,su,cd}*.shp')).each do |shpfile|
        import_districts(shpfile)
      end
    end

    def import_districts(shpfile)
      puts "Inserting shapefile #{File.basename(shpfile)}"
      OpenGov::Shapefile.process(shpfile, :drop_table => true)

      table_name = File.basename(shpfile, '.shp')
      puts "Migrating #{table_name} table into districts"

      arTable = Class.new(ActiveRecord::Base) do
        set_table_name table_name
      end

      # All district shapefiles will have at least:
      # - state (fips_code)
      # - the_geom (geometry)
      # - lsad (district type)

      # If table_name starts with sl (lower chamber):
      # - sldl (district number, or ZZZ for undistricted areas)

      # If it starts with su (upper chamber):
      # - sldu (district number, or ZZZ)

      # and if it starts with cd (congress):
      # - cd (district number, or 00 for at large)
      table_type = table_name[0, 2]

      arTable.find(:all).each do |shape|

        state = State.find_by_fips_code(shape.state)

        if [AREA_STATE_LOWER, AREA_STATE_UPPER].include?(table_type)
          legislature = state.legislature
        else
          # It's federal; so it's always congress.
          legislature = Legislature::CONGRESS
        end

        if legislature
          # We're not using the LSAD for state houses, because
          # there are lots of LSADs we don't care about.
          chamber = case table_type
            when AREA_STATE_UPPER then
              legislature.upper_chamber
            when AREA_STATE_LOWER, AREA_CONGRESSIONAL_DISTRICT then
              legislature.lower_chamber
            else
              raise "Unsupported table type #{table_type} encountered"
          end

          vintage = case table_type
            when AREA_STATE_LOWER, AREA_STATE_UPPER # State
              VINTAGE
            else # Federal
              CONGRESS
          end

          census_sld = shape[:cd] || shape[:sldl] || shape[:sldu]

          d = District.find_or_initialize_by_census_sld_and_chamber_id_and_state_id(census_sld, chamber.id, state.id)

          d.update_attributes!(
            :name => district_name_for(shape),
            :vintage => vintage,
            :state => state,
            :at_large => AT_LARGE_LSADS.include?(shape.lsad.downcase),
            :census_district_type => shape.lsad,
            :geom => shape.the_geom
          )

        end

      end

      puts "Dropping #{table_name} conversion table"
      OpenGov::Shapefile.cleanup(shpfile)
    end

    def district_name_for(shape)
      census_name_column = (shape[:cd] || shape[:name])
      fips_code = shape.state.to_i

      # Some states have sane district names in the dataset
      # We check via the FIPS codes.
      if [32, 25].include?(fips_code)
        census_name_column
      elsif fips_code == 50
        # These have names like "Orleans-Caledonia-1"
        "District " + census_name_column
      elsif fips_code == 33 && shape.lsad == "LL"
        "District " + census_name_column
      else
        "District " + census_name_column.gsub(/^0+/,'')
      end
    end

    protected
    def process_one(ga, fips_code, area_name)
      census_fn = census_fn_for(ga, fips_code)
      curl_ops = File.exists?(census_fn) ? "-Lfz #{census_fn}" : '-Lf'

      puts "---------- Downloading the district shapefile for #{area_name}"
      download(census_url_for(ga, fips_code), :curl_ops => curl_ops, :output_fn => census_fn, :unzip => true)
    end

    def census_url_for(ga, fips_code)
      # ga is geographic area - eg. "cd" for congressional district
      # Only provide congress number (eg. 110) if we're looking for congressional districts
      vintage_or_congress = (ga == AREA_CONGRESSIONAL_DISTRICT ? CONGRESS : VINTAGE)
      return eval('"' + CENSUS_SHP_URL + '"') + census_fn_for(ga, fips_code)
    end

    def census_fn_for(ga, fips_code)
      fips_code = "%02d" % fips_code
      vintage = (ga == AREA_CONGRESSIONAL_DISTRICT ? CONGRESS : ALT_VINTAGE)
      eval('"' + CENSUS_SHP_FN + '"')
    end

    def shpfile_for(zipped_filename)
      zipped_filename.match(/^(.*)_shp.zip$/)[1] + ".shp"
    end
  end
end
