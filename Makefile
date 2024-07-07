SOURCES = src/cirronlib.cpp src/apple_arm_events.h
PYTHON_DIR = python/cirron
RUBY_DIR = ruby/lib

.PHONY: test build build-python build-ruby copy-sources

test: test-python test-ruby

copy-sources:
	cp $(SOURCES) $(PYTHON_DIR)/
	cp $(SOURCES) $(RUBY_DIR)/

.PHONY: test-python
test-python: copy-sources
	rm -f $(PYTHON_DIR)/cirronlib.so
	@echo "Running Python tests..."
	sudo PYTHONPATH=./python python -m unittest discover -s python/tests

.PHONY: test-ruby
test-ruby: copy-sources
	rm -f $(RUBY_DIR)/cirronlib.so
	@echo "Running Ruby tests..."
	cd ruby && \
	sudo gem install bundler && \
	sudo bundle install && \
	sudo bundle exec ruby -Ilib:test tests/tests.rb

build: build-python build-ruby

.PHONY: build-python
build-python: copy-sources
	@echo "Building Python package..."
	cd python && python setup.py sdist bdist_wheel

.PHONY: build-ruby
build-ruby: copy-sources
	@echo "Building Ruby package..."
	cd ruby && gem build cirron.gemspec