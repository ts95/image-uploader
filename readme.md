Image uploader
========
A simple image uploading client for OS X. Upload target:  [img-service](https://github.com/ts95/img-service).

![Image uploader Status Menu](https://img.tonisucic.com/i/Z1qFbl6.png)

### Features
* Automatic upload of images taken with the OS X snipping tool (shift+cmd+3 & shift+cmd+4)
* Supports the following formats: gif, jpeg, jpg, png, webm, mp4, mov
* Files can be uploaded by dragging them to the menu bar icon
* Files can be uploaded directly from the clipboard
* When a mov file is uploaded it will be converted to a compressed mp4 file by
  ffmpeg before it's uploaded [1]
 
[1] Only if ffmpeg is installed on the system via homebrew.
