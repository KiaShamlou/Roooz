CC ?= cc
CFLAGS ?= -O2 -std=c99 -Wall -Wextra -Werror -pedantic
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
  LIB = build/librooz.dylib
  SHARED = -dynamiclib
else
  LIB = build/librooz.so
  SHARED = -shared -fPIC
endif
.PHONY: all test sanitize oracle reference clean
all: $(LIB)
build:
	mkdir -p build
$(LIB): core/src/rooz.c core/src/locales.inc core/include/rooz.h | build
	$(CC) $(CFLAGS) $(SHARED) -Icore/include core/src/rooz.c -o $@
build/core_test: tests/core_test.c tests/fixtures/official_1405.h core/src/rooz.c core/src/locales.inc core/include/rooz.h | build
	$(CC) $(CFLAGS) -Icore/include core/src/rooz.c tests/core_test.c -o $@
test: build/core_test
	./build/core_test
sanitize: | build
	$(CC) -std=c99 -g -O1 -Wall -Wextra -Werror -fsanitize=address,undefined -fno-omit-frame-pointer -Icore/include core/src/rooz.c tests/core_test.c -o build/core_test_sanitized
	./build/core_test_sanitized
oracle: build/core_test
	node tools/intl_oracle.mjs > build/oracle.tsv
	./build/core_test build/oracle.tsv
reference: build/core_test
	node tools/reference_oracle.cjs > build/reference.tsv
	./build/core_test --reference build/reference.tsv
clean:
	rm -rf build
