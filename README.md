# Howm indexing

Emacs [Howm mode](https://www.emacswiki.org/emacs/HowmMode) is great for keeping notes, and it has some searching built
in, but it isn't documented on the home page, so I decided to index my Howm wiki to make it searchable in Elasticsearch.
The steps below get everything set up and all my notes indexed in <5 minutes, not counting time to download Docker
images.

Start elasticsearch+kibana.

    docker-compose up

To be able to search by date, add a custom date mapping before ingesting. Note that timezones will be off. I haven't
looked into how to fix that yet.

    curl -X PUT "localhost:9200/wiki" -H 'Content-Type: application/json' -d'
    {
        "mappings": {
            "dynamic_date_formats": ["yyyy-MM-dd HH:mm:ss"]
        }
    }
    '

The indexing scripts are written to run as a pipeline. This works to ingest the entire wiki:

    ./find-all-entries.sh | \
    while IFS='$\n' read -r oneline; do \
        echo "$oneline" | ./parse-entry.sh | ./ingest.sh || { echo "Something went wrong"; break; }
    done

The first script outputs a line per file to process. The second outputs two lines per file. That's why the loop has to
be where it is. If I changed parse-entry.sh to output a single line encoded somehow, then both downstream scripts could
loop and read lines from stdin themselves. However, then I don't think I could avoid loading the whole line into memory
in ingest.sh, and right now the payload from stdin is passed right along to curl to keep it streaming the whole way.
What a dilemma!

See some indexed docs:

    curl -X GET "http://localhost:9200/wiki/_search?pretty" \
        -H 'Content-Type: application/json' \
        -d '{"_source": {"excludes": ["content"]}}'

To see the data in Kibana, create an index pattern that matches the index:

    curl -X POST "localhost:5601/api/index_patterns/index_pattern" \
        -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '
        {
            "index_pattern": {
                "id": "my-wiki-index-pattern",
                "title": "wiki",
                "timeFieldName": "createTime"
            }
        }'

Then go to
http://localhost:5601/app/discover#/?_g=(time:(from:'2014-12-01T06:00:00.000Z',to:now))&_a=(columns:!(title),index:my-wiki-index-pattern)
to see the entries. Kibana might ship with a default index pattern, or I might have created it accidentally.

To start from scratch, delete the wiki index and index pattern do it all again:

    curl -X DELETE "http://localhost:9200/wiki" \
        -H 'kbn-xsrf: true' "localhost:5601/api/index_patterns/index_pattern/my-wiki-index-pattern"
