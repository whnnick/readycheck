#!/usr/bin/env bash
set -euo pipefail

swift build
swift run ReadyCheckApp
