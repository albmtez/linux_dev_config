#!/bin/bash

script_name=$0
DEV_BASE=$HOME/dev
CODE_BASE=$HOME/code

function usage {
  echo "Usage: $script_name <bundle_or_package_name>"
  echo "    Software:"
  echo "        base_config      - Directories are created and all base software is installed (root pwd required)"
  echo "          dirs           - Directories creation"
  echo "          shell_conf     - Shell configuration, adding environment variables and executables to PATH"
  echo "          base_sw        - Install base software from apt repository (root pwd required)"
  echo "          git            - Installs git scm. You'll have to select the version to install"
  echo "        development      - Development languages and tools"
  echo "          go             - Installs the latest version of Golang"
  echo "          dart           - Install the latest version of dart"
  echo "          python         - Installs python. You'll have to select the version to install"
  echo "          node           - Installs the latest version of Node JS"
  echo "          maven          - Installs the latest version of Maven"
  echo "          ant            - Installs the latest version of Ant"
  echo "        virtualization   - Virtualization tools"
  echo "          kvm            - KVM"
  echo "          virtualbox     - Virtualbox"
  echo "          vagrant        - Vagrant"
  echo "        docker_all       - Docker engine and tools"
  echo "          docker         - Docker engine Community"
  echo "          docker-compose - Docker compose"
  echo "          docker-machine - Docker machine"
  echo "          minikube       - Minikube"
  echo "          kubectl        - Kubectl"
  echo "       provisioning      - Provision tools"
  echo "          ansible        - Ansible"
  echo "          puppet         - Puppet"
  echo "          terraform      - Terraform"
  echo "          tfm_proxmox    - Terraform provider for Proxmox"
}

function dirs_creation {
  echo "Directories creation..."
  echo "  $DEV_BASE"
  echo "  |- bin"
  echo "  $CODE_BASE"
  echo "  |- go"
  echo "  |  |- src"
  echo "  |  |- pkg"
  echo "  |  |- bin"
  echo "  |- tmp"

  # Main directories
  mkdir -p $DEV_BASE
  mkdir -p $DEV_BASE/bin
  mkdir -p $CODE_BASE
  mkdir -p $CODE_BASE/tmp

  # Go directories
  mkdir -p $CODE_BASE/go/src
  mkdir -p $CODE_BASE/go/pkg
  mkdir -p $CODE_BASE/go/bin
}

function environment_config {
  cat >$DEV_BASE/dev_profile <<EOL
# Dev environment configuration

# Dev base dir
export DEV_BASE=\$HOME/dev

# Code base dir
export CODE_BASE=\$HOME/code

# Binaries dir added to PATH
export PATH=\$DEV_BASE/bin:\$PATH

# Git config
export GIT_HOME=\$DEV_BASE/git/default
export PATH=\$GIT_HOME/bin:\$PATH

# Python config
export PYTHONPATH=\$DEV_BASE/python/default
export PATH=\$PYTHONPATH/bin:\$PATH

# Go config
export GOROOT=\$DEV_BASE/go/default
export GOPATH=\$CODE_BASE/go
export PATH=\$GOROOT/bin:\$PATH

# NodeJS config
export NODEJS_HOME=\$DEV_BASE/node/default/bin
export PATH=\$NODEJS_HOME:\$PATH

# Maven config
export MAVEN_HOME=\$DEV_BASE/apache-maven/default
export PATH=\$MAVEN_HOME/bin:\$PATH

# Ant config
export ANT_HOME=\$DEV_BASE/apache-ant/default
export PATH=\$ANT_HOME/bin:\$PATH
EOL

  cp $script_name $DEV_BASE
}

function base_sw {
  echo "Base software installation"
  echo "You'll be required to enter root password"
  sudo apt update
  sudo apt install -y build-essential git cvs subversion mercurial maven ant etckeeper \
                        git-cvs git-svn subversion-tools openjdk-11-jdk \
                        dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev \
                        libssl-dev asciidoc xmlto docbook2x install-info \
                        libffi-dev
}

function git_install {
  echo "Git scm installation"
  tmpDir=$(mktemp -d)
  cd $tmpDir
  git clone https://github.com/git/git.git
  cd git
  git fetch --tags
  tag=$(git tag -l --sort=-v:refname | grep -oP '^v[0-9\.]+$' | head -n 1)

  # Check if already installed
  [ -d $DEV_BASE/git/git-$tag ] && echo "Git version ${tag} already installed!" && rm -rf $tmpDir && unset tmpDir && exit 1

  git checkout $tag -b version-to-install
  mkdir $DEV_BASE/git
  rm -rf $DEV_BASE/git/git-$tag
  make configure
  ./configure --prefix=$DEV_BASE/git/git-$tag
  make all
  make install
  rm -f $DEV_BASE/git/default
  ln -s $DEV_BASE/git/git-$tag $DEV_BASE/git/default
  rm -rf $tmpDir
  unset tmpDir
}

