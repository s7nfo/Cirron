.PHONY: test
test: test-python test-ruby

.PHONY: test-python
test-python:
	@echo "Running Python tests..."
	sudo PYTHONPATH=./python python -m unittest discover -s python/tests

.PHONY: test-ruby
test-ruby:
	@echo "Running Ruby tests..."
	cd ruby && \
	sudo gem install bundler && \
	sudo bundle install && \
	sudo bundle exec ruby -Ilib:test tests/tests.rb
