#!/bin/sh

url="https://000000book.com"
# url="https://blackbook4.test"

# for i in 60 600 6000 6040 6041; do
for i in 6000; do
  # curl --data @public/data/$i.gml https://blackbook4.test/data; echo
  id=$(curl -F gml=@public/data/$i.gml $url/data)
  echo $id
  echo
  open https://000000book.com/data/$id
  # sleep 1
done

