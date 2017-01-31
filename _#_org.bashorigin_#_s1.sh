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
        git add -A . 2> /dev/null || true
        git commit -m "Updated base template" 2> /dev/null || true

        git push origin gh-pages

    popd > /dev/null

}
