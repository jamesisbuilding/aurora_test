#!/bin/sh
# Calculates line coverage for business logic only (bloc, cubit, data, domain, utils, di).
# Excludes view layer, generated files, and platform-specific code.
#
# Usage: from feature/image_viewer, run:
#   flutter test --coverage && ./scripts/coverage_business_logic.sh

set -e
cd "$(dirname "$0")/.."
COV="${1:-coverage/lcov.info}"

if [ ! -f "$COV" ]; then
  echo "Run 'flutter test --coverage' first to generate $COV"
  exit 1
fi

perl -ne '
  if (/^SF:(.+)/) { $current_sf = $1; $lf=$lh=0 }
  if (/^LF:(\d+)/) { $lf = $1 }
  if (/^LH:(\d+)/) {
    $lh = $1;
    if ($current_sf =~ m{lib/src/(bloc|cubit|data|domain|utils|di)/}) {
      $total_lf += $lf; $total_lh += $lh;
    }
  }
  END {
    $pct = $total_lf ? 100*$total_lh/$total_lf : 0;
    printf "Business logic coverage: %.1f%% (%d/%d lines)\n", $pct, $total_lh, $total_lf;
  }
' "$COV"
