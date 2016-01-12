#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0");
BIN_DIR=$(dirname "$SCRIPT");
PROJECT_ROOT=$(dirname "$BIN_DIR");
PROJECT_NAME=$(basename $PROJECT_ROOT);
BOX_PHAR=$PROJECT_ROOT/box.phar;

COMPOSER_PHAR=$PROJECT_ROOT/composer.phar;
JQ_BIN=$PROJECT_ROOT/jq;
GIT_VERSION=`cd $PROJECT_ROOT && git name-rev --name-only HEAD`;
GIT_COMMIT=`cd $PROJECT_ROOT && git rev-parse HEAD`;
VERSION="branch '$GIT_VERSION', commit '$GIT_COMMIT'";
CONSOLE=$PROJECT_ROOT/app/console
BOX_JSON=$PROJECT_ROOT/box.json;

if [[ (! -f "$PROJECT_ROOT/vendor/autoload.php") && (! -f "$PROJECT_ROOT/autoload.php") ]]; then
    if [ ! -f "$COMPOSER_PHAR" ]; then
        echo -e "Download composer.phar...\n";
        curl -sS https://getcomposer.org/installer | php
        mv composer.phar "$COMPOSER_PHAR"
    fi
    (cd $PROJECT_ROOT && php $COMPOSER_PHAR install)
fi

if [ ! -f "$BOX_PHAR" ]; then
    echo -e "Download box.phar...\n";
    curl -LSs https://box-project.github.io/box2/installer.php | php
    mv box.phar "$BOX_PHAR"
fi

if [ ! -f "$BOX_JSON" ]; then
    echo -e "Error: $BOX_JSON not found\n";
    exit 1;
fi

if [ ! -f "$JQ_BIN" ]; then
    echo -e "Download jq to parse box.json...\n";
    wget http://stedolan.github.io/jq/download/linux64/jq > $JQ_BIN
    chmod 755 $JQ_BIN
fi

#eval echo to unquote string
if [ ! "$PROVIDER_NAME" ]; then
   PROVIDER_NAME="project.phar"
fi
PROVIDER_PHAR="$PROJECT_ROOT/$PROVIDER_NAME"

echo -e "Clear all the caches...\n";
rm  -f "$PROVIDER_PHAR"
php $CONSOLE cache:clear --env="prod"
php $CONSOLE cache:clear --env="dev"

echo -e "Build $PROVIDER_NAME ($VERSION)...\n";
WAS_BUILT=`cd $PROJECT_ROOT && php -d phar.readonly=0 "$BOX_PHAR" build`
if [[ (-n "$WAS_BUILT") && (-f "$BOX_PHAR") ]]; then
    echo -e "$PROVIDER_NAME has been built against $VERSION"
fi
