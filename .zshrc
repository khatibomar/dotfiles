# Big cheese!! 🧀!! We're going to install a zsh package manager!

# Using the nightly, with:
# curl -L git.io/antigen-nightly > antigen.zsh
source ~/antigen.zsh

# Load the oh-my-zsh library
antigen use oh-my-zsh

# zsh has a ton of nice builtins!
# here just my favs (I haven't even seen them all)
antigen bundle git # autocompletions
antigen bundle pip # autocompletions

# A bit more exciting 😎
antigen bundle command-not-found # suggests commands
antigen bundle z # jump around!
antigen bundle colored-man-pages # Neat man pages bro

# zsh-users bundles (an awesome group of devs 🙏)
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions # Game changer!

# Shhh secret 🤫 bundles
antigen bundle thefuck # Press ESC twice to auto correct problems ;d 
antigen bundle fasd # Another z, but with opening!

# Cool gitignore creation module
antigen bundle voronkovich/gitignore.plugin.zsh 

# Nicer git diffing
antigen bundle zdharma/zsh-diff-so-fancy

# Let's add a theme! 
antigen bundle sohnryang/lambda-minimal-theme
antigen theme sohnryang/lambda-minimal-theme

# Use my old bash Aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Use my custom exports
if [ -f ~/.exports ]; then
    . ~/.exports
fi
# Always remember to antigen apply!! 🤗🤗
antigen apply
