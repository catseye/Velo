#!/bin/sh

APPLIANCES=""
if [ `which ruby`x != x ]; then
    APPLIANCES="$APPLIANCES tests/appliances/velo.rb.md"
fi
if [ `which lua`x != x ]; then
    APPLIANCES="$APPLIANCES tests/appliances/velo.lua.md"
fi
if [ "${APPLIANCES}x" = x ]; then
    echo "Neither ruby nor lua found on search path."
    exit 1
fi
falderal $APPLIANCES README.md
