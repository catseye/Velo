#!/bin/sh

cat >test_config <<EOF
    -> Functionality "Interpret Velo Script" is implemented by shell command
    -> "./velo.rb %(test-file)"
EOF
cd src && falderal test ../test_config ../README.markdown
rm ../test_config