function go_install {
  echo "Golang installation"
  
  # Find latest version
  echo "Finding latest version of Go for AMD64..."
  url="$(wget -qO- https://golang.org/dl/ | grep -oP '\/dl\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 )"
  latest="$(echo $url | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )"

  # Check if already installed
  [ -d $DEV_BASE/go/go-"${latest}" ] && echo "Go version ${latest} already installed!" && exit 1

  # Download Go
  tmpDir=$(mktemp -d)
  cd ${tmpDir}
  echo "Downloading latest Go for AMD64: ${latest}"
  wget --quiet --continue --show-progress "https://golang.org${url}"
  unset url

  mkdir -p $DEV_BASE/go
  tar -C $DEV_BASE/go -xzf go"${latest}".linux-amd64.tar.gz
  mv $DEV_BASE/go/go $DEV_BASE/go/go-"${latest}"
  rm -f $DEV_BASE/go/default
  ln -s $DEV_BASE/go/go-"${latest}" $DEV_BASE/go/default
  unset latest
  rm -rf ${tmpDir}
  unset tmpDir
}

function dart_install {
  echo "Dart installation"
  echo "You'll be required to enter root password"

  sudo apt-get update
  sudo apt-get install apt-transport-https
  sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
  sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
  sudo apt update
  sudo apt install -y dart
}

function python_install {
  echo "Python installation"
  tmpDir=$(mktemp -d)
  cd ${tmpDir}
  git clone https://github.com/python/cpython.git
  cd cpython
  git fetch --tags
  tag=$(git tag -l --sort=-v:refname | grep -oP '^v[0-9\.]+$' | head -n 1)

  # Check if already installed
  [ -d $DEV_BASE/python/python-$tag ] && echo "Python version ${tag} already installed!" && rm -rf $tmpDir && unset tmpDir && exit 1

  git checkout $tag -b version-to-install
  mkdir $DEV_BASE/python
  rm -rf $DEV_BASE/python/python-$tag
  ./configure --prefix=$DEV_BASE/python/python-$tag
  make
  make install
  rm -f $DEV_BASE/python/default
  ln -s $DEV_BASE/python/python-$tag $DEV_BASE/python/default
  rm -rf ${tmpDir}
  unset tmpDir
}

function node_install {
  echo "Node JS installation"

  # Find latest version
  echo "Finding latest version of NodeJS for AMD64..."
  url="$(wget -qO- https://nodejs.org/dist/latest/ | grep -oP 'node-v([0-9\.]+)\-linux-x64\.tar\.gz' | head -n 1 )"
  latest="$(echo $url | grep -oP 'node-v[0-9\.]+' | grep -oP '[0-9\.]+')"

  # Check if already installed
  [ -d $DEV_BASE/node/node-v"${latest}" ] && echo "Node version ${latest} already installed!" && exit 1

  # Download Node
  tmpDir=$(mktemp -d)
  cd ${tmpDir}
  echo "Downloading latest Node for AMD64: ${latest}"
  wget --quiet --continue --show-progress https://nodejs.org/dist/latest/"${url}"
  unset url

  mkdir -p $DEV_BASE/node
  tar -C $DEV_BASE/node -xzf node-v"${latest}"-linux-x64.tar.gz
  mv $DEV_BASE/node/node-v"${latest}"-linux-x64 $DEV_BASE/node/node-v"${latest}"
  rm -f $DEV_BASE/node/default
  ln -s $DEV_BASE/node/node-v"${latest}" $DEV_BASE/node/default

  rm -rf ${tmpDir}
  unset tmpDir
}

function maven_install {
  echo "Maven installation"

  # Find latest version
  echo "Finding latest version of Apache Maven for AMD64..."
  latest="$(wget -qO- https://apache.brunneis.com/maven/maven-3/ | grep -oP '[0-9\.]+/<' | grep -oP '[0-9\.]+' | tail -n 1)"

  # Check if already installed
  [ -d $DEV_BASE/apache-maven/apache-maven-"${latest}" ] && echo "Apache Maven version ${latest} already installed!" && exit 0

  # Download Apache Maven
  tmpDir=$(mktemp -d)
  cd ${tmpDir}
  echo "Downloading latest Apache Maven for AMD64: ${latest}"
  wget --quiet --continue --show-progress https://apache.brunneis.com/maven/maven-3/"${latest}"/binaries/apache-maven-"${latest}"-bin.tar.gz
  unset url

  mkdir -p $DEV_BASE/apache-maven
  tar -C $DEV_BASE/apache-maven -xzf apache-maven-"${latest}"-bin.tar.gz
  rm -f $DEV_BASE/apache-maven/default
  ln -s $DEV_BASE/apache-maven/apache-maven-"${latest}" $DEV_BASE/apache-maven/default

  rm -rf ${tmpDir}
  unset tmpDir
}

