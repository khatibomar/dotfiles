
## dotfiles for my local setup
---------------------------------


This simple yet effective technique lets you track the files you care about
and it doesn't require any tools other than git. The files will be kept at
their intended location, without the need to create symlinks or copies.

Files are added to the repository by calling `dots add $HOME/.config/file` and when
issuing `git status` - only changes to files explicitly added will be shown.

To get a list of files not tracked by git, use `dots untracked` or `dots untracked-at $HOME/path/to/foo/bar`
to only show files in a specific subdirectory.

Dead simple!
# Clone and add configs
do this if you want to add files to the repo , replace repo link with yours

## Prerequisites
via Git clone

### Clone this repository to your home directory.

```bash
git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1
```

Add to the ~/.bashrc in case of using bash:

```bash
if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    source $HOME/.bash-git-prompt/gitprompt.sh
fi
```

I moved to zsh , to install zsh
```bash
sudo apt-get install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
source ~/.zshrc
curl -L git.io/antigen > antigen.zsh
chsh -s $(which zsh)
```

to display fonts correctly please install [Noto Color Emoji](https://www.google.com/get/noto/#emoji-zsye-color) by putting it in `~/.fonts` then
```bash
fc-cache -f -v
```

install terminator :
```bash
sudo apt-get install terminator
```

install kitty terminal : 
```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```
⚠️ this installation uses https://github.com/dexpota/kitty-themes , download it


install rsync - Arch
```
pacman -S rsync //arch
apt-get install rsync //ubuntu
```

#### Alias
~~~ sh
alias dots='git --git-dir=$HOME/.dots.git/ --work-tree=$HOME'
~~~

#### Setup
~~~ sh
git init --bare $HOME/.dots.git
dots remote add origin https://github.com/OmarElKhatibCS/dotfiles_v2.git
~~~

#### Configuration
~~~ sh
dots config status.showUntrackedFiles no

# Useful aliases
dots config alias.untracked "status -u ."
dots config alias.untracked-at "status -u"
~~~

#### Usage
~~~ sh
# Use the dots alias like you would use the git command
dots status
dots add --update ...
dots commit -m "..."
dots push

# Listing files (not tracked by git)
dots untracked
dots status -u .config/

# Listing files (tracked by git)
dots ls-files
dots ls-files .config/polybar/
~~~

# Install on your local machine
~~~ sh
echo "alias dots='git --git-dir=$HOME/.dots.git/ --work-tree=$HOME'" >> $HOME/.bashrc
source $HOME/.bashrc
git clone --recursive --separate-git-dir=$HOME/.dots.git https://github.com/OmarElKhatibCS/dotfiles_v2.git /tmp/dots
rsync -rvl --exclude ".git" /tmp/dots/ $HOME/
rm -r /tmp/dots
dots submodule update --init --recursive $HOME/
~~~

### Note
this template is from the dotfiles for [jaagr dots](https://github.com/jaagr/dots)
