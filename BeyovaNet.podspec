Pod::Spec.new do |s|
  s.name        = "BeyovaNet"
  s.version     = "0.0.3"
  s.summary     = "BeyovaNet makes it easy to deal with Networking and Codable in Swift"
  s.homepage    = "https://github.com/Beyova/BeyovaNet"
  s.license     = { :type => "MIT" }
  s.authors     = { "canius" => "canius.chu@outlook.com" }

  s.requires_arc = true
  s.osx.deployment_target = "10.12"
  s.ios.deployment_target = "10.0"
  s.source   = { :git => "https://github.com/Beyova/BeyovaNet.git", :tag => s.version }
  s.source_files = "Source/*.swift"
end