function ant_install {
  echo "Ant installation"

  # Find latest version
  echo "Finding latest version of Apache Ant for AMD64..."
  latest="$(wget -qO- http://apache.uvigo.es//ant/binaries/ | grep -oP 'apache-ant-([0-9\.]+)-bin.tar.gz<' | grep -oP 'ant-[0-9\.]+' | grep -oP '[0-9\.]+' | sort --version-sort | tail -n 1)"

  # Check if already installed
  [ -d $DEV_BASE/apache-ant/apache-ant-"${latest}" ] && echo "Apache Ant version ${latest} already installed!" && exit 0

  # Download Apache Ant
  tmpDir=$(mktemp -d)
  cd ${tmpDir}
  echo "Downloading latest Apache Ant for AMD64: ${latest}"
  wget --quiet --continue --show-progress http://apache.uvigo.es//ant/binaries/apache-ant-"${latest}"-bin.tar.gz
  unset url

  mkdir -p $DEV_BASE/apache-ant
  tar -C $DEV_BASE/apache-ant -xzf apache-ant-"${latest}"-bin.tar.gz
  rm -f $DEV_BASE/apache-ant/default
  ln -s $DEV_BASE/apache-ant/apache-ant-"${latest}" $DEV_BASE/apache-ant/default

  rm -rf ${tmpDir}
  unset tmpDir
}

function kvm_install {
  echo "KMV install"

  # Install packages from apt repositories
  echo "You'll be required to enter root password"
  sudo apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-top virt-manager seabios qemu-utils ovmf

  # Add user to libvirt and libvirt-qemu groups
  user=$(whoami)
  sudo usermod -a -G libvirt $user
  sudo usermod -a -G libvirt-qemu $user
  unset user
}

function virtualbox_install {
  echo "Virtualbox install"
  echo "You'll be required to enter root password"

  # Install requierd packages
  # Add packages to apt sources
  # Add repo keys
  # Install virtualbox package
  # Add user to vboxusers group
  # Recompile the kernel moduoe an install it
  user=$(whoami)
  sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  sudo add-apt-repository "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y virtualbox-6.1
  sudo usermod -a -G vboxusers $user
  unset user
}

function vagrant_install {
  echo "Vagrant install"
  echo "You'll be required to enter root password"

  # Find latest vagrant version
  latest=$(wget -qO- https://releases.hashicorp.com/vagrant/ | grep -oP '[0-9\.]+<' | grep -oP '[0-9\.]+' | head -n 1)

  # Download latest vagrant package
  tmpDir=$(mktemp -d)
  cd $tmpDir
  wget --quiet --continue --show-progress https://releases.hashicorp.com/vagrant/"${latest}"/vagrant_"${latest}"_x86_64.deb

  # Install and clean
  sudo dpkg -i ./vagrant_"${latest}"_x86_64.deb
  unset latest
  rm -rf $tmpDir
}

function docker_install {
  echo "Docker install"
  echo "You'll be required to enter root password"

  # Uninstall old versions.
  sudo apt remove -y docker docker-engine docker.io containerd runc

  # Install packages to allow apt to use a repository over HTTPS.
  sudo apt update
  sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

  # Add GPG key.
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

  # Configure apt repository.
  sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) \
        stable"

  # Install the latest version of Docker Engine - Community and containerd.
  sudo apt update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # Add the user to docker group.
  sudo usermod -aG docker $(whoami)
}

function docker_compose_install {
  echo "Docker compose install"

  version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
  echo "Installing docker compose version ${version}"
  curl -L "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" -o $DEV_BASE/bin/docker-compose
  chmod +x $DEV_BASE/bin/docker-compose
  unset version
}

