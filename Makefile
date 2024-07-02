# Makefile to trigger tests for Python, Ruby, and Go implementations

# Default target
.PHONY: test
test: test-python test-ruby

# Python test target
.PHONY: test-python
test-python:
	@echo "Running Python tests..."
	sudo PYTHONPATH=./python python -m unittest discover -s python/tests

# Ruby test target
.PHONY: test-ruby
test-ruby:
	@echo "Running Ruby tests..."
	cd ruby && \
	gem install bundler && \
	bundle install && \
	sudo bundle exec ruby -Ilib:test tests/tests.rb
