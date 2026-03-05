# Build Notes

These steps are for building AVCPro from source.

## Requirements
- macOS 13+
- Xcode Command Line Tools
- ffmpeg (required for MP4 export)

Install ffmpeg with Homebrew:
```bash
brew install ffmpeg
```

## App Icon
Source: `Assets/icon.jpg`

Generate `Assets/AppIcon.icns`:
```bash
mkdir -p Assets/AppIcon.iconset
sips -s format png -z 16 16 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_16x16.png
sips -s format png -z 32 32 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_16x16@2x.png
sips -s format png -z 32 32 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_32x32.png
sips -s format png -z 64 64 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_32x32@2x.png
sips -s format png -z 128 128 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_128x128.png
sips -s format png -z 256 256 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_128x128@2x.png
sips -s format png -z 256 256 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_256x256.png
sips -s format png -z 512 512 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_256x256@2x.png
sips -s format png -z 512 512 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_512x512.png
sips -s format png -z 1024 1024 Assets/icon.jpg --out Assets/AppIcon.iconset/icon_512x512@2x.png
iconutil -c icns Assets/AppIcon.iconset -o Assets/AppIcon.icns
rm -rf Assets/AppIcon.iconset
```

## Build App Bundle
```bash
swift build -c release
rm -rf build/AVCPro.app
mkdir -p build/AVCPro.app/Contents/MacOS build/AVCPro.app/Contents/Resources
cp .build/release/AVCPro build/AVCPro.app/Contents/MacOS/AVCPro
chmod +x build/AVCPro.app/Contents/MacOS/AVCPro
cp Assets/AppIcon.icns build/AVCPro.app/Contents/Resources/AppIcon.icns

cat > build/AVCPro.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>AVCPro</string>
  <key>CFBundleIdentifier</key>
  <string>com.yourname.AVCPro</string>
  <key>CFBundleExecutable</key>
  <string>AVCPro</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

open build/AVCPro.app
```

## Build DMG
```bash
rm -rf build/dmg
mkdir -p build/dmg/AVCPro
cp -R build/AVCPro.app build/dmg/AVCPro/
ln -s /Applications build/dmg/AVCPro/Applications
hdiutil create -volname "AVCPro" -srcfolder build/dmg/AVCPro -ov -format UDZO build/AVCPro.dmg
```
