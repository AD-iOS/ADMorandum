ARCHS=-arch arm64

buildpath=build
Appname=ADMorandum

Frameworks=-framework Foundation -framework UIKit -framework CoreGraphics -framework PencilKit -framework Vision

Objcxxfile=*.mm

CC=clang
CXX=clang++

# SDKpath=/var/theos/sdks/iPhoneOS16.5.sdk
SDKpath=$(xcrun --sdk iphoneos --show-sdk-path)
iOSv=-miphoneos-version-min=15.0
Other=-std=c++17 -fobjc-arc -lc -lc++

all: build

build:
	mkdir -p $(buildpath)
	mkdir -p $(buildpath)/Payload/$(Appname).app
	$(CXX) $(ARCHS) -isysroot $(SDKpath) $(iOSv) $(Frameworks) $(Other) $(Objcxxfile) -o $(Appname)
	mv $(Appname) $(buildpath)/Payload/$(Appname).app/
	cp -r Orton/* $(buildpath)/Payload/$(Appname).app/
	cd $(buildpath) && zip -r -9 $(Appname).ipa Payload/$(Appname).app/

clean:
	rm -rf build