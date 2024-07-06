.PHONY: test
test: test-python test-ruby

.PHONY: test-python
test-python:
	cp src/cirronlib.cpp src/apple_arm_events.h python/cirron/	
	rm -f python/cirron/cirronlib.so
	@echo "Running Python tests..."
	sudo PYTHONPATH=./python python -m unittest discover -s python/tests

.PHONY: test-ruby
test-ruby:
	cp src/cirronlib.cpp src/apple_arm_events.h ruby/lib/
	rm -f ruby/lib/cirronlib.so
	@echo "Running Ruby tests..."
	cd ruby && \
	sudo gem install bundler && \
	sudo bundle install && \
	sudo bundle exec ruby -Ilib:test tests/tests.rb
