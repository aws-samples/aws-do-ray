# #!/bin/bash

# # Install python3.9
# apt update
# apt install -y software-properties-common python3-distutils python3-apt
# DEBIAN_FRONTEND=noninteractive; add-apt-repository -y ppa:deadsnakes/ppa; apt install -y python3.9; update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1

# # Install pip
# curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py; python3 get-pip.py; rm -f get-pip.py


#!/bin/bash

# Ensure non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Install python3.9
apt update
apt install -y software-properties-common python3-distutils python3-apt
add-apt-repository -y ppa:deadsnakes/ppa
apt install -y python3.9
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1

# Install pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
rm -f get-pip.py

# Install python libraries
pip3 install pillow

# Redirect python3.9 to python3.10
rm /usr/bin/python
ln -s /usr/bin/python3 /usr/bin/python

