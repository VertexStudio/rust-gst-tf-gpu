# VSCode Devcontainer

## Contains
- Rust
- GStreamer
- TensorFlow 1.13.1
- CUDA 10.0
- cuDNN 7.4
- OpenCV 4.1.1

## Setup

- Move to the root directory of your project and run:
```
git submodule add git@github.com:VertexStudio/rust-gst-tf-gpu.git .devcontainer
```
- Install the VSCode extension [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Press <kbd>F1</kbd> to bring up the Command Palette and type in *remote-containers* for a full list of commands
- Run the `Remote-Containers: Reopen in Container` command or run `Remote-Containers: Open Folder in Container...` command and select the local folder

> **Note:** If you don't want this as a Git Submodule, you may also choose to download this repository as a **zip**, extract its content, and paste it in a `.devcontainer` directory at the root of your project.
