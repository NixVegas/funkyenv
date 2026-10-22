# dumpFunctionOrder SRC DST
#
# For each executable and shared library under SRC, writes its function names in
# address order, one per line, to DST/<path relative to SRC>.txt.
# Symbols made by the linker (mold's foo$plt stubs, etext) are left out and
# symbol versions (@GLIBC_2.2.5, which only GNU ld keeps) are stripped so the
# lists can be diffed. funkyenv's canary functions (__funkyenv_canary_*) are
# kept, so the funky lists show exactly what funkyenv added.

dumpFunctionOrder() {
    local src=$1 dst=$2 file rel type

    while IFS= read -r -d '' file; do
        isELF "$file" || continue
        type=$($READELF -h "$file" 2>/dev/null | awk '/Type:/ {print $2}')
        [[ $type == EXEC || $type == DYN ]] || continue

        rel=${file#"$src"/}
        mkdir -p "$dst/$(dirname "$rel")"
        $NM -n --defined-only "$file" 2>/dev/null |
            awk '$2 ~ /^[tT]$/ && $3 !~ /\$plt(got)?$|^_PROCEDURE_LINKAGE_TABLE_$|^_?etext$/ { sub(/@.*/, "", $3); print $3 }' >"$dst/$rel.txt"
    done < <(find "$src" -type f -not -path "*/lib/debug/*" -print0)
}
