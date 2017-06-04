#!/usr/bin/env bash.origin.script

depend {
    "git": "@com.github/bash-origin/bash.origin.gitscm#s1",
    "boilerplate": "@com.github/pinf-it/it.pinf.com.html5boilerplate#s1"
}

function EXPORTS_getJSRequirePath {
    echo "$__DIRNAME__/_#_org.bashorigin_#_s1.js"
}

# @source https://github.com/pinf-to/pinf-to-github-pages/blob/master/bin/pinf-publish.js
function EXPORTS_publish {

    echo "TEST_MATCH_IGNORE>>>"

    if ! BO_has_cli_arg "--ignore-dirty" && ! CALL_git is_clean; then
        BO_exit_error "Your git working directory has uncommitted changes!"
    fi

    local gitRemoteUrl="$(git config --get remote.origin.url)"
    if ! BO_test "$gitRemoteUrl" "github\\.com"; then
        BO_exit_error "The 'origin' of your git remote must point to github!"
    fi

    local sourceClonePath="$(CALL_git get_closest_parent_git_root)"
    local pagesClonePath="$__RT_DIRNAME__/targets/_$(BO_replace "$gitRemoteUrl" "^.+\\/([^\\/]+)\$")_$(BO_hash "$gitRemoteUrl")"

    BO_log "$VERBOSE" "cwd: $(pwd)"
    BO_log "$VERBOSE" "sourceClonePath: $sourceClonePath"


    CALL_git ensure_cloned_commit "$pagesClonePath" "$gitRemoteUrl" "gh-pages"

    local sourceBasePath="$(dirname "$sourceClonePath")"

    pushd "$pagesClonePath" > /dev/null

        # Add source repo as source remote
        CALL_git ensure_remote "source" "file://$sourceClonePath"

        git clean -d -x -f
        git fetch source
        git merge source/master -m "Merged from master"

        CALL_boilerplate copy_minimal_as_base "$@"

        BO_run_recent_node --eval '
            const sourceBasePath = process.argv[1];

            const BOILERPLATE = require(process.argv[2]);

            const config = JSON.parse(process.argv[3]);

            const PUBLISHER = require("$__DIRNAME__/_#_org.bashorigin_#_s1.js");

            PUBLISHER.publish(sourceBasePath, config, {
                BOILERPLATE: BOILERPLATE
            });
        ' "${sourceBasePath}" "$(CALL_boilerplate getJSRequirePath)" "$@"

        if ! BO_has_cli_arg "--dryrun"; then

            git add -A . 2> /dev/null || true
            git commit -m "Updated pages" 2> /dev/null || true

            git push origin gh-pages
        fi

    popd > /dev/null

    echo "<<<TEST_MATCH_IGNORE"
}
