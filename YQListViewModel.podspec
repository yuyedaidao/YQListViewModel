#
# Be sure to run `pod lib lint YQListViewModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YQListViewModel'
  s.version          = '0.1.9'
  s.summary          = 'YQListViewModel.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = '基于RxDataSource便捷处理列表数据刷新和加载更多的ViewModel'

  s.homepage         = 'https://github.com/yuyedaidao/YQListViewModel'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wyqpadding@gmail.com' => 'wyqpadding@gmail.com' }
  s.source           = { :git => 'https://github.com/yuyedaidao/YQListViewModel.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.swift_version = '5.3'
  s.ios.deployment_target = '10.0'

  s.source_files = 'YQListViewModel/Classes/**/*'
  
  #s.resource_bundles = {
  #  'YQListViewModel' => ['YQListViewModel/Assets/*.png']
  #}

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'Moya/RxSwift'
  # s.dependency 'SnapKit
  s.dependency 'RxDataSources'
end
