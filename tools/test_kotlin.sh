#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build
: "${JAVA_HOME:=$(/usr/libexec/java_home 2>/dev/null || true)}"
if [ -z "$JAVA_HOME" ]; then echo 'Set JAVA_HOME to a JDK with JNI headers' >&2; exit 1; fi
case "$(uname -s)" in
  Darwin) suffix=dylib; os=darwin; link=-dynamiclib ;;
  *) suffix=so; os=linux; link='-shared -fPIC' ;;
esac
${CC:-cc} -std=c99 -O2 -Wall -Wextra -Werror $link -Icore/include -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/$os" core/src/rooz.c bindings/kotlin/jni/rooz_jni.c -o "build/librooz_jni.$suffix"
"${KOTLINC:-kotlinc}" bindings/kotlin/src/main/kotlin/dev/rooz/Rooz.kt bindings/kotlin/tests/Smoke.kt -include-runtime -d build/rooz-tests.jar
"$JAVA_HOME/bin/java" -Djava.library.path=build -jar build/rooz-tests.jar
