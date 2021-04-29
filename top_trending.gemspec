require_relative 'lib/top_trending/version'

Gem::Specification.new do |spec|
  spec.name          = "top_trending"
  spec.version       = TopTrending::VERSION
  spec.authors       = ["Andrew Nagi"]
  spec.email         = ["andrew.nagi@gmail.com"]

  spec.summary       = 'Caputre and report on top trending hits.'
  spec.description   = 'Amongst millions of hits, report the top trending hits in the last 24 hours.'
  spec.homepage      = 'https://github.com/entropyhub/top_trending'
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.add_dependency 'redis', '~> 4.0'
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
