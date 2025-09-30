Pod::Spec.new do |spec|
  spec.name         = "TraceWiseSDK"
  spec.version      = "1.0.0"
  spec.summary      = "TraceWise SDK for iOS - Product traceability and digital product passports"
  spec.description  = <<-DESC
    TraceWise SDK provides comprehensive product traceability features including:
    - Digital Product Passport (DPP) management
    - Product search and resolution
    - CIRPASS integration
    - Lifecycle event tracking
    - Enterprise subscription management
  DESC

  spec.homepage     = "https://github.com/tracewise/tracewise-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "TraceWise" => "support@tracewise.io" }

  spec.ios.deployment_target = "13.0"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/tracewise/tracewise-ios-sdk.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/TraceWiseSDK/**/*.swift"

  spec.framework    = "Foundation"
  spec.requires_arc = true

  spec.dependency "SwiftUI"
end