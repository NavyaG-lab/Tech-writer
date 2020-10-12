#!/usr/bin/env bash

PROJECT_NAME="data-platform-docs"

all_links() {
    cd $PROJ_HOME
    grep -r "nubank/$PROJECT_NAME/" --exclude-dir=".build" . \
     | grep .md
}

extract_url() {
   grep -Eo "nubank/$PROJECT_NAME[^# \)\?>]+" \
     | sed "s|nubank/$PROJECT_NAME/tree/master/||g" \
     | sed "s|nubank/$PROJECT_NAME/blob/master/||g" \
     | sed "s|nubank/$PROJECT_NAME/edit/master/||g" \
     | grep -vE "/[0-9a-f]{5}" \
     | grep -v ":ALERT-NAME:" \
     | sed "s|^nubank/$PROJECT_NAME/||"
}

url_exists() {
    local -r filename="$1"
    local -r url="$2"

    if ! [ -f "${PROJ_HOME}/${url}" ] && ! [ -f "${PROJ_HOME}/${url}/README.md" ]; then
        log::warning "$filename references $url but it doesn't exist"
        return 1
    fi
}

link_exists() {
   local -r input="$1"

   local -r filename="$(echo "$input" | awk -F':' '{print $1}')"
   local -r url="$(echo "$input" | extract_url)"

   if [ -n "$url" ]; then
      test::run "$url exists" url_exists "$filename" "$url"
   fi
}

all_links_exist() {
    IFS=$'\n'
    for l in $(all_links); do
        link_exists "$l"
    done
}

test::set_suite "links"
all_links_exist
