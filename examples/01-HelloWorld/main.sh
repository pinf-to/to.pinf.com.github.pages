#!/usr/bin/env bash.origin.script

echo "TEST_MATCH_IGNORE>>>"

depend {
    "pages": "@com.github/pinf-to/to.pinf.com.github.pages#s1"
}

CALL_pages publish {
    "anchors": {
        "body": (javascript () >>>

            const PATH = require("path")
            const FS = require("fs");

            return [
                "<ul>",
                FS.readdirSync(PATH.join("$__DIRNAME", "examples")).map(function (filename) {
                    return "<li><a href='/to.pinf.com.github.pages/examples/" + filename + "/index.html'>examples/" + filename + "</a></li>";
                }).join("\n"),
                "</ul>"
            ].join("\n");
        <<<)
    },
    "files": {
        "/examples/01-HelloWorld/index.html": "$__DIRNAME__/index.html"
    }
}

echo "<<<TEST_MATCH_IGNORE"

echo "OK"
