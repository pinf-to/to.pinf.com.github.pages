#!/usr/bin/env bash.origin.script

echo "TEST_MATCH_IGNORE>>>"

depend {
    "pages": "@com.github/pinf-to/to.pinf.com.github.pages#s1"
}

CALL_pages publish {
    "cd": "examples/02-Markdown",
    "css": (css () >>>
        BODY {
            padding-left: 10px;
        }
    <<<),
    "anchors": {
        "body": "$__DIRNAME__/Index.md"
    }
}

echo "<<<TEST_MATCH_IGNORE"

echo "OK"
