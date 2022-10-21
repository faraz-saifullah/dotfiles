#!/usr/bin/env bash
set -eu

shopt -s nullglob

DOTFILES_CLONE_PATH=$HOME/.dotfiles

# dotfile symlinks
echo "Symlinking all files and directories starting with '.' into $HOME"

for dotfile in "$DOTFILES_CLONE_PATH/".*; do
  # Skip `..` and '.'
  [[ $dotfile =~ \.{1,2}$ ]] && continue
  # Skip Git related
  [[ $dotfile =~ \.git$ ]] && continue
  [[ $dotfile =~ \.gitignore$ ]] && continue
  [[ $dotfile =~ \.gitattributes$ ]] && continue

  echo "Symlinking $dotfile"
  ln -sf "$dotfile" "$HOME"
done

# PACKAGES="wget zip vim net-tools zsh screen tmux curl htop systemd fonts-powerline tzdata software-properties-common lsof postgresql-client"
# PACKAGES="${PACKAGES} libgtk2.0-0 libgtk-3-0 libgbm-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb"

PACKAGES="net-tools screen postgresql-client"

# set time zone
sudo ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

# install via APT
echo "Installing packages - $PACKAGES"
sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -q -y -o Acquire::Retries=10 $PACKAGES
sudo apt-get clean

echo "dpkg reconfigure - tzdata"
DEBIAN_FRONTEND=noninteractive sudo dpkg-reconfigure --frontend noninteractive tzdata

# change shell to zsh, oh my zsh in unattended mode doesn't change shell
sudo chsh $USER -s $(which zsh)

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
# need to do this before we can use nvm
source ~/.nvm/nvm.sh
# some error, it has, unbound alias -- nvm install lts/erbium || true

# hasura cli
curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash

# terraform tfenv setup
[ -d "~/.tfenv" ] && git clone https://github.com/tfutils/tfenv.git ~/.tfenv
sudo ln -s ~/.tfenv/bin/* /usr/local/bin || true

# cloudflare argo tunnel
# sudo wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
# sudo chmod +x /usr/local/bin/cloudflared

################## 
##* kubectl setup
##################
echo "Setting up kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

################## 
##* stern setup
##################
echo "Setting up stern"
wget https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64 -O stern
chmod +x ./stern

if [[ ! -d "/home/${USER}/.oh-my-zsh" ]]
then
KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# syntax highlighting plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true
# autosuggestions plugin
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true
fi

# install github cli
# sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
# sudo apt-add-repository -y https://cli.github.com/packages
# sudo apt-get update && sudo apt-get install -q -y gh

# libraries needed for vs code live share
sudo wget -O ~/vsls-reqs https://aka.ms/vsls-linux-prereq-script && sudo chmod +x ~/vsls-reqs && sudo ~/vsls-reqs

# act https://github.com/nektos/act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

################## 
##* aws cli setup
##################
echo "Setting up aws cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
/bin/echo "y" | /usr/bin/unzip -o awscliv2.zip
sudo ./aws/install --update

# helper for configuring mfa
sudo ln -sf ${DOTFILES_CLONE_PATH}/aws-mfa.sh /usr/local/bin/aws-mfa

# update kubeconfig
KUBE_CLUSTER_NAME="casa"
aws eks update-kubeconfig --region us-east-1 --name $KUBE_CLUSTER_NAME || true

################## 
##* tctl setup - starting the docker shouldn't be part of dotfiles
##################
# echo "Setting up tctl"
# docker rm -f temporal-admin-tools 2> /dev/null || true
# sudo docker run --name temporal-admin-tools -d --rm -ti --entrypoint /bin/bash --network host --env TEMPORAL_CLI_ADDRESS=localhost:7233 temporalio/admin-tools:1.14.0
