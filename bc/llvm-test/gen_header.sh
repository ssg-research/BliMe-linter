#! /usr/bin/env bash
#
# Author: Hans Liljestrand <hans@liljestrand.dev>
# Copyright (C) 2021 Hans Liljestrand <hans@liljestrand.dev>
#
# Distributed under terms of the MIT license.

fail() {
  printf >&2 "[EE] %b\n" "$*"; exit 1
}

header_file=FileCheck-header.ll
src=
dst=

while [ $# -gt 0 ]; do
  arg="$1"

  case ${arg} in
  -cflags)
    cflags="$2"
    shift
    shift
    ;;
  -i)
    src="$2"
    shift
    shift
    ;;
  *)
    fail "Unrecognized arg: $1"
    shift
    ;;
  esac
done
[[ -n $src ]] || fail "No src!"

# Remove GLOBAL / LOCAL if unused

old_local=',LOCAL'
old_global=',GLOBAL'
new_local=
new_global=

grep GLOBAL "$src" >/dev/null && new_global="${old_global}"
grep LOCAL "$src" >/dev/null && new_local="${old_local}"

grep '^// RUN:' "$src" | 
  sed 's/^\/\/\s/; /' |
  sed "s/${old_global}/${new_global}/" | 
  sed "s/${old_local}/${new_local}/"

echo "; "
echo "; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!"
echo "; Instead, modify it under /bc/llvm-test and install from there!"
echo "; "

# Dump cflags and source
echo -e "\n; CFLAGS: $cflags\n"

# Remove C comments, and then make everything .ll comments
grep -v '^// RUN:' "$src" |
  sed 's/^\/\/\s//' |
  sed 's/^/; /g'

echo -e "\n\n"
