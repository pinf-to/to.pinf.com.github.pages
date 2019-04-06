#!/usr/bin/env bash.origin.script

depend {
    "git": "@com.github/bash-origin/bash.origin.gitscm#s1",
    "boilerplate": "@com.github/pinf-it/it.pinf.com.html5boilerplate#s1"
}

function EXPORTS_getJSRequirePath {
    echo "$__DIRNAME__/_#_org.bashorigin_#_s1.js"
}

function EXPORTS_getTargetPath {
    local gitRemoteUrl="$(git config --get remote.origin.url)"
    if ! BO_test "$gitRemoteUrl" "github\\.com"; then
        BO_exit_error "The 'origin' of your git remote must point to github!"
    fi

    echo "$__RT_DIRNAME__/targets/_$(BO_replace "$gitRemoteUrl" "^.+\\/([^\\/]+)\$")_$(BO_hash "$gitRemoteUrl")"
}

# @source https://github.com/pinf-to/pinf-to-github-pages/blob/master/bin/pinf-publish.js
function EXPORTS_publish {

    echo "TEST_MATCH_IGNORE>>>"

    local gitRemoteUrl="$(git config --get remote.origin.url)"
    if ! BO_test "$gitRemoteUrl" "github\\.com"; then
        BO_exit_error "The 'origin' of your git remote must point to github!"
    fi

    local sourceClonePath="$(CALL_git get_closest_parent_git_root)"
    local pagesClonePath="$__RT_DIRNAME__/targets/_$(BO_replace "$gitRemoteUrl" "^.+\\/([^\\/]+)\$")_$(BO_hash "$gitRemoteUrl")"

    BO_log "$VERBOSE" "cwd: $(pwd)"
    BO_log "$VERBOSE" "sourceClonePath: $sourceClonePath"
    BO_log "$VERBOSE" "pagesClonePath: $pagesClonePath"

    if [ ! -e "$pagesClonePath" ]; then
        CALL_git ensure_cloned_commit "$pagesClonePath" "$gitRemoteUrl" "gh-pages"
    fi

    local sourceBasePath="$(dirname "$sourceClonePath")"

    pushd "$sourceBasePath" > /dev/null
        if ! BO_has_arg "--ignore-dirty" "$@" && ! CALL_git is_clean; then
            BO_exit_error "Your git working directory has uncommitted changes! (pwd: $(pwd))"
        fi
    popd > /dev/null

    pushd "$pagesClonePath" > /dev/null

        if ! BO_has_arg "--dynamic-changes-only" "$@"; then

            # Add source repo as source remote
            CALL_git ensure_remote "source" "file://$sourceClonePath"

            BO_log "$VERBOSE" "clean"
            git clean -d -x -f

            BO_log "$VERBOSE" "fetch source"
            git fetch source

            BO_log "$VERBOSE" "merge from master"
            git merge source/master -m "Merged from master"

            BO_log "$VERBOSE" "copy boilerplate"
            CALL_boilerplate copy_minimal_as_base "$@"
        fi

        BO_run_recent_node --eval '
            const sourceBasePath = process.argv[1];

            const BOILERPLATE = require(process.argv[2]);

            const config = JSON.parse(process.argv[3]);

            const PUBLISHER = require("$__DIRNAME__/_#_org.bashorigin_#_s1.js");

            PUBLISHER.publish(sourceBasePath, config, {
                BOILERPLATE: BOILERPLATE
            });
        ' "${sourceBasePath}" "$(CALL_boilerplate getJSRequirePath)" "$@"

        if ! BO_has_arg "--dryrun" "$@"; then

            BO_log "$VERBOSE" "add files"
            git add -A . 2> /dev/null || true
            BO_log "$VERBOSE" "commit changes"
            git commit -m "Updated pages" 2> /dev/null || true

            BO_log "$VERBOSE" "push to origin gh-pages"
            git push origin gh-pages
        fi

    popd > /dev/null

    echo "<<<TEST_MATCH_IGNORE"
}
