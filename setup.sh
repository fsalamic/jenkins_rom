echo $TELEGRAM_TOKEN >/tmp/tg_token
echo $TELEGRAM_CHAT >/tmp/tg_chat
echo $GITHUB_TOKEN >/tmp/gh_token

sudo cp github-release /usr/bin
sudo cp telegram /usr/bin
sudo "bash build.sh"