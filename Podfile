# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'MobFlowiOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Test
#  pod 'Adjust'
  pod 'ReachabilitySwift'
  pod 'Firebase'
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseRemoteConfig' 
  pod 'OneSignalXCFramework' 
  pod 'TikTokBusinessSDK', '~> 1.3.2'
  pod 'AppLovinSDK'
  pod 'AppLovinMediationVungleAdapter'
  pod 'AppLovinMediationFacebookAdapter'
  pod 'AppLovinMediationByteDanceAdapter'
  pod 'AppLovinMediationUnityAdsAdapter'
  pod 'AppsFlyerFramework'
  pod 'FBSDKCoreKit', '~> 16.0.0'
  pod 'FBAudienceNetwork'
  pod 'Adjust', '~> 4.38.4'
  pod 'Clarity'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end

    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
      # some older pods don't support some architectures, anything over iOS 11 resolves that
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'

      end
    end
  end
 end
  
