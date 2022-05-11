preFixupHooks+=(_placeDLLs)
fixupOutputHooks+=(_fixDLLArchiveImportTable)

# Ensure that there are no DLLs in $bin and that they are moved to $lib or
# $out. This should reduce the dependency cycles and matches the location
# that .so files are placed on linux
_placeDLLs() {
(
    if [ -z $1 ]; then
        if [ "${!outputBin}" != "${!outputLib}" ]; then
            _placeDLLs ${!outputBin} ${!outputLib}
        fi
        exit
    fi

    echo "Moving DLLs from $1 to $2"

    local dlls

    mapfile -t dlls < <(find $1 -iname '*.dll')

    local dll
    for dll in ${dlls[@]}; do
        local rpath=$(realpath --relative-to=$1 $dll)
        mkdir -vp $2/$(dirname $rpath)
        mv -v $dll $2/$rpath
    done
)
}

# For every *.a in $outputs we try to find all (potential) import tables and
# match them to the appropriate DLL path. This path is then modified so that it
# uses windows directory separators and is relative (/nix/store is mapped to
# ..\..). This assumes that the running binary will be run from in $output/bin
_fixDLLArchiveImportTable() {
    (
        set +e

        echo "Finding and replacing DLL Import Tables"
        local archives
        local out_dirs

        for output in $outputs; do
            out_dirs+=" ""${!output} "
        done

        echo "SEARCHING $prefix"

        mapfile -t archives < <(find $prefix -iname '*.a')

        local archives_to_fix
        local dlls_to_search

        for archive in ${archives[@]}; do
            local maybe_dll
            echo "SEARCHING inside $archive"

            maybe_dll=$(@pe_imp_fix@ $archive)
            if [ $? -eq 0 ]; then
                echo "$archive refers to $maybe_dll"
                dlls_to_search[${#archives_to_fix[@]}]=$maybe_dll
                archives_to_fix[${#archives_to_fix[@]}]=$archive
            fi
        done

        for index in ${!dlls_to_search[@]}; do
            local location
            local dll=${dlls_to_search[$index]}
            echo "Searching for $dll"
            location=$(find $out_dirs -iname "$dll" -type f -print -quit)
            if [ -z "$location" ]; then
                echo "$dll not found"
                continue
            fi

            set -e

            location=$(echo $location | sed 's/\/nix\/store\//..\\..\\/; s/\//\\/g')
            local archive=${archives_to_fix[$index]}
            echo "SETTING $archive to $location"

            @pe_imp_fix@ "$archive" "$location" "$AR"

            set +e
        done

        set -e
    )
}
