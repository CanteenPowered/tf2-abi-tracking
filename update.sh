#!/bin/bash

BASE="$(realpath "$(dirname "$0")")"

dump_symbols() {
    # Create output dir
    mkdir -p "$(dirname "$2")"
    # Dump symbols
    echo "Dumping symbols for $1"
    if [ -f "$2" ]; then
        rm "$2"
    fi
    "$BASE/bin/abidump" "$1" symbols                                \
        | awk '{ for(i=2; i<=NF; ++i) printf $i""FS; print "" }'    \
        | sort                                                      \
        | uniq                                                      \
        >> "$2"
}

dump_vtables() {
    # Create output dir
    mkdir -p "$2"
    # Collect class names
    CLASSES="$("$BASE/bin/abidump" "$1" symbols "vtable for .*" | awk '{ for(i=4; i<=NF; ++i) printf $i""FS; print "" }')"
    echo "$CLASSES" | while read CLASS; do
        echo "Dumping vtable for $CLASS..."
        if [ -f "$2/$CLASS.txt" ]; then
            rm "$2/$CLASS.txt"
        fi
        "$BASE/bin/abidump" "$1" vtables "^$CLASS\$" >> "$2/$CLASS.txt"
    done
}

main() {
    # Build abidump
    if [ ! -f "$BASE/bin/abidump" ]; then
        mkdir -p "$BASE/bin"
        cmake                                               \
            -G Ninja                                        \
            -B "$BASE/build"                                \
            -DCMAKE_BUILD_TYPE=Release                      \
            -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="$BASE/bin"    \
            "$BASE/abidump"
        ninja -C "$BASE/build"
    fi

    # Use dedicated server files
    if [ ! -d "$BASE/dedicated_server" ]; then
        echo "Please copy the tf2 server files to $BASE/dedicated_server"
        exit
    fi

    # Dump symbols
    dump_symbols    "$BASE/dedicated_server/tf/bin/server_srv.so"   "$BASE/symbols/server.txt"
    dump_symbols    "$BASE/dedicated_server/bin/engine_srv.so"      "$BASE/symbols/engine.txt"
    dump_symbols    "$BASE/dedicated_server/bin/libtier0_srv.so"    "$BASE/symbols/tier0.txt"
    dump_symbols    "$BASE/dedicated_server/bin/libvstdlib_srv.so"  "$BASE/symbols/vstdlib.txt"

    # Dump vtables
    dump_vtables    "$BASE/dedicated_server/tf/bin/server_srv.so"   "$BASE/vtables/server"
    dump_vtables    "$BASE/dedicated_server/bin/engine_srv.so"      "$BASE/vtables/engine"
    dump_vtables    "$BASE/dedicated_server/bin/libtier0_srv.so"    "$BASE/vtables/tier0"
    dump_vtables    "$BASE/dedicated_server/bin/libvstdlib_srv.so"  "$BASE/vtables/vstdlib"

    # Extract game version
    GAMEVER="$(cat "$BASE/dedicated_server/tf/steam.inf" | awk -F= '/^PatchVersion/ { print $2 }')"
    GAMEVER="${GAMEVER%%[[:cntrl:]]}" # windows newlines :)

    git add .
    git commit -m "Server version $GAMEVER"
}

main "$@"
