#!/usr/bin/sh

ostype() {
  if [ "$(uname -o)" = "Cygwin" ]; then
    OSTYPE="Cygwin"
  else
    OSTYPE="Linux"
  fi
  printf "%s" "$OSTYPE"
}

osarch() {
  if [ "$(uname -m)" = "x86_64" ]; then
    OSARCH="x86_64"
  elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "armv8l"  ]; then
    OSARCH="aarch64"
  else
    OSARCH="Unknow"
  fi
  printf "%s" "$OSARCH"
}
