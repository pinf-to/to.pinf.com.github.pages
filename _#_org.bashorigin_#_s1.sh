#!/usr/bin/env bash.origin.script

depend {
    "git": "@com.github/bash-origin/bash.origin.gitscm#s1",
    "boilerplate": "@com.github/pinf-it/it.pinf.com.html5boilerplate#s1"
}

# @source https://github.com/pinf-to/pinf-to-github-pages/blob/master/bin/pinf-publish.js
function EXPORTS_publish {

    if ! BO_has_cli_arg "--ignore-dirty" && ! CALL_git is_clean; then
        BO_exit_error "Your git working directory has uncommitted changes!"
    fi

    local gitRemoteUrl="$(git config --get remote.origin.url)"
    if ! BO_test "$gitRemoteUrl" "github\\.com"; then
        BO_exit_error "The 'origin' of your git remote must point to github!"
    fi

    local sourceClonePath="$(CALL_git get_git_root)"
    local pagesClonePath="$__RT_DIRNAME__/targets/_$(BO_replace "$gitRemoteUrl" "^.+\\/([^\\/]+)\$")_$(BO_hash "$gitRemoteUrl")"


    CALL_git ensure_cloned_commit "$pagesClonePath" "$gitRemoteUrl" "gh-pages"


    pushd "$pagesClonePath" > /dev/null

        # Add source repo as source remote
        CALL_git ensure_remote "source" "file://$sourceClonePath"

        git clean -d -x -f
        git fetch source
        git merge source/master -m "Merged from master"

        CALL_boilerplate copy_minimal_as_base "$@"

        BO_run_node --eval '
            const PATH = require("path");
            const FS = require("$__DIRNAME__/node_modules/fs-extra");
            const CODEBLOCK = require("$__DIRNAME__/node_modules/codeblock");
            const BOILERPLATE = require("'$(CALL_boilerplate getJSRequirePath)'");

            const MARKED = require("$__DIRNAME__/node_modules/marked");
            const HIGHLIGHT = require("$__DIRNAME__/node_modules/highlight.js");

            const VERBOSE = !!process.env.VERBOSE;


            var config = JSON.parse(process.argv[1]);

            var uriDepth = 0;
            if (config.cd) {
                uriDepth = config.cd.split("/").length;
                var path = PATH.join(process.cwd(), config.cd);
                if (!FS.existsSync(path)) {
                    FS.mkdirsSync(path);
                }
                process.chdir(path);
            }

            if (VERBOSE) console.log("cwd:", process.cwd());

            function prepareAnchorCode (code) {

                if (/^\//.test(code)) {
                    var path = code;

                    if (/\.md$/.test(path)) {
                        // TODO: Relocate this.

                        code = FS.readFileSync(path, "utf8");

                        var tokens = MARKED.lexer(code);

                        code = MARKED.parser(tokens, {
                            highlight: function (code, type) {
                                if (type) {
                                    return HIGHLIGHT.highlight(type, code, true).value;
                                }
                                return HIGHLIGHT.highlightAuto(code).value;
                            }
                        });
                    } else {
                        throw new Error("No parser found for file: " + path);
                    }
                }

                if (code[".@"] === "github.com~0ink~codeblock/codeblock:Codeblock") {
                    code = CODEBLOCK.run(code, {}, {
                        sandbox: {
                            require: require
                        }
                    });
                }

                return code;
            }

            var css = "";
            if (config.css) {
                css = config.css;
                if (css[".@"] === "github.com~0ink~codeblock/codeblock:Codeblock") {
                    css = CODEBLOCK.thawFromJSON(css);
                    if (css.getFormat() === "css") {
                        css = css.getCode();                        
                    }
                }
            }

            if (
                config &&
                config.anchors &&
                config.anchors.body
            ) {
                var targetPath = "index.html";
                var code = config.anchors.body;
                code = prepareAnchorCode(code);
                code = BOILERPLATE.wrapHTML(code, {
                    css: css,
                    uriDepth: uriDepth
                });
                FS.outputFileSync(targetPath, code, "utf8");
            }

            if (
                config &&
                config.files
            ) {
                Object.keys(config.files).forEach(function (targetSubpath) {
                    if (/\.html?$/.test(targetSubpath)) {
                        var code = FS.readFileSync(config.files[targetSubpath], "utf8");
                        code = prepareAnchorCode(code);
                        code = BOILERPLATE.wrapHTML(code, {
                            css: css,
                            uriDepth: uriDepth + (targetSubpath.split("/").length - 1)
                        });
                        FS.outputFileSync(targetSubpath, code, "utf8");
                    } else {
                        FS.copySync(config.files[targetSubpath], targetSubpath);
                    }
                });
            }
        ' "$@"

        if ! BO_has_cli_arg "--dryrun"; then

            git add -A . 2> /dev/null || true
            git commit -m "Updated pages" 2> /dev/null || true

            git push origin gh-pages
        fi

    popd > /dev/null

}
