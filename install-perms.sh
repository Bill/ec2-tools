#!/usr/bin/env bash
# Run this script as root to set permissions and ownership after svn export of this tree
# run as root from /usr/thoughtpropulsion Å
chown aws:aws . ./bin ./lib ./bin/* ./lib/*
chmod o+rx . ./bin ./lib ./bin/*
chmod o+r ./lib/*.rb
chmod o-w . ./bin ./lib ./bin/*