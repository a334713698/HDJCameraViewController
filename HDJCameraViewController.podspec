
Pod::Spec.new do |s|

s.name         = "HDJCameraViewController"
s.version      = "1.0.5"
s.ios.deployment_target = "9.0"
s.summary      = "HDJCameraViewController —— 仿微信相机"
s.homepage     = "https://github.com/a334713698/HDJCameraViewController"
s.license      = "MIT"
s.author       = { "洪冬介" => "hongdongjie334@gmail.com" }
s.social_media_url   = "https://weibo.com/1871979715"
s.source       = { :git => "https://github.com/a334713698/HDJCameraViewController.git", :tag => s.version }
s.source_files  = "HDJCameraViewController/*","HDJCameraViewController/**/*"
s.platform = "ios"
s.framework = "AVFoundation"

#s.requires_arc = true

end
