Pod::Spec.new do |s|
  s.name             = "RaceTracker"
  s.version          = "0.1.0"
  s.summary          = "A short description of RaceTracker."

  s.description      = <<-DESC
Run tracking engine.
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
