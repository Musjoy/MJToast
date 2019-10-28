#
# Be sure to run `pod lib lint MJToast.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MJToast"
  s.version          = "0.1.2"
  s.summary          = "Use this to show a toast."

  s.homepage         = "https://github.com/Musjoy/MJToast"
  s.license          = 'MIT'
  s.author           = { "Raymond" => "Ray.musjoy@gmail.com" }
  s.source           = { :git => "https://github.com/Musjoy/MJToast.git", :tag => "v-#{s.version}" }

  s.ios.deployment_target = '7.0'

  s.source_files = 'MJToast/Classes/**/*'
  
  s.user_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => 'MODULE_TOAST'
  }

end
