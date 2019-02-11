Pod::Spec.new do |spec|
  spec.name         = 'TravelKit'
  spec.version      = '2.0.3'
  spec.license      = 'MIT'
  spec.homepage     = 'https://github.com/sygic-travel/apple-sdk'
  spec.authors      = 'Tripomatic s.r.o.', 'Michal Zelinka'
  spec.summary      = 'Travel SDK for travelling projects'
  spec.source       = { :http => 'https://github.com/sygic-travel/apple-sdk/releases/download/v2.0.3/TravelKit-2.0.3-iOS.zip' }
  spec.documentation_url = 'http://docs.sygictravelapi.com/apple-sdk/latest'
  spec.module_name  = 'TravelKit'

  spec.platform = :ios
  spec.ios.deployment_target  = '8.2'

  spec.framework      = 'SystemConfiguration'
  spec.ios.framework  = 'CoreTelephony'
  spec.ios.library = 'sqlite3'

  spec.ios.vendored_frameworks = 'TravelKit.framework'
end
