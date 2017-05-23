#!/usr/bin/env bash.origin.script

echo "TEST_MATCH_IGNORE>>>"

depend {
    "pages": "@com.github/pinf-to/to.pinf.com.github.pages#s1"
}

CALL_pages publish {
    "css": (css () >>>
        BODY {
            padding-left: 10px;
        }
    <<<),
    "anchors": {
        "body": (javascript () >>>

            const PATH = require("path")
            const FS = require("fs");

            return [
                '<p><b>Source:</b> <a href="https://github.com/pinf-to/to.pinf.com.github.pages">github.com/pinf-to/to.pinf.com.github.pages</a></p>',
                '<h1>Examples</h1>',
                '<ul>',
                FS.readdirSync(PATH.join("$__DIRNAME", "examples")).map(function (filename) {
                    return '<li><a href="examples/' + filename + '/index.html">' + filename + '</a></li>';
                }).join("\n"),
                '</ul>'
            ].join("\n");
        <<<)
    },
    "files": {
        "examples/01-HelloWorld/index.html": "$__DIRNAME__/index.html"
    }
}

echo "<<<TEST_MATCH_IGNORE"

echo "OK"
