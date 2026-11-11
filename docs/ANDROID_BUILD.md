# Android build notes

- Engine: Godot 4.x.
- Renderer: Compatibility (OpenGL ES 3), selected for broader Android device support.
- Input: touchscreen first; mouse input remains useful during desktop testing.
- Initial target: portrait layout, with a board camera that can later support rotation and zoom.
- Keep textures compressed and avoid large external asset packs.
- Test frame rate, touch accuracy, thermal behaviour, and memory use on the actual target phone before release.

Android export requires the matching Godot export templates and Android build prerequisites configured in the editor. The repository does not yet contain a signed APK or export credentials.