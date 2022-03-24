#!/usr/bin/env bash
#
# Somewhat ugly brute forcing test that just runs the binaries with naively
# created permutations of input variables.

set -e

BIN_DATE=/usr/bin/date
DATE_CMD=( "${BIN_DATE}" "+%s%N" )

test_count=0
fail_count=0

input0_time=0
input1_time=0
input2_time=0
input3_time=0

reset_time() {
  input0_time=0
  input1_time=0
  input2_time=0
  input3_time=0
}

dump_and_reset_time() {
  echo -n "$1 ("
  echo -n "${input0_time}"
  echo -n ", ${input1_time} (Δ $( bc <<< "scale=2; $input1_time / $input0_time" ))"
  echo -n ", ${input2_time} (Δ $( bc <<< "scale=2; $input2_time / $input1_time" ))"
  echo -n ", ${input3_time} (Δ $( bc <<< "scale=2; $input3_time / $input1_time" ))"
  echo -n ")"
  reset_time
}

store_time() {
  local out="$1"
  local store=$2

  local start="$( echo "${out}" | head -n 1 )"
  local end="$( echo "${out}" | tail -n 1 )"

  printf -v "${store}" "%lu" "$( bc <<< "${!store} + (${end} - ${start})" )"
}

test_equal() {
  test_count=$((test_count+1))
  local g="$1"; shift
  local p="$1"; shift
  local t="$1"; shift
  local opt="$1"; shift
  local inputs=("$@")


  out0=$("${DATE_CMD[@]}"; "$g" "${inputs[@]}"; echo; "${DATE_CMD[@]}" )
  out1=$("${DATE_CMD[@]}"; "$p" "${inputs[@]}"; echo; "${DATE_CMD[@]}" )
  out2=$("${DATE_CMD[@]}"; "$t" "${inputs[@]}"; echo; "${DATE_CMD[@]}" )
  out3=$("${DATE_CMD[@]}"; "$opt" "${inputs[@]}"; echo; "${DATE_CMD[@]}" )

  store_time "$out0" "input0_time"
  store_time "$out1" "input1_time"
  store_time "$out2" "input2_time"
  store_time "$out3" "input3_time"

  out0=$( echo "${out0}" | head -n -1 | tail -n 1 )
  out1=$( echo "${out1}" | head -n -1 | tail -n 1 )
  out2=$( echo "${out2}" | head -n -1 | tail -n 1 )
  out3=$( echo "${out3}" | head -n -1 | tail -n 1 )

  if [[ "str:$out0" != "str:$out1" ]]; then
    fail_count=$((fail_count+1))
    echo "Failed: $p " "${inputs[@]}"
  fi

  if [[ "str:$out1" != "str:$out2" ]]; then
    fail_count=$((fail_count+1))
    echo "Failed: $t " "${inputs[@]}"
  fi

  if [[ "str:$out1" != "str:$out3" ]]; then
    fail_count=$((fail_count+1))
    echo "Failed: $opt " "${inputs[@]}"
  fi
}


test_bin() {
  local g="$1.g"
  local p="$1.p"
  local t="$1.t"
  local opt="$1.opt"

  reset_time
  for i in $(seq 0 16); do
    input1=$(((1 << 62) >> (1 + (i * 4))))
    for j in $(seq 0 16); do
      input2=$(((1 << 62) >> (1 + (j * 4))))
      echo -n "."
      test_equal "$g" "$p" "$t" "$opt" "$input1" "$input2"
    done
  done
  echo
  dump_and_reset_time "$1"
  if [[ $fail_count -gt 0 ]]; then
    echo -e " -> Failed ${fail_count}/${test_count} tests"
  else
    echo -e " -> Ok"
  fi
}

test_bin "$(pwd)/$1"

# if [[ $fail_count -gt 0 ]]; then
#   echo -e "\nFailed ${fail_count}/${test_count} tests"
# else
#   echo -e "\nOk"
# fi
