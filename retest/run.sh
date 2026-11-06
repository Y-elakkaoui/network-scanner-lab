#!/usr/bin/env bash
# Reproduces the documented Apache findings, applies the fix, and scans again.
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p evidence

PASS=0; FAIL=0
check() { # check "<description>" <command...>
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS  $d"; PASS=$((PASS+1)); else echo "FAIL  $d"; FAIL=$((FAIL+1)); fi
}
check_not() { # check_not "<description>" <command...>
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "FAIL  $d"; FAIL=$((FAIL+1)); else echo "PASS  $d"; PASS=$((PASS+1)); fi
}
finish() { echo; echo "Result: $PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]; }

docker network create retest >/dev/null
docker build -q -t retest-scanner -f Dockerfile.scanner . >/dev/null
SCAN="docker run --rm --network retest retest-scanner"

for state in before after; do
  docker build -q --build-arg CONF=$state.conf -t retest-web-$state . >/dev/null
  docker run -d --name web-$state --network retest retest-web-$state >/dev/null
  sleep 5
  $SCAN curl -sI http://web-$state/ | tee evidence/$state-headers.txt
  $SCAN curl -s  http://web-$state/ > evidence/$state-body.html
  $SCAN nmap -sC -sV -p 80 web-$state | tee evidence/$state-nmap.txt
  $SCAN nikto -h http://web-$state/ -maxtime 120s -nointeractive > evidence/$state-nikto.txt 2>&1 || true
done

{
  echo "== Original configuration: the documented findings should reproduce"
  check "Server header shows the full Apache version" grep -qE '^Server: Apache/2\.4\.[0-9]+ \(Ubuntu\)' evidence/before-headers.txt
  check "Directory listing is shown"                  grep -q 'Index of /' evidence/before-body.html
  check "Version appears in the page footer"          grep -q '<address>Apache/2' evidence/before-body.html
  check_not "X-Frame-Options is absent"               grep -qi '^X-Frame-Options' evidence/before-headers.txt
  echo
  echo "== Corrected configuration: the findings should be gone"
  check "Server header no longer shows a version"     grep -qE '^Server: Apache.?$' evidence/after-headers.txt
  check_not "Nmap no longer reports the version in the server header" grep -q 'Apache/2' evidence/after-nmap.txt
  check "Directory listing is refused (403)"          grep -q '^HTTP/1.1 403' evidence/after-headers.txt
  check_not "No directory listing in the body"        grep -q 'Index of /' evidence/after-body.html
  check_not "No version in the page footer"           grep -q 'Apache/2' evidence/after-body.html
  check "X-Frame-Options is set"                      grep -qi '^X-Frame-Options: SAMEORIGIN' evidence/after-headers.txt
  check "X-Content-Type-Options is set"               grep -qi '^X-Content-Type-Options: nosniff' evidence/after-headers.txt
  finish
} 2>&1 | tee evidence/results.txt
exit "${PIPESTATUS[0]}"
