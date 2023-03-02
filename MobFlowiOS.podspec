Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.name         = "MobFlowiOS"
  spec.version      = "1.6.6"
  spec.requires_arc =  true
  spec.summary      = "An sdk that inialize multiple library in order to run custom ad screen of MobFlowiOS."
  spec.description  = <<-DESC
  An sdk that inialize multiple library in order to run custom ad screen

  u can use it inside appdelegate

  of MobFlowiOS.
                      DESC
  spec.homepage     = 'https://github.com/MASDKManager/ios-html-sdk'
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Maarouf" => "mobsdk10@gmail.com" }
  spec.source = {
    :git => 'https://github.com/MASDKManager/ios-html-sdk.git',
    :tag => spec.version.to_s
  }
  spec.framework = 'UIKit'
  spec.dependency 'Adjust'
  spec.dependency 'ReachabilitySwift'
  spec.dependency 'Firebase'
  spec.dependency 'FirebaseAnalytics'
  spec.dependency 'FirebaseCrashlytics'
  spec.dependency 'FirebaseRemoteConfig'
  spec.dependency 'FirebaseDynamicLinks'
  spec.dependency 'YandexMobileMetrica/Dynamic', '~> 4.2.0'
  spec.source_files  = "MobFlowiOS/**/*.{h,m,swift}"
  spec.resource_bundles = {
    'MobFlowiOS' => ['MobFlowiOS/**/*.{storyboard,xib,xcassets,lproj,png}']
  }
  spec.swift_version = '5'
  spec.ios.deployment_target = '14.0'

  spec.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  spec.static_framework = true
end
