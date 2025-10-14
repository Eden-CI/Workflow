#!/bin/bash -e

# compiler handling
if [ "$COMPILER" = "clang" ]; then
	case "$PLATFORM" in
		(linux|freebsd)
			CLANG=clang
			CLANGPP=clang++
			;;
		(win)
			CLANG=clang-cl
			CLANGPP=clang-cl
			;;
		(*) ;;
	esac

	COMPILER_FLAGS+=(-DCMAKE_C_COMPILER="$CLANG" -DCMAKE_CXX_COMPILER="$CLANGPP")
fi

export COMPILER_FLAGS