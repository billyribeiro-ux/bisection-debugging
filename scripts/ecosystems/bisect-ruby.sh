bundle install --frozen --jobs=4 >/dev/null 2>&1 || exit 125
bundle exec rspec --fail-fast
