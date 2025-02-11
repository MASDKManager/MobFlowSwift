# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'MobFlowiOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Test
  pod 'Adjust', '~> 5.0.0'
  pod 'ReachabilitySwift'
  pod 'Firebase'
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseRemoteConfig' 
  pod 'OneSignalXCFramework' 
  pod 'TikTokBusinessSDK', '~> 1.3.2'
#  pod 'AppLovinSDK'
#  pod 'AppLovinMediationVungleAdapter'
#  pod 'AppLovinMediationFacebookAdapter'
#  pod 'AppLovinMediationByteDanceAdapter'
#  pod 'AppLovinMediationUnityAdsAdapter'
  pod 'AppsFlyerFramework'
  pod 'FBSDKCoreKit', '~> 17.0.0'
  pod 'FBAudienceNetwork'
  pod 'Clarity', '2.2.1'
#  pod 'UnityAds'
  
  pod 'Appodeal', '3.4.1'
  pod 'APDBidMachineAdapter', '3.4.1.1'
  pod 'APDBidonAdapter', '3.4.1.0'
  pod 'APDIABAdapter', '3.4.1.0'
  pod 'APDSentryAdapter', '3.4.1.0'
  pod 'APDUnityAdapter', '3.4.1.0'
  pod 'BidonAdapterBidMachine', '0.7.1.1'
  pod 'BidonAdapterUnityAds', '0.7.1.0'
  
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
  
