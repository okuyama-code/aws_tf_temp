#!/bin/bash
echo "EC2 起動スクリプト実行中..."
sudo yum update -y
sudo yum install -y postgresql16 git

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
echo -e "\n. $HOME/.asdf/asdf.sh" >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
source ~/.bashrc

asdf update
asdf plugin add nodejs
asdf install nodejs 22.11.0
asdf global nodejs 22.11.0
npm update -g npm

mkdir ~/app

# TODO: .envにDB接続情報を記述

echo "EC2 起動スクリプト完了"
