require 'lexicon'

namespace :lexicon do

  include Lexicon
  desc ""
  task import_departments: :environment do
    ENV["SHAPEFILE"]= Rails.root.join("tmp","departments","departements-20140306-5m.shp").to_s
    ENV["FILENAME"]=File.join(Rails.root.join('plugins', 'manuring', "db","lexicon","departments.yml").to_s).to_s
    ENV["NAME_ATTR"]="code_insee"
    ENV["NATURE"]="Department"
    ENV["SRID"]="2154"
    ENV["PREFIX"]="FR-"

    url = 'http://osm13.openstreetmap.fr/~cquest/openfla/export/departements-20140306-5m-shp.zip'
    unless File.exists?(Rails.root.join("tmp","departments","departements-20140306-5m.shp"))
      FileUtils.mkdir_p 'tmp/departements'
      dir = Rails.root.join("tmp","departments")
      open(url) do |file|
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end
      end
    end

    Rake::Task['lexicon:shapefile_to_yaml'].invoke
    FileUtils.rm_r dir
  end
end