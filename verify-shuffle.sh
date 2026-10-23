# Fails the build unless every executable and shared library in the outputs
# contains funkyenv's canary functions in shuffled order. Missing canaries mean
# the file was linked without funkyenv's linker flags. Separate debug info
# files (lib/debug) are skipped; the binaries they belong to are checked.
# Set dontVerifyFunkyenv to skip.

funkyenvVerifyShuffle() {
    if [[ -n "${dontVerifyFunkyenv-}" ]]; then
        return
    fi

    local output file type order checked=0 failed=0
    local unshuffled
    unshuffled="$(seq -s ' ' 0 31) "

    for output in $(getAllOutputNames); do
        while IFS= read -r -d '' file; do
            isELF "$file" || continue
            type=$($READELF -h "$file" 2>/dev/null | awk '/Type:/ {print $2}')
            [[ $type == EXEC || $type == DYN ]] || continue

            order=$($NM -n --defined-only "$file" 2>/dev/null |
                sed -n 's/.* __funkyenv_canary_\([0-9]*\)$/\1/p' | tr '\n' ' ')

            if [[ -z $order ]]; then
                echo "funkyenv: $file has no canary functions; it was not linked with funkyenv's flags (or its symbols were stripped)" >&2
                failed=$((failed + 1))
            elif [[ $order == "$unshuffled" ]]; then
                echo "funkyenv: functions in $file were not shuffled" >&2
                failed=$((failed + 1))
            else
                checked=$((checked + 1))
            fi
        done < <(find "${!output}" -type f -not -path "*/lib/debug/*" -print0)
    done

    if ((failed > 0)); then
        echo "funkyenv: $failed ELF file(s) failed verification, $checked passed" >&2
        exit 1
    fi
    echo "funkyenv: verified shuffled function order in $checked ELF file(s)"
}

postFixupHooks+=(funkyenvVerifyShuffle)
