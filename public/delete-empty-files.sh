#!/bin/sh
for i in data/*.gml; do [ ! -s "$i" ] && rm "$i"; done
for i in data-json/*.json; do [ ! -s "$i" ] && rm "$i"; done
