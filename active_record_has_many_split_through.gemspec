
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record_has_many_split_through/version"

Gem::Specification.new do |spec|
  spec.name          = "active_record_has_many_split_through"
  spec.version       = ActiveRecordHasManySplitThrough::VERSION
  spec.authors       = ["Nathan Herald"]
  spec.email         = ["me@nathanherald.com"]

  spec.summary       = %q{Support has_many :through across seperate databases}
  spec.description   = %q{Support has_many :through across seperate databases}
  spec.homepage      = "https://github.com/myobie/active_record_has_many_split_through"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/myobie/active_record_has_many_split_through"
    spec.metadata["changelog_uri"] = "https://github.com/myobie/active_record_has_many_split_through"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0", "< 7"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mysql2", ">= 0.4.10"
  spec.add_development_dependency "byebug", "~> 10.0"
end
