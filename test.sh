#!/bin/sh

cat >test_config <<EOF
    -> Functionality "Interpret Velo Script" is implemented by shell command
    -> "bin/velo %(test-file)"

    -> Functionality "Interpret Velo Script" is implemented by shell command
    -> "impl/velo.lua/src/velo.lua %(test-file)"
EOF
falderal test test_config README.markdown
rm test_config
