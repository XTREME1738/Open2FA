module Fastlane
  module Actions
    module SharedValues
      PUBSPEC_BUILD_NUMBER = :PUBSPEC_BUILD_NUMBER
    end

    class GetBuildNumberFromPubspecAction < Action
      def self.run(params)
        require 'yaml'
		require 'pathname'
		
		pubspec_path = Pathname.new(File.join(Dir.pwd, 'pubspec.yaml'))
		unless pubspec_path.exist?
			UI.user_error!("pubspec.yaml file not found in #{pubspec_path}")
		end

		pubspec_content = YAML.load_file(pubspec_path)
		unless pubspec_content['version']
			UI.user_error!("Build number not found in pubspec.yaml")
		end
		
		build_number = pubspec_content['version'].split('+').last
		unless build_number
			UI.user_error!("Build number not found in pubspec.yaml")
		end

		Actions.lane_context[SharedValues::PUBSPEC_BUILD_NUMBER] = build_number
      end

	  #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Get build number from pubspec.yaml'
      end

      def self.available_options
		[]
      end

      def self.output
        [
          ['PUBSPEC_BUILD_NUMBER', 'The build number from pubspec.yaml']
        ]
      end

      def self.return_value
        
      end

      def self.authors
        ['XTREME1738']
      end

      def self.is_supported?(platform)
		true
      end
    end
  end
end
