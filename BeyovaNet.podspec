Pod::Spec.new do |s|
  s.name        = "BeyovaNet"
  s.version     = "0.0.4"
  s.summary     = "BeyovaNet makes it easy to deal with Networking and Codable in Swift"
  s.homepage    = "https://github.com/Beyova/BeyovaNet"
  s.license     = { :type => "MIT" }
  s.authors     = { "canius" => "canius.chu@outlook.com" }

  s.requires_arc = true
  s.osx.deployment_target = "10.12"
  s.ios.deployment_target = "10.0"
  s.source   = { :git => "https://github.com/Beyova/BeyovaNet.git", :tag => s.version }
  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|    
    ss.source_files = "Source/*.swift"
    ss.osx.deployment_target = "10.12"
    ss.ios.deployment_target = "10.0"
  end

  s.subspec 'Promise' do |ss|    
    ss.source_files = "BeyovaNetPromise/Sources/*.swift"
    ss.osx.deployment_target = "10.12"
    ss.ios.deployment_target = "10.0"
    ss.dependency 'BeyovaNet/Core'
  end

end
