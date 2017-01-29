#!/usr/bin/env bash.origin.script

depend {
    "git": "@com.github/bash-origin/bash.origin.gitscm#strawman"
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

    local sourceClonePath="$( CALL_git get_git_root )"
    local pagesClonePath="$(pwd)/.rt/to.pinf.com.github.pages/targets/$(BO_hash "$gitRemoteUrl")-$(BO_replace "$gitRemoteUrl" "^.+\\/([^\\/]+)\$")"

echo "pagesClonePath: $pagesClonePath"

    if [ ! -e "$pagesClonePath" ]; then
        BO_ensure_parent_dir "$pagesClonePath"
        # TODO: Use bash.origin.git to clone into tmp dir and then if successful into final location.
        git clone "$gitRemoteUrl" $pagesClonePath
        set +e
        pushd "$pagesClonePath" > /dev/null

            # Go to github pages branch
            git checkout --track gh-pages || ( \
                git checkout -b gh-pages \
            )

            # Add source repo as source remote
            CALL_git ensure_remote "source" "file://$sourceClonePath"

        popd > /dev/null
        set -e
    fi

    pushd "$pagesClonePath" > /dev/null
        git clean -d -x -f
        git fetch source
        git merge source/master
        git push origin gh-pages
    popd > /dev/null

}
