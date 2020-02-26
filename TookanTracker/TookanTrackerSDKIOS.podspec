
Pod::Spec.new do |s|
s.name         = 'TookanTrackerSDKIOS'
s.version      = '0.0.1'
s.summary      = 'Now add Tookan Tracker in app for quick tracking.'
s.homepage     = 'https://github.com/tookanapp/tookan-tracker-ios'
s.documentation_url = 'https://docs.jungleworks.com/tookan/sdk/ios'

s.license      = { :type => 'MIT', :file => 'FILE_LICENSE' }

s.author             = { 'Mukul Kansal' => 'mukul.kansal@jungleworks.com' }

s.source       = { :git => 'https://github.com/tookanapp/tookan-tracker-ios.git', :tag => s.version }
s.ios.deployment_target = '9.0'
s.source_files = 'TookanTracker/**/*.{swift}'
s.exclude_files = 'Classes/Exclude'
s.exclude_files = 'TookanTracker/DemoApp',
s.static_framework = false

s.swift_version = '5.0'

#s.resource_bundles = {
#'TookanTrackerSDKIOS' => ['TookanTracker/**/*.#{lproj,storyboard,xcassets,gif}','README.md']
#}
s.resources = ['TookanTracker/**/*.xcassets']
s.preserve_paths = ['README.md']




end
