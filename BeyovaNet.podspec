Pod::Spec.new do |s|
  s.name        = "BeyovaNet"
  s.version     = "0.0.5"
  s.summary     = "BeyovaNet makes it easy to deal with Networking and Codable in Swift"
  s.homepage    = "https://github.com/Beyova/BeyovaNet"
  s.license     = { :type => "MIT" }
  s.authors     = { "canius" => "canius.chu@outlook.com" }

  s.requires_arc = true
  s.osx.deployment_target = "10.9"
  s.ios.deployment_target = "8.0"
  s.source   = { 
    :git => "https://github.com/Beyova/BeyovaNet.git", 
    :tag => s.version,
    :submodules => true
  }
  s.default_subspecs = 'Core'
  s.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-DBNCocoaPods' }

  s.subspec 'Core' do |ss|    
    ss.source_files = "Sources/*.swift"
    ss.osx.deployment_target = "10.9"
    ss.ios.deployment_target = "8.0"
  end

  s.subspec 'Promise' do |ss|    
    ss.source_files = "BeyovaNetPromise/Sources/*.swift"
    ss.osx.deployment_target = "10.9"
    ss.ios.deployment_target = "8.0"
    ss.dependency 'PromiseKit/CorePromise'
    ss.dependency 'BeyovaNet/Core'
  end

end
