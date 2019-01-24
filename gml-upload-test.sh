#!/bin/sh

# for i in 60 600 6000 6040 6041; do
for i in 6000; do
  # curl --data @data/$i.gml https://blackbook4.test/data; echo
  curl -F gml=@data/$i.gml https://blackbook4.test/data; echo
  # sleep 1
done

