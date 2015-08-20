module Manuring
  module Abaci

    class << self
      def root
        Pathname.new(__FILE__).dirname.dirname.dirname.join("abaci")
      end
      
      def load_files
        Dir.glob(root.join("*.csv")) do |path|
          name = File.basename(path, ".csv")
          puts "Set #{name.classify} with #{path}".red
          const_set(name.classify, ::Abaci.read(path))
        end
      end
    end

    # Load all abaci in one time
    load_files
  end
end
