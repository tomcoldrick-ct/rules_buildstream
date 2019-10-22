FROM fedora

RUN dnf install -y python3 fuse bubblewrap python3-pip python3-devel
RUN dnf install -y bzr git lzip patch ostree python3-gobject
RUN pip3 install --user arpy
RUN dnf install -y gcc
RUN pip3 install --user BuildStream==1.4.1
RUN git clone https://gitlab.com/BuildStream/bst-external.git
RUN cd bst-external && pip install --user -e .

RUN dnf install -y wget which unzip
RUN wget https://github.com/bazelbuild/bazel/releases/download/0.29.1/bazel-0.29.1-installer-linux-x86_64.sh
RUN chmod +x bazel-0.29.1-installer-linux-x86_64.sh
RUN ./bazel-0.29.1-installer-linux-x86_64.sh --user

RUN echo "export PATH=$PATH:$HOME/bin:$HOME/.local/bin" >> ~/.bashrc
