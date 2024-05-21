#! /bin/sh
set -xeuo pipefail

heartwood()
{
	git ls-remote "rad://z3gqcJUoA1n9HaHKufZs5FCSGazv5" "$1" \
		| cut --fields=1
}

master="$(heartwood "master")"

nix-update --commit --flake --version=$master radicle-node-master
