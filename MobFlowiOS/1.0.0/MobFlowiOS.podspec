Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.name         = "MobFlowiOS"
  spec.version      = "1.0.0"
  spec.requires_arc = true
  spec.summary      = "An sdk that inialize multiple library in order to run custom ad screen of MobFlowiOS."
  spec.description  = <<-DESC
  An sdk that inialize multiple library in order to run custom ad screen
  
  u can use it inside appdelegate.
  
  of MobFlowiOS.
                      DESC
  spec.homepage     = 'https://github.com/MASDKManager/IOS-HTML-SDK'
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Vishnu" => "vishnu@mobiboxsoftech.com" }
  spec.source = { 
    :git => 'https://github.com/MASDKManager/IOS-HTML-SDK.git', 
    :tag => spec.version.to_s 
  }
  spec.framework = 'UIKit'
  spec.dependency 'Adjust'
  spec.dependency 'ReachabilitySwift'
  spec.dependency 'Firebase'
  spec.dependency 'Firebase/Analytics'
  spec.dependency 'Firebase/Messaging'
  spec.dependency 'Branch'
  spec.dependency 'YandexMobileMetrica/Dynamic'
  spec.dependency 'Firebase/Crashlytics'
  spec.source_files  = "MobFlowiOS/*.{swift}"
  spec.resources = "MobFlowiOS/*.{storyboard,xib,xcassets,lproj,png}"
  spec.swift_version = '5'
  spec.ios.deployment_target = '14.0'

end