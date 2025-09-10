Pod::Spec.new do |spec|
  spec.name         = "TraceWiseSDK"
  spec.version      = "1.0.1"
  spec.summary      = "Official TraceWise SDK for iOS with exact Trello task signatures"
  spec.description  = "TraceWise SDK provides seamless integration with TraceWise API for supply chain transparency and digital product passports."
  
  spec.homepage     = "https://github.com/tracewise420/TraceWise-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "TraceWise" => "sdk@tracewise.io" }
  
  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "10.15"
  spec.watchos.deployment_target = "6.0"
  spec.tvos.deployment_target = "13.0"
  
  spec.source       = { :git => "https://github.com/tracewise420/TraceWise-iOS.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/TraceWiseSDK/**/*.swift"
  
  spec.dependency "Firebase/Auth", "~> 10.0"
  
  spec.swift_version = "5.9"
end