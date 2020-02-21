Pod::Spec.new do |s|
s.name         = 'TrackingSDK'
s.version      = '0.0.1'
s.summary      = 'Now add Tracking SDK in app for quick support.'
s.homepage     = 'https://github.com/tookanapp/tookan-tracker-ios.git'
s.documentation_url = 'https://github.com/Jungle-Works/Hippo-iOS-SDK'

s.license      = { :type => 'MIT', :file => 'FILE_LICENSE' }

s.author             = { 'Mukul Kansal' => 'mukul.kansal@jungleworks.com'  }

s.source       = { :git => 'https://github.com/tookanapp/tookan-tracker-ios.git', :tag => s.version }
s.ios.deployment_target = '9.0'
s.source_files = 'MapQuest/*.{swift,h,m}'
s.exclude_files = 'Classes/Exclude'
s.static_framework = false

s.swift_version = '4.0'

s.resource_bundles = {
'TrackingSDK' => ['TookanTracker/*.{lproj,storyboard,xcassets,gif}','TookanTracker/Assets/**/*.imageset','TookanTracker/.xib','TookanTracker/UIView/CollectionViewCells/**/*.xib','TookanTracker/UIView/CustomViews/**/*.xib', 'README.md']
}
s.resources = ['TookanTracker/*.xcassets']
s.preserve_paths = ['README.md']

s.dependency 'Alamofire'
s.dependency 'Polyline'


end

