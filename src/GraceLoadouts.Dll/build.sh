#!/usr/bin/env bash
# Builds out/GraceLoadouts/grace_loadouts.dll.
#
# Needs Rust (~/.cargo, windows-gnu host) and tools/zig (setup.ps1). Rust's bundled GNU dlltool has
# no assembler next to it, so tools/as provides dlltool.exe/as.exe stand-ins that hand it zig's.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out="$root/out/GraceLoadouts"
zig="$root/tools/zig/zig.exe"
mkdir -p "$out" "$root/tools/as"

for tool in as dlltool; do
    [ -f "$root/tools/as/$tool.exe" ] || "$zig" cc -target x86_64-windows-gnu -municode -O2 \
        -o "$root/tools/as/$tool.exe" "$here/build-tools/$tool.c"
done
selfcontained="$(ls -d "$HOME"/.rustup/toolchains/stable-x86_64-pc-windows-gnu/lib/rustlib/x86_64-pc-windows-gnu/bin/self-contained)"

REAL_DLLTOOL="$(cygpath -w "$selfcontained/dlltool.exe")" \
PATH="$root/tools/as:$selfcontained:$HOME/.cargo/bin:$PATH" \
    cargo build --release --manifest-path "$here/Cargo.toml"
cp "$here/target/release/grace_loadouts.dll" "$out/"
ls -la "$out"
