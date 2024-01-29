#!/usr/bin/env zsh

##### 1. Create a file with the list of URLs
# source: [command line interface - How to use curl -Z (--parallel) effectively? - Stack Overflow](https://stackoverflow.com/questions/71244217/how-to-use-curl-z-parallel-effectively)

curl --parallel --parallel-immediate --parallel-max 60 --config config.txt

# config.txt file:

# url=http://site/path/to/file1
# output="./path/to/file1"
# url=http://site/path/to/file2
# output="./path/to/file2"
# ...

curl --parallel --parallel-immediate \
  --parallel-max 60 \
  --config config.txt \
  --fail-with-body \
  --retry 5 \
  --create-dirs \
  --write-out "code %{response_code} url %{url} type %{content_type}\n"
