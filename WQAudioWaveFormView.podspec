#
# Be sure to run `pod lib lint WQAudioWaveFormView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WQAudioWaveFormView'
  s.version          = '0.1.1'
  s.summary          = 'A short description of WQAudioWaveFormView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/qiqiw124/WQAudioWaveFormView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wqq' => 'qiqiw124@163.com' }
  s.source           = { :git => 'https://github.com/qiqiw124/WQAudioWaveFormView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'WQAudioWaveFormView/Classes/**/*'

  s.subspec 'Wave' do |subWave|
     subWave.source_files = 'WQAudioWaveFormView/Classes/Wave/*.{h,m}'
     end
  s.subspec 'BackScroll' do |subScroll|
     subScroll.source_files = 'WQAudioWaveFormView/Classes/BackScroll/*.{h,m}'
     end
    

  
  # s.resource_bundles = {
  #   'WQAudioWaveFormView' => ['WQAudioWaveFormView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
