platform :ios, '10.0'

target 'ScreamTracker' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for nagrywanie2
  pod 'AudioKit', '4.5.1'
    pod 'Google-Mobile-Ads-SDK'
    pod 'Charts', '3.2'
    pod 'Firebase/Core'
    pod 'Fabric', '~> 1.7.11'
    pod 'Crashlytics', '~> 3.10.7'
    pod 'ProgressHUD'
    pod 'GoogleMobileAdsMediationIronSource'
    
    post_install do |installer|
        sharedLibrary = installer.aggregate_targets.find { |aggregate_target| aggregate_target.name == 'Pods-[MY_FRAMEWORK_TARGET]' }
        installer.aggregate_targets.each do |aggregate_target|
            if aggregate_target.name == 'Pods-[MY_APP_TARGET]'
                aggregate_target.xcconfigs.each do |config_name, config_file|
                    sharedLibraryPodTargets = sharedLibrary.pod_targets
                    aggregate_target.pod_targets.select { |pod_target| sharedLibraryPodTargets.include?(pod_target) }.each do |pod_target|
                        pod_target.specs.each do |spec|
                            frameworkPaths = unless spec.attributes_hash['ios'].nil? then spec.attributes_hash['ios']['vendored_frameworks'] else spec.attributes_hash['vendored_frameworks'] end || Set.new
                        frameworkNames = Array(frameworkPaths).map(&:to_s).map do |filename|
                            extension = File.extname filename
                            File.basename filename, extension
                        end
                        frameworkNames.each do |name|
                            if name != '[DUPLICATED_FRAMEWORK_1]' && name != '[DUPLICATED_FRAMEWORK_2]'
                                raise("Script is trying to remove unwanted flags: #{name}. Check it out!")
                            end
                            puts "Removing #{name} from OTHER_LDFLAGS"
                            config_file.frameworks.delete(name)
                        end
                    end
                end
                xcconfig_path = aggregate_target.xcconfig_path(config_name)
                config_file.save_as(xcconfig_path)
            end
        end
    end
    
    
   
   
   #post_install do |installer|
        
        #installer.pods_project.targets.each do |target|
            #target.build_configurations.each do |config|
                #if target.name == 'Charts'
                    #config.build_settings['SWIFT_VERSION'] = '4.2'
                    #else
                    #config.build_settings['SWIFT_VERSION'] = '4.1'
                    #end
                #end
            #end
        #    end
end

end
