#
# Be sure to run `pod lib lint HSAPICaller.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HSAPICaller'
  s.version          = '1.0.10'
  s.summary          = 'A short description of HSAPICaller.'
  s.description      = <<-DESC
       HSAPICaller is a wrapper written upon Moya (ref: Moya ) to make API Calls with ease, and make it cacheable without adding any extra lines of code.
                       DESC

  s.homepage         = 'https://github.com/himanshusingh1/HSAPICaller'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Himanshu Singh' => 'himanshusingh@hotmail.co.uk' }
  s.source           = { :git => 'https://github.com/himanshusingh1/HSAPICaller.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.swift_versions = '5.0.0'
  s.source_files = 'HSAPICaller/Classes/**/*'

    s.dependency 'Moya'
end
