#!/usr/bin/env bash
#
# Somewhat ugly brute forcing test that just runs the binaries with naively
# created permutations of input variables.

test_count=0
fail_count=0

test_equal() {
  test_count=$((test_count+1))
  local p="$1"
  shift
  local t="$1"
  shift
  local inputs=("$@")

  out1=$($p "${inputs[@]}")
  out2=$($t "${inputs[@]}")

  if [[ "str:$out1" != "str:$out2" ]]; then
    fail_count=$((fail_count+1))
    echo "Failed: $t " "${inputs[@]}"
  fi
}

test_bin() {
  local p="$1.p"
  local t="$1.t"

  for i in $(seq 1 64); do
    input1=$(((1 << 62) >> i))
    for j in $(seq 1 64); do
      input2=$(((1 << 62) >> j))
      test_equal "$p" "$t" "$input1" "$input2"
    done
  done
}

test_bin "$(pwd)/$1"

if [[ $fail_count -gt 0 ]]; then
  echo "Failed ${fail_count}/${test_count} tests"
else
  echo "all okay"
fi
