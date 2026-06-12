BUNDLE_FROZEN=true bundle install --jobs=4 >/dev/null 2>&1 || exit 125  # --frozen flag is removed in modern Bundler
bundle exec rspec --fail-fast
