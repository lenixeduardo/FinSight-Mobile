#!/usr/bin/env bash
set -euo pipefail
export PUB_CACHE="${PUB_CACHE:-/tmp/finsight-pub-cache}"
FLUTTER_HOME=/tmp/finsight-flutter-sdk
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
"$FLUTTER_HOME/bin/flutter" config --enable-web
"$FLUTTER_HOME/bin/flutter" create --platforms=web --project-name finsight_mobile .
"$FLUTTER_HOME/bin/flutter" pub get
"$FLUTTER_HOME/bin/flutter" build web --release
[ -f build/web/index.html ] || { echo 'Flutter Web index.html ausente' >&2; exit 1; }
