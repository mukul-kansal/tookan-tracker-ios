Pod::Spec.new do |s|
s.name = 'TookanTracker'
s.version = '0.0.1'
s.summary = 'Now add Tookan Tracker in app for quick tracking.'
s.homepage = 'https://github.com/mukul-kansal/tookan-tracker-ios.git'
s.documentation_url = 'https://docs.jungleworks.com/tookan/sdk/ios'

s.license = { :type => 'MIT', :file => 'FILE_LICENSE' }

s.author = { 'Mukul Kansal' => 'mukul.kansal@jungleworks.com' }

s.source = { :git => 'https://github.com/mukul-kansal/tookan-tracker-ios.git', :tag => s.version }
s.ios.deployment_target = '9.0'

s.exclude_files = 'TookanTracker/TookanTracker/DemoApp'
s.static_framework = true

s.source_files = 'TookanTracker/**/*.{h,m,swift}'
s.resources = 'TookanTracker/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}'

s.resource_bundles = {
'TookanTracker' => ['TookanTracker/*.{lproj,storyboard,xcassets,gif,png,jpeg,jpg,xib}', 'TookanTracker/*.imageset','TookanTracker/*.xib', 'README.md']
}

#s.dependency 'GoogleMaps'
#s.dependency 'GooglePlaces'
#s.dependency 'CocoaAsyncSocket'
s.static_framework = true


s.swift_version = '5.0'

end
