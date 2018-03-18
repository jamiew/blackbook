#!/bin/sh
for i in data/*.gml; do [ ! -s "$i" ] && rm "$i"; done
