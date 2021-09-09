#! /usr/bin/env bash
#
# Author: Hans Liljestrand <hans@liljestrand.dev>
# Copyright (C) 2021 Hans Liljestrand <hans@liljestrand.dev>
#
# Distributed under terms of the MIT license.

fail() {
  printf >&2 "[EE] %b\n" "$*"; exit 1
}

DEBUG=${DEBUG:-0}
DRY_RUN=${DRY_RUN:-0}

common_file=common.ll
src=
dst=

while [ $# -gt 0 ]; do
  arg="$1"

  case ${arg} in
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


if [[ -n $src ]]; then
  head -n 5 "$src"
  cat "${common_file}"
  tail -n +5 "$src" |
	  sed -E '/^declare dso_local (\w|_|-)+ @doNothing/d' |
	  sed -E 's/(clang version [[:digit:]]+(\.[[:digit:]])*) .*"}/\1"}/'
else
  # Assume we're processing stdin
  while IFS= read -r line
  do
    if [[ $linenr -lt 5 ]]; then
      echo "$line"
    else
      if [[ linenr -eq 5 ]]; then 
        cat "${common_file}"
        echo
      fi
  
      echo "$line" | 
        sed -E '/^declare dso_local (\w|_|-)+ @doNothing/d' |
	      sed -E 's/(clang version [[:digit:]]+(\.[[:digit:]])*) .*"}/\1"}/' |
        sed -E 's/(DICompileUnit\(.*producer: "clang version [[:digit:]]+\.[[:digit:]]+).*"/\1"/'
    fi

    linenr=$((linenr+1))
  done
fi

linenr=0

