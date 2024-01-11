mkdir -p                                    \
      build                                 \
      build/Triangle.app/Contents           \
      build/Triangle.app/Contents/MacOS     \
      build/Triangle.app/Contents/Resources

xcrun                  \
    -sdk macosx metal  \
    -o build/Shader.ir \
    -c Shader.metal

xcrun -sdk macosx metallib                                      \
      -o build/Triangle.app/Contents/Resources/default.metallib \
      build/Shader.ir

clang                                             \
    -fobjc-arc                                    \
    -framework Cocoa                              \
    -framework Metal                              \
    -framework Quartz                             \
    -o build/Triangle.app/Contents/MacOS/Triangle \
    main.m
