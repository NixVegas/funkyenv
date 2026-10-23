# makeBinaryWrapper compiles wrappers with nixpkgs' normal compiler, which
# doesn't understand funkyenv's linker flags. If the package uses it, load it
# again built with the package's own compiler, so its wrappers get shuffled too.
# This runs before the first phase, after every setup hook has been loaded.

funkyenvUseFunkyBinaryWrapper() {
    declare -F makeCWrapper >/dev/null || return 0

    # Keep whether makeWrapper/wrapProgram make shell or binary wrappers, and
    # the shell options (the hook starts with `set -euo pipefail`).
    local savedFunctions savedOptions
    savedFunctions=$(declare -f makeWrapper wrapProgram)
    savedOptions=$(set +o)
    source @binaryWrapperHook@
    eval "$savedOptions"
    eval "$savedFunctions"
}

appendToVar prePhases funkyenvUseFunkyBinaryWrapper
