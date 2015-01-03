#!/bin/sh

FIXTURES=""
if [ `which ruby`x != x ]; then
    FIXTURES="$FIXTURES fixture/velo.rb.markdown"
fi
if [ `which lua`x != x ]; then
    FIXTURES="$FIXTURES fixture/velo.lua.markdown"
fi
if [ "${FIXTURES}x" = x ]; then
    echo "Neither ruby nor lua found on search path."
    exit 1
fi
falderal $FIXTURES README.markdown
