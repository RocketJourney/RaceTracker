Pod::Spec.new do |s|
  s.name             = "RaceTracker"
  s.version          = "0.1.1"
  s.summary          = "RaceTracker is RocketJourney's Run Tracking Engine."

  s.description      = <<-DESC
RocketJourney's run tracking engine consists of a single state machine that keeps record of users location data in time. You might use this to build your own running application, track your users trajectory, or as a base to your own tracking engine.
                       DESC

  s.homepage         = "https://github.com/RocketJourney/RaceTracker"
  s.license          = 'MIT'
  s.author           = { "Ernesto Cambuston" => "e.cambuston@gmail.com" }
  s.source           = { :git => "https://github.com/RocketJourney/RaceTracker.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Source/*.swift'

  s.frameworks = 'CoreLocation'
end
