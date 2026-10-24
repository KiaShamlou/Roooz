#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rooz_native.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rooz_native'
  s.version          = '0.1.0'
  s.summary          = 'Rooz deterministic civil calendar engine.'
  s.description      = <<-DESC
Rooz deterministic civil calendar engine.
                       DESC
  s.homepage         = 'https://github.com/KiaShamlou/Roooz'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Rooz contributors'

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
