.PHONY: generate open build test clean

# Regenerate the Xcode project from project.yml.
generate:
	xcodegen generate

open: generate
	open Cero.xcodeproj

build: generate
	xcodebuild -project Cero.xcodeproj -scheme Cero \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
		-quiet build

test: generate
	xcodebuild -project Cero.xcodeproj -scheme Cero \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
		-quiet test

clean:
	rm -rf Cero.xcodeproj build
