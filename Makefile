.PHONY: generate open build run clean

# Regenerate the Xcode project from project.yml.
generate:
	xcodegen generate

open: generate
	open Cero.xcodeproj

build: generate
	xcodebuild -project Cero.xcodeproj -scheme Cero \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
		-quiet build

# Build, install and launch on the booted simulator.
run: build
	xcrun simctl install booted "$$(xcodebuild -project Cero.xcodeproj -scheme Cero -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $$2}' | head -1)/Cero.app"
	xcrun simctl launch --terminate-running-process booted com.mgeovany.cero

# Same, with a sample situation loaded so every screen has data.
demo: build
	xcrun simctl install booted "$$(xcodebuild -project Cero.xcodeproj -scheme Cero -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $$2}' | head -1)/Cero.app"
	SIMCTL_CHILD_CERO_DEMO_DATA=1 xcrun simctl launch --terminate-running-process booted com.mgeovany.cero

clean:
	rm -rf Cero.xcodeproj build