function docker_machine_install {
  echo "Docker machine install"

  version=$(curl -s https://api.github.com/repos/docker/machine/releases/latest | grep 'tag_name' | cut -d\" -f4)
  echo "Installing docker machine version ${version}"
  curl -L https://github.com/docker/machine/releases/download/${version}/docker-machine-$(uname -s)-$(uname -m) -o $DEV_BASE/bin/docker-machine
  chmod +x $DEV_BASE/bin/docker-machine
  unset version
}

function minikube_install {
  echo "Minikube install"

  curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o $DEV_BASE/bin/minikube
  chmod +x $DEV_BASE/bin/minikube
}

function kubectl_install {
  echo "kubectl install"

  curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o $DEV_BASE/bin/kubectl
  chmod +x $DEV_BASE/bin/kubectl
}

function ansible_install {
  echo "Ansible install"
  echo "You'll be required to enter root password"

  sudo apt update
  sudo apt install -y ansible
}

function puppet_install {
  echo "Puppet install"
  echo "You'll be required to enter root password"

  sudo apt update
  sudo apt install -y puppet
}

function terraform_install {
  echo "Terraform install"

  # Get the latest version
  latest=$(wget -qO- https://releases.hashicorp.com/terraform/ | grep -oP 'terraform_[0-9\.]+<' | grep -oP 'terraform_[0-9.]+' | grep -oP '[0-9\.]+' | head -n 1)

  # Download zip file
  tmpDir=$(mktemp -d)
  cd ${tmpDir}
  echo "Downloading latest Terraform version: ${latest}"
  wget --quiet --continue --show-progress https://releases.hashicorp.com/terraform/"${latest}"/terraform_"${latest}"_linux_amd64.zip
  unzip "${tmpDir}"/terraform_"${latest}"_linux_amd64.zip -d ${tmpDir}
  inst_ver=""
  [ -f $DEV_BASE/bin/terraform ] && inst_ver=$($DEV_BASE/bin/terraform -version)
  latest_ver=$(${tmpDir}/terraform -version)
  if [ "${inst_ver}" = "${latest_ver}" ]; then
    echo "Terraform version ${latest} already installed"
    unset inst_ver
    unset latest_ver
    rm -rf ${tmpDir}
    exit 1
  fi
  echo "Installing Terraform ${latest}"
  cp ${tmpDir}/terraform $DEV_BASE/bin
  chmod 700 $DEV_BASE/bin/terraform
  rm -rf ${tmpDir}
  unset latest
}

function tfm_proxmox_install {
  cd $CODE_BASE/tmp
  git clone https://github.com/Telmate/terraform-provider-proxmox.git
  cd terraform-provider-proxmox
  go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox
  go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provisioner-proxmox
  make
  mkdir ~/.terraform.d/plugins
  cp bin/terraform-provider-proxmox ~/.terraform.d/plugins
  cp bin/terraform-provisioner-proxmox ~/.terraform.d/plugins
  cd $CODE_BASE/tmp
  rm -rf terraform-provider-proxmox
}

[[ "$@" = "" ]] && usage && exit 1
[ "$#" -ne 1 ] && echo "Error: Wrong number of arguments" && usage && exit 1

case "$1" in
  "base_config")
    dirs_creation
    environment_config
    base_sw
    git_install
    ;;
  "dirs")
    dirs_creation
    ;;
  "shell_conf")
    environment_config
    ;;
  "base_sw")
    base_sw
    ;;
  "git")
    git_install
    ;;
  "development")
    go_install
    dart_install
    python_install
    node_install
    maven_install
    ant_install
    ;;
  "go")
    go_install
    ;;
  "dart")
    dart_install
    ;;
  "python")
    python_install
    ;;
  "node")
    node_install
    ;;
  "maven")
    maven_install
    ;;
  "ant")
    ant_install
    ;;
  "virtualization")
    kvm_install
    virtualbox_install
    vagrant_install
    ;;
  "kvm")
    kvm_install
    ;;
  "virtualbox")
    virtualbox_install
    ;;
  "vagrant")
    vagrant_install
    ;;
  "docker_all")
    docker_install
    docker_compose_install
    docker_machine_install
    minikube_install
    kubectl_install
    ;;
  "docker")
    docker_install
    ;;
  "docker-compose")
    docker_compose_install
    ;;
  "docker-machine")
    docker_machine_install
    ;;
  "minikube")
    minikube_install
    ;;
  "kubectl")
    kubectl_install
    ;;
  "provisioning")
    ansible_install
    puppet_install
    terraform_install
    tfm_proxmox_install
    ;;
  "ansible")
    ansible_install
    ;;
  "puppet")
    puppet_install
    ;;
  "terraform")
    terraform_install
    ;;
  "tfm_proxmox")
    tfm_proxmox_install
    ;;
  *)
    echo "Error: Bundle or package name invalid" && usage && exit 1
    ;;
esac

exit 0

