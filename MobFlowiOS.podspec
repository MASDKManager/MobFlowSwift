Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.name         = "MobFlowiOS"
  spec.version      = "3.2.8"
  spec.requires_arc =  true
  spec.summary      = "An sdk that inialize multiple library in order to run custom ad screen of MobFlowiOS."
  spec.description  = <<-DESC
  An sdk that inialize multiple library in order to run custom ad screen

  u can use it inside appdelegate

  of MobFlowiOS.
                      DESC
  spec.homepage     = 'https://github.com/MASDKManager/MobFlowSwift'
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Maarouf" => "mobsdk10@gmail.com" }
  spec.source = {
    :git => 'https://github.com/MASDKManager/MobFlowSwift.git',
    :tag => spec.version.to_s
  }
  spec.framework = 'UIKit'
  spec.dependency 'Adjust','>= 5.0.0'
  spec.dependency 'ReachabilitySwift'
  spec.dependency 'Firebase'
  spec.dependency 'FirebaseAnalytics'
  spec.dependency 'FirebaseCrashlytics'
  spec.dependency 'FirebaseRemoteConfig'  
  spec.dependency 'OneSignalXCFramework'
  spec.dependency 'TikTokBusinessSDK', '>= 1.3.2'
  spec.dependency 'AppsFlyerFramework'
  spec.dependency 'FBSDKCoreKit','>= 17.0.0'
  spec.dependency 'FBAudienceNetwork'
  spec.dependency 'Clarity', '2.2.1'
  spec.dependency 'Appodeal', '3.4.1'
  spec.dependency 'APDBidMachineAdapter', '3.4.1.1'
  spec.dependency 'APDBidonAdapter', '3.4.1.0'
  spec.dependency 'APDIABAdapter', '3.4.1.0'
  spec.dependency 'APDSentryAdapter', '3.4.1.0'
  spec.dependency 'APDUnityAdapter', '3.4.1.0'
  spec.dependency 'BidonAdapterBidMachine', '0.7.1.1'
  spec.dependency 'BidonAdapterUnityAds', '0.7.1.0'
  spec.source_files  = "MobFlowiOS/**/*.{h,m,swift}"
  spec.resource_bundles = {
    'MobFlowiOS' => ['MobFlowiOS/**/*.{storyboard,xib,xcassets,lproj,png,xcprivacy}']
  }
  spec.swift_version = '5'
  spec.ios.deployment_target = '14.0'

  spec.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  spec.static_framework = true
end
