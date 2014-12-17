pod 'Parse', '1.6.0'
pod 'ParseFacebookUtils', '1.6.0'
pod 'ParseUI', '1.0.2'
pod 'ParseCrashReporting', '1.6.0'
pod 'AWSiOSSDKv2', '2.0.13'
pod 'Facebook-iOS-SDK', '3.21.1'
pod 'CrittercismSDK', '4.3.7'
pod 'MagicalRecord', '2.2'
pod 'AFNetworking', '2.4.1'

post_install do |installer|
  installer.project.targets.each do |target|
    target.build_configurations.each do |config|
      s = config.build_settings['GCC_PREPROCESSOR_DEFINITIONS']
    if s==nil then s = [ '$(inherited)' ] end
    s.push('MR_ENABLE_ACTIVE_RECORD_LOGGING=0');
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = s
    end
  end
end
