ASYNC_TESTS_FAST = $(shell find test/ -name '*.test.coffee')
ASYNC_TESTS_SLOW = $(shell find test/ -name '*.test.slow.coffee')
SERIAL_TESTS_FAST = $(shell find test/ -name '*.test.serial.coffee')
SERIAL_TESTS_SLOW = $(shell find test/ -name '*.test.serial.slow.coffee')

test-single:
	@NODE_ENV=test ./node_modules/expresso/bin/expresso \
		-I src \
		--serial \
		$(TESTFLAGS) \
		--timeout 6000 \
		test/Model.test.coffee

test-async-fast:
	@NODE_ENV=test ./node_modules/expresso/bin/expresso \
		-I src \
		$(TESTFLAGS) \
		$(ASYNC_TESTS_FAST)

test-async-slow:
	@NODE_ENV=test ./node_modules/expresso/bin/expresso \
		-I src \
		--timeout 6000 \
		$(TESTFLAGS) \
		$(ASYNC_TESTS_SLOW)

test-serial-fast:
	@NODE_ENV=test ./node_modules/expresso/bin/expresso \
		-I src \
		--serial \
		$(TESTFLAGS) \
		$(SERIAL_TESTS_FAST)

test-serial-slow:
	@NODE_ENV=test ./node_modules/expresso/bin/expresso \
		-I src \
		--serial \
		--timeout 6000 \
		$(TESTFLAGS) \
		$(SERIAL_TESTS_SLOW)

test-async: test-async-fast test-async-slow
test-serial: test-serial-fast test-serial-slow
test-fast: test-async-fast test-serial-fast
test-slow: test-async-slow test-serial-slow
test: test-async-fast test-async-slow test-serial-fast test-serial-slow

test-cov:
	@TESTFLAGS=--cov $(MAKE) test

compile:
	./node_modules/coffee-script/bin/coffee -b -w -o ./lib -c ./src
