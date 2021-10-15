#!/bin/bash -e

# Reads a line from stdin and treats it as a single entry file to be parsed into details to be indexed.

read -r entry

echo "Parsing $entry" >&2

## Fields we care about are the entry title, timestamp, and a unique id so that reindexing doesn't cause duplicates

# The first line should be the title
raw_title="$(head -1 "$entry")"
title="${raw_title:2}"

# The second line of the file mostly contains the timestamp, but sometimes not. We can more reliably derive the
# timestamp from the filename.
d="[[:digit:]]"
ts_pattern="($d$d$d$d)-($d$d)-($d$d)-($d$d)($d$d)($d$d).txt\$"
[[ $entry =~ $ts_pattern ]] || {
  echo "Failed to get timestamp from file path."
  echo "I thought all wiki entries followed the same naming scheme."
  exit 1
}
y="${BASH_REMATCH[1]}"
mo="${BASH_REMATCH[2]}"
d="${BASH_REMATCH[3]}"
h="${BASH_REMATCH[4]}"
mi="${BASH_REMATCH[5]}"
s="${BASH_REMATCH[6]}"
create_time="$y-$mo-$d $h:$mi:$s"
modified_time="$(date -r "$entry" "+%Y-%m-%d %H:%M:%S")"

# The title + creation time should be unique enough and not change often
uid="$title $create_time"
uid="${uid// /_}"

# The content is everything after the first line
content="$(tail -n +2 "$entry")"

# To index this, the id will have to be known independently of the json payload. To allow piping without loading the
# whole payload into memory, write the id to a line and the json to the following line.
echo "$uid"
jq -n \
  --arg title "$title" \
  --arg create_time "$create_time" \
  --arg modified_time "$modified_time" \
  --arg id "$uid" \
  --arg content "$content" \
  '{
    title: $title,
    createTime: $create_time,
    modifiedTime: $modified_time,
    id: $id,
    content: $content
  }'
