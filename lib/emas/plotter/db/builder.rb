module EMAS
  module Plotter
    module DB
      class Builder
        DATABASE_DIR = '.db'.freeze

        attr_reader :database

        def build_database
          ensure_database_dir

          @database = create_database

          schema_loader = SchemaLoader.new database
          schema_loader.load_schema

          database
        end

        private

        def create_database
          Sequel.sqlite database_path
        end

        def ensure_database_dir
          FileUtils.mkdir_p DATABASE_DIR unless File.directory? DATABASE_DIR
        end

        def database_path
          @database_path ||= File.join DATABASE_DIR, database_filename
        end

        def database_filename
          @database_filename ||= "#{SecureRandom.hex}.db"
        end
      end
    end
  end
end
