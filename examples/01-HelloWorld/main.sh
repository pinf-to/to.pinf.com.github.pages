#!/usr/bin/env bash.origin.script

echo "TEST_MATCH_IGNORE>>>"

depend {
    "pages": "@com.github/pinf-to/to.pinf.com.github.pages#strawman"
}

CALL_pages publish

echo "<<<TEST_MATCH_IGNORE"

echo "OK"
