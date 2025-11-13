# Nextcloud Image Loading Implementation

## Implemented Feature

Image loading from Nextcloud has been implemented using the WebDAV API.

## How It Works

### 1. Authentication
- Uses Basic Authentication with username and password
- Builds the WebDAV URL: `https://nextcloud.example.com/remote.php/dav/files/USERNAME/PATH`

### 2. File Listing (PROPFIND)
- Executes a PROPFIND request with Depth=infinity to list files in the folder (recursively including subfolders)
- Parses the XML response to extract file paths
- Filters only image files (jpg, jpeg, png, gif, webp, bmp, svg, tiff)

### 3. Image URL Construction
- Builds direct URLs for image download
- Adds authentication to the URL to allow download

### 4. Carousel
- Loads images into the list
- If "Random order" is active, shuffles the list
- Starts the carousel with the configured timer

## Supported Formats

- JPEG/JPG
- PNG
- GIF
- WebP
- BMP
- SVG
- TIFF

## Notes

- Credentials are included in the URL (Basic Auth)
- For better security, consider using an app password instead of the main password
- The plugin loads images asynchronously
- Images are downloaded via XMLHttpRequest and converted to base64 data URLs (since QML Image component doesn't support authenticated URLs directly)

## Troubleshooting

If images don't load:

1. **Verify credentials**: Username and password must be correct
2. **Verify path**: The photo path must exist in Nextcloud
3. **Verify permissions**: You must have access to the folder in Nextcloud
4. **Check logs**: Open QML console to see debug messages
   ```bash
   QT_LOGGING_RULES="qml.debug=true" plasmashell
   ```

## Future Improvements

- Local image cache
- OAuth2 support
- Improved error handling
- Loading progress indicator
