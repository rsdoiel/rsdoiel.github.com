#!/bin/bash

START_PATH=$(pwd)
BLOG=blog

function fileTitle {
    FILENAME=$(echo "$1" | sed -e "s/\s$//g")
    if [ -f "$FILENAME" ]; then
      echo $(grep "# " "$FILENAME" | head -1 | sed -e "s/# //g")
    else
      echo "Can't find $FILENAME"
      exit 1
    fi
}

# Build blog nav
echo "Building blog nav"
cat nav.md > $BLOG/nav.md
echo "+ [up](/blog/)" >> $BLOG/nav.md

echo "Building blog footer"
cat footer.md > $BLOG/footer.md

#
# Add post - create a date directory if needed and then
# render markdown file in direct directory
#
if [ "$1" != "" ]; then
    POST_PATH=$(reldate 0 day| tr - /)
    echo "Generating directory $POST_PATH"
    mkdir -p $BLOG/$POST_PATH

    FILENAME="$1"

    echo "Copying markdown file into blog path $POST_PATH"
    cp -v "$FILENAME" "$BLOG/$POST_PATH/"
    echo "Resolving $FILENAME to basename"
    FILENAME=$(pathparts -b $FILENAME)
    echo "Adding to git $POST_PATH/$FILENAME"
    git add $BLOG/$POST_PATH/$FILENAME
    git add $BLOG/$POST_PATH/${FILENAME/.md/.html}
    git commit -am "Added $BLOG/$POST_PATH/$FILENAME"
else
    echo "No post to add"
fi


echo "Changing work directory to $BLOG"
cd $BLOG
echo "Work directory now $(pwd)"
THIS_YEAR=$(reldate 0 day | cut -d\- -f 1)
LAST_YEAR=$(reldate -- -1 year | cut -d\- -f 1)
START_YEAR=2016
# Render all posts
for CUR_YEAR in $(range $THIS_YEAR $START_YEAR); do
    echo "Rendering posts for $CUR_YEAR"
    findfile -s .md $CUR_YEAR | sort -r | while read ITEM; do
        echo "Rendering $CUR_YEAR/$ITEM"
        TITLE=$(fileTitle "$CUR_YEAR/$ITEM")
        mkpage \
            "year=text:$(date +%Y)" \
            "title=text:$TITLE" \
            "contentBlock=$CUR_YEAR/$ITEM" \
            "nav=../nav.md" \
            "footer=footer.md" \
            "mdfile=text:$(basename $ITEM)" \
            post.tmpl > "$CUR_YEAR/${ITEM/.md/.html}"
done 
done

# Build index
echo "Building $BLOG/index.md"
TITLE="Robert's ramblings"
echo "" > index.md
echo "Building links to $THIS_YEAR posts"
findfile -s .md $THIS_YEAR | sort -r | while read ITEM; do
    echo "Processing index.md <-- $THIS_YEAR/$ITEM"
    POST_FILENAME=$THIS_YEAR/$ITEM
    POST_TITLE=$(fileTitle "$POST_FILENAME")
    REL_PATH="$THIS_YEAR/$ITEM"
    POST_DATE=$(pathparts -d $REL_PATH)
    POST_DATE=${POST_DATE//\//-}
    echo "+ [$POST_TITLE](/blog/$THIS_YEAR/${ITEM/.md/.html}), $POST_DATE" >> index.md
done
echo "" >> index.md
echo "Building Prior Years $LAST_YEAR to $START_YEAR"
for Y in $(range $LAST_YEAR $START_YEAR); do
    echo "Building index for year $Y"
    echo "## $Y" >> index.md
    echo "" >> index.md
    findfile -s .html $Y | while read FNAME; do
        ARTICLE=$(basename $FNAME | sed -e 's/.html//g;s/-/ /g')
        echo " + [$ARTICLE](/blog/$Y/$FNAME)" >> index.md
    done
done
mkpage \
    "year=text:$(date +%Y)" \
    "title=text:$TITLE" \
    "pageContent=index.md" \
    "nav=nav.md" \
    "footer=footer.md" \
    index.tmpl > index.html

cd $START_PATH
