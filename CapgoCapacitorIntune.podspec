require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapgoCapacitorIntune'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '17.0'
  s.dependency 'Capacitor'
  s.dependency 'MSAL', '2.9.0'
  s.prepare_command = <<-CMD
    set -e
    rm -rf vendor/intune-ios
    git clone --depth 1 --branch 21.5.1 https://github.com/microsoftconnect/ms-intune-app-sdk-ios.git vendor/intune-ios
  CMD
  s.vendored_frameworks = [
    'vendor/intune-ios/IntuneMAMSwift.xcframework',
    'vendor/intune-ios/IntuneMAMSwiftStub.xcframework'
  ]
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.swift_version = '5.1'
end
