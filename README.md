# AVCPro

AVCPro is a lightweight macOS app that makes browsing and exporting AVCHD clips easy.

## Features
- Browse AVCHD clips from a selected folder
- Grid or list layout with search and sort
- Built-in playback
- Export selected clips as original `.MTS` or rewrap to `.MP4` using ffmpeg

## Requirements
- macOS 13+
- ffmpeg installed for MP4 export

Install ffmpeg with Homebrew:
```bash
brew install ffmpeg
```

## Build the App
Use the build script to create a runnable `.app` bundle with the icon:
```bash
./scripts/build_app.sh
```

Launch:
```bash
open build/AVCPro.app
```

## App Icon
The icon source is `icon.png` and the generated icon is stored at:
`Assets/AppIcon.icns`

If you update `icon.png`, regenerate the icns file:
```bash
mkdir -p Assets/AppIcon.iconset
sips -z 16 16 icon.png --out Assets/AppIcon.iconset/icon_16x16.png
sips -z 32 32 icon.png --out Assets/AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32 icon.png --out Assets/AppIcon.iconset/icon_32x32.png
sips -z 64 64 icon.png --out Assets/AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128 icon.png --out Assets/AppIcon.iconset/icon_128x128.png
sips -z 256 256 icon.png --out Assets/AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256 icon.png --out Assets/AppIcon.iconset/icon_256x256.png
sips -z 512 512 icon.png --out Assets/AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512 icon.png --out Assets/AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out Assets/AppIcon.iconset/icon_512x512@2x.png
iconutil -c icns Assets/AppIcon.iconset -o Assets/AppIcon.icns
rm -rf Assets/AppIcon.iconset
```
