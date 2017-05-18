Pod::Spec.new do |s|
  s.name             = 'SwiftScraper'
  s.version          = '0.3.0'
  s.summary          = 'Screen scraping orchestration for iOS in Swift.'
  s.description      = <<-DESC
Framework that makes it easy to integrate and orchestrate screen scraping with your Swift iOS app.
                       DESC

  s.homepage         = 'https://github.com/cweatureapps/SwiftScraper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cweatureapps' => 'cweatureapps@gmail.com' }
  s.source           = { :git => 'https://github.com/cweatureapps/SwiftScraper.git', :tag => s.version.to_s }
  s.resource_bundles = { "SwiftScraper" => ["Resources/**/*.{js}"] }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/**/*.{h,m,swift}'
  s.frameworks = 'UIKit', 'WebKit'
  s.dependency 'Observable-Swift', '~> 0.7'
end
