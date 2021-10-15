#!/bin/bash -e

# Takes a parsed entry and ingests it into elasticsearch.
# First line of a parsed entry is the uid so we can include it in the url.
# The rest of the entry is the json to send.
read -r uid
echo "Ingesting $uid"

encoded="$(echo "$uid" | jq -R @uri)"
output="$(mktemp)"
status=$(curl -sw "%{http_code}" -o "$output" -X PUT "http://localhost:9200/wiki/_doc/$encoded" -H 'Content-Type: application/json' -d @-)
[ "$status" = "200" ] || [ "$status" = "201" ] || {
  echo "Expected status 200|201; got $status"
  jq < "$output"
  rm "$output"
  exit 1
}
rm "$output"
