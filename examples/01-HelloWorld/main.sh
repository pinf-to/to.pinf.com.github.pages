#!/usr/bin/env bash.origin.script

echo "TEST_MATCH_IGNORE>>>"

depend {
    "pages": "@com.github/pinf-to/to.pinf.com.github.pages#s1"
}

# TODO: Wrap our index.html file in the boilerplate.

CALL_pages publish {
    "args": {
        "anchors": {
            "body": "<a href='https://pinf-to.github.io/to.pinf.com.github.pages/examples/01-HelloWorld/index.html'>examples/01-HelloWorld</a>"
        }
    }
}

echo "<<<TEST_MATCH_IGNORE"

echo "OK"
