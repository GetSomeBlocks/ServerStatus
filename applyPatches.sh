ORIG_PWD="$(pwd)"
cd "$(dirname "$0")"
echo "  Rebuilding Forked projects.... "

function requireCleanWorkTree {
    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        echo >&2 "cannot apply patches to $1: you have unstaged changes."
        git diff-files --name-status -r --ignore-submodules -- >&2
        err=1
    fi

    # Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        echo >&2 "cannot apply patches to $1: your index contains uncommitted changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    if [ $err = 1 ]
    then
        echo >&2 "Please commit or stash them."
        exit 1
    fi
}

function applyPatches {
    what=base/$1
    target=build/$1
    patches=$1

    cd $what
    git branch -f upstream >/dev/null
    cd ../../
    if [ ! -d  $target ]; then
        git clone $what $target -b upstream
    fi

    cd $target

    requireCleanWorkTree $target

    echo "  Resetting $target to $what..."
    git remote rm upstream 2>/dev/null 2>&1
    git remote add upstream ../../$what >/dev/null 2>&1
    git fetch upstream >/dev/null 2>&1
    git reset --hard upstream/upstream

    echo "  Applying patches to $target..."
    git am --abort

    if !(git am --3way ../../$patches/*.patch); then
        echo "  Something did not apply cleanly to $target."
        echo "  Please review above details and finish the apply then"
        echo "  save the changes with rebuildPatches.sh"
        cd "$ORIG_PWD"
        exit 1
    else
        echo "  Patches applied cleanly to $target"
    fi

    cd ../..
}
cd "$ORIG_PWD"
