Pod::Spec.new do |spec|
  spec.name         = "TraceWiseSDK"
  spec.version      = `git describe --tags --exact-match 2>/dev/null | sed 's/^v//'`.strip.empty? ? "1.0.0" : `git describe --tags --exact-match 2>/dev/null | sed 's/^v//'`.strip
  spec.summary      = "TraceWise SDK for iOS - Product traceability and digital product passports"
  spec.description  = <<-DESC
    TraceWise SDK provides comprehensive product traceability features including:
    - Digital Product Passport (DPP) management
    - Product search and resolution
    - CIRPASS integration
    - Lifecycle event tracking
    - Enterprise subscription management
  DESC

  spec.homepage     = "https://github.com/tracewise420/TraceWise-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "TraceWise" => "support@tracewise.io" }

  spec.ios.deployment_target = "15.0"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/tracewise420/TraceWise-iOS.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/TraceWiseSDK/**/*.swift"

  spec.framework    = "Foundation"
  spec.requires_arc = true
  
  spec.dependency "Firebase/Auth"
end