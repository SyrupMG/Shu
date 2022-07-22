#
# Be sure to run `pod lib lint Shu.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Shu'
  s.version          = '2.1.1'
  s.summary          = 'ApiService'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'High level Api Service, that wraps the alamofire'

  s.homepage         = 'https://github.com/SyrupMG/Shu'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'abesmon' => 'abesmon@gmail.com' }
  s.source           = { :git => 'https://github.com/SyrupMG/Shu.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.swift_version = '5.3'
  s.default_subspec = "Core"
  
  s.subspec "Core" do |ss|
    ss.source_files = 'Shu/Classes/Core/**/*.{swift}'
    s.dependency 'Alamofire', "~> 5.4"
    s.dependency 'PromiseKit', "~> 6.8"
  end
  
  s.subspec "CRUD" do |ss|
    ss.source_files = 'Shu/Classes/CRUD/**/*.{swift}'
    ss.dependency 'Shu/Core'
  end
  
  s.subspec "SwiftyBeaverLog" do |ss|
    ss.source_files = 'Shu/Classes/SwiftyBeaverLog/**/*.{swift}'
    ss.dependency 'Shu/Core'
    ss.dependency 'SwiftyBeaver', "~> 1.9"
  end
  
end
