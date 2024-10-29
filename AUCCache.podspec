
Pod::Spec.new do |s|
  s.name             = 'AUCCache'
  s.version          = '0.0.2'
  s.summary          = 'a new cache pod library'
  s.homepage         = 'http://george.xue@appgitlab.unicornfintech.com:2190/lee.li/AUCCache.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'George' => 'george.xue@hytechc.com' }
  s.source           = { :git => 'git@github.com:GeorgeTang123/AUCache.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'AUCCache/Classes/*.{h,m}'
end
