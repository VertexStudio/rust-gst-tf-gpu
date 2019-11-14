ARG UBUNTU_VERSION=18.04

FROM nvidia/cudagl:10.0-devel-ubuntu${UBUNTU_VERSION} as base
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        mesa-utils \
        build-essential \
        sudo \
        cmake \
        libgtk2.0-dev \
        libgtk-3-dev \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libfreetype6-dev \
        libhdf5-serial-dev \
        unzip \
        zip \
        libzmq3-dev \
        python-dev \
        python-numpy \
        python3-dev \
        python3-numpy \
        python-pip \
        python3-pip \
        python-tk \
        python3-tk \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libeigen3-dev \
        libdc1394-22-dev \
        pkg-config \
        software-properties-common \
        unzip \
        zip \
        wget \
        git \
        vim \
        curl \
        libssl-dev \
        lldb \
        procps \
        lsb-release \
        x11-xserver-utils \
        libmagick++-dev

# CUDA 10.0
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-command-line-tools-10-0 \
        cuda-cublas-10-0 \
        cuda-cufft-10-0 \
        cuda-curand-10-0 \
        cuda-cusolver-10-0 \
        cuda-cusparse-10-0 \
        libcudnn7=7.4.2.24-1+cuda10.0 \
        libcudnn7-dev=7.4.2.24-1+cuda10.0

ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

RUN apt-get install -y --no-install-recommends \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    libgstrtspserver-1.0-dev \
    libgstreamer1.0-0 \
    gstreamer1.0-libav \
    gstreamer1.0-doc \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-pulseaudio \
    gtk-doc-tools

# Remove old OpenCV
RUN apt remove --purge -y libopencv-dev

# Compile OpenCV 4.1.1
RUN git clone https://github.com/opencv/opencv.git
WORKDIR /opencv
RUN git checkout 4.1.1
RUN mkdir build
WORKDIR /opencv/build
RUN cmake \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_TESTS=OFF \
    -D BUILD_DOCS=OFF \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D ENABLE_PRECOMPILED_HEADERS=OFF \
    ..
RUN make -j$(nproc)
RUN make install
RUN ldconfig

# Tensorflow 1.13.1
RUN wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-1.13.1.tar.gz \
    && tar -C /usr/local -xzf libtensorflow-gpu-linux-x86_64-1.13.1.tar.gz \
    && ldconfig
    
ARG USERNAME=sim
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /home/$USERNAME/.vscode-server /home/$USERNAME/.vscode-server-insiders \
    && chown ${USER_UID}:${USER_GID} /home/$USERNAME/.vscode-server* \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && usermod -a -G audio,video $USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME
ENV HOME /home/$USERNAME
WORKDIR $HOME

# Bazel 0.21.0
RUN wget https://github.com/bazelbuild/bazel/releases/download/0.21.0/bazel-0.21.0-installer-linux-x86_64.sh \
    && chmod +x bazel-0.21.0-installer-linux-x86_64.sh \
    && ./bazel-0.21.0-installer-linux-x86_64.sh --user \
    && echo 'export PATH=$HOME/bin:$PATH' >> $HOME/.bashrc \
    && echo 'source /home/sim/.bazel/bin/bazel-complete.bash' >> $HOME/.bashrc

# Latest Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
ENV PATH=$HOME/.cargo/bin:$PATH
RUN rustup component add rls rust-analysis rust-src rustfmt clippy fd-find ripgrep

RUN pip install --user setuptools wheel image
RUN pip3 install --user setuptools wheel image

RUN pip install --user matplotlib
RUN pip3 install --user matplotlib

RUN pip install --user tensorflow-gpu==1.13.1
RUN pip3 install --user tensorflow-gpu==1.13.1

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=