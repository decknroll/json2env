#!/bin/sh

set -e

cd "${0%/*}"

json2env="${1:-json2env}"

n=$'\n'

errors=0

shell_quote() { echo \'"$(echo "$1" | sed -e "s/'/'\\\\''/g")"\'; };

t() {
  name="$1"
  code="$2"
  op="$3"
  if [ -e "$4" ]; then val="$(cat "$4")"
  else val="$4"; fi
  out="$(eval "$code")"
  if eval "[ $(shell_quote "$out") $op $(shell_quote "$val") ]"; then
    echo "$name: ok"
  else
    errors=$(( errors + 1 ))
    echo "$name: fail"
    echo "       ran:         \`$code\`"
    echo "       got:         [$out]"
    echo "       comparison:  $op"
    echo "       expected:    [$val]"
  fi
}

#t 'fail' 'echo 1' == 0

t 'help exit code' \
  '$json2env --help >/dev/null 2>&1; echo $?' == 0

t 'help content length' \
  '$json2env --help 2>/dev/null | wc -l' -eq 69

t 'from stdin' \
  'cat string.json | $json2env' == string=value

t 'from files' \
  '$json2env string.json case.json' == "string=value${n}Key=a"

[ -e /tmp/out.sh ] && rm /tmp/out.sh

t 'output-to-file empty stdout' \
  '$json2env -o /tmp/out.sh string.json' == ''

t 'output-to-file contents' \
  'cat /tmp/out.sh' == string=value

[ -e /tmp/out.sh ] && rm /tmp/out.sh

t 'mixed-case to lowercase key translation' \
  '$json2env -l case.json' == key=a

t 'mixed-case to uppercase key translation' \
  '$json2env -u case.json' == KEY=a

t 'array as JSON compact' \
  '$json2env -k ar -c complex.json' == ar=\''["a","b","c"]'\'

t 'object as JSON compact' \
  '$json2env -k obj -c complex.json' == obj=\''{"k1":"v1","k2":"v2"}'\'

t 'array as text default' \
  '$json2env -t -k ar complex.json' == "ar='a${n}b${n}c'"

t 'array as text with delimiter' \
  '$json2env -t -L , -k ar complex.json' == "ar='a,b,c'"

t 'object as text default' \
  '$json2env -t -k obj complex.json' == "obj='k1 v1${n}k2 v2'"

t 'object as text with delimiters' \
  '$json2env -t -L , -K = -k obj complex.json' == "obj='k1=v1,k2=v2'"

# --prefix
# --env-name
# --array
# --assoc
# --force
# --strict
# non-strict
# --path

if [ "$errors" -gt 0 ]; then
  echo "ERRORS: $errors"
fi

exit $errors

