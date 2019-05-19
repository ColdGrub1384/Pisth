# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Pisth' do

  # ignore all warnings from all pods
  inhibit_all_warnings!
  
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Pisth

  pod 'NMSSH', :git => 'https://github.com/ColdGrub1384/NMSSH.git', :branch => 'master'
  pod 'Highlightr', :git => 'https://github.com/raspu/Highlightr.git', :branch => 'master'
  pod 'Zip'
  pod 'SwiftKeychainWrapper'
  pod 'BiometricAuthentication', '~> 2.1'
  pod 'ActionSheetPicker-3.0'
  pod 'Firebase/Core'
  pod 'PanelKit'
  pod 'WhatsNew', '~> 0.4.4'
  pod 'ObjectUserDefaults'
end

target 'PisthTests' do
    
    # ignore all warnings from all pods
    inhibit_all_warnings!
    
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    
    # Pods for Pisth
    
    pod 'NMSSH', :git => 'https://github.com/ColdGrub1384/NMSSH.git', :branch => 'master'
    pod 'Highlightr', :git => 'https://github.com/raspu/Highlightr.git', :branch => 'master'
    pod 'Zip'
    pod 'SwiftKeychainWrapper'
    pod 'BiometricAuthentication', '~> 2.1'
    pod 'ActionSheetPicker-3.0'
    pod 'Firebase/Core'
    pod 'PanelKit'
    pod 'WhatsNew', '~> 0.4.4'
    pod 'ObjectUserDefaults'
end

# post install
post_install do |installer|
    # Build settings
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings = config.build_settings.dup
            if config.build_settings['PRODUCT_MODULE_NAME'] == 'PanelKit'
                puts "Set Swift version for PanelKit"
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
            
            if config.build_settings['PRODUCT_MODULE_NAME'] == 'NMSSH'
              puts "Disable bitcode for NMSSH"
              config.build_settings['ENABLE_BITCODE'] = 'NO'
            end
        end
    end
end
