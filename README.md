# http-glb-host-game-project

V-Sekai development community focuses on providing social VR functionality for the open-source Godot Engine.

## Quick start

This starts a godot engine web server that exports the editor scene as a gltf2 binary.

Tested with [https://github.com/V-Sekai/world-godot/releases/tag/latest.v-sekai-editor-152](https://github.com/V-Sekai/world-godot/releases/tag/latest.v-sekai-editor-153) which implements the `?compatible` flag for VRChat streaming via a DDS image writer.

It is recommended you have fast internet and that you use https://tailscale.com/kb/1223/funnel

```bash
tailscale funnel 8080
# Start godot editor opened to this project
```
