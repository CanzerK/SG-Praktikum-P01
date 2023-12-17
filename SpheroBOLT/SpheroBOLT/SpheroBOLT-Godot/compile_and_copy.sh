
PROJECT_NAME="SpheroBOLT-Godot"
FRAMEWORK_NAME="Sphero"
TARGET_NAME="SpheroBOLT-Godot"
OUTPUT_DIR="../../../Game/ios/plugins/Sphero"

RELEASE_MODE="Release"

rm -rf plugin/*.xcframework

# Build for iPhoneOS
xcodebuild -project ${PROJECT_NAME}.xcodeproj -target ${TARGET_NAME} -sdk iphoneos -configuration ${RELEASE_MODE}

# Build for iPhone Simulator
xcodebuild -project ${PROJECT_NAME}.xcodeproj -target ${TARGET_NAME} -sdk iphonesimulator -configuration ${RELEASE_MODE}    

xcodebuild -create-xcframework \
    -library build/${RELEASE_MODE}-iphonesimulator/lib${TARGET_NAME}.a \
    -library build/${RELEASE_MODE}-iphoneos/lib${TARGET_NAME}.a \
    -output plugin/${FRAMEWORK_NAME}.xcframework

cp -r plugin/${FRAMEWORK_NAME}.xcframework ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework
cp plugin/godotsphero.gdip ${OUTPUT_DIR}/godotsphero.gdip
