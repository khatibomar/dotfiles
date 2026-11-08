# dotfiles
<p>
<img src="https://github.com/user-attachments/assets/16f83416-b24a-4a3d-863e-2bee052133d7" width=300 alt/> <br/>
<em>Art by <a href="https://www.fiverr.com/macistudio">Maci</a></em><br/>
</p>

dotfiles for my linux and mac

# Tools used

https://github.com/jimeh/tmuxifier.git <br/>
https://luarocks.org/ <br/>
https://ohmyz.sh/ <br/>
https://github.com/junegunn/fzf <br/>
https://github.com/BurntSushi/ripgrep <br/>
https://github.com/lsd-rs/lsd <br/>
https://github.com/sharkdp/bat <br/>
https://github.com/golang/tools/tree/master/gopls <br/>
https://github.com/dominikh/go-tools <br/>
https://github.com/fatih/gomodifytags <br/>
https://github.com/josharian/impl <br/>
https://nodejs.org/en/download/package-manager <br/>
https://github.com/bash-lsp/bash-language-server <br/>
https://github.com/mvdan/sh <br />
https://github.com/LuaLS/lua-language-server <br />
https://cppcheck.sourceforge.io <br/>
https://github.com/bufbuild/buf <br/>
https://github.com/tamasfe/taplo <br/>
https://github.com/JohnnyMorganz/StyLua <br/>
https://github.com/aristocratos/btop <br/>
https://github.com/jstemmer/gotags <br />
https://golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment <br />
https://github.com/golangci/golangci-lint <br />
https://opencode.ai <br />

# Install

if you don't already have the GPG configured locally, you need to modify `keys/gpg_private_key.asc` <br/>
and place the real private key inside then run the script<br/>

```sh
./install.sh
```

# Sources

https://github.com/cpow/neovim-for-newbs <br/>

## GPG signing with KDE Wallet

The agent uses `config/gnupg/pinentry-kde-wallet` to run `pinentry-qt` with
`PINENTRY_KDE_USE_WALLET=1`. This enables its Secret Service integration on KDE.
KWallet's Secret Service must be running, and `pinentry-qt` must include libsecret
support (Fedora's package does). Use a password-based wallet, not a wallet encrypted
with the same GPG key, to avoid a circular unlock dependency.

Both the general config and GPG import menu steps install these settings without
replacing `~/.gnupg` or its keyring. To apply only the agent settings:

```sh
bash backup-scripts/install_gpg_agent.sh
```

An existing differing agent config is backed up beside it before replacement.
On the next signing prompt, enter the GPG passphrase and select **Save passphrase
in password manager**. Approve wallet access if KDE asks. Once saved, Pinentry
retrieves the passphrase from the wallet after agent restarts and reboots. A wallet
unlocked automatically by your login avoids a separate wallet password prompt;
a locked wallet still requires unlocking. The agent also keeps a 24-hour memory
cache between wallet lookups.

Only configuration belongs in dotfiles: never commit passwords, private keys,
or wallet files. To forget the saved passphrase, remove its **GnuPG:** entry in
KDE Wallet Manager, then run `gpgconf --reload gpg-agent` to clear the memory cache.

References: [Pinentry KDE opt-in](https://github.com/gpg/pinentry/blob/pinentry-1.3.2/pinentry/pinentry.c)
and [KWallet Secret Service](https://github.com/KDE/kwallet).

## oc dashboard

`oc top` opens the oc-top executor dashboard. In Claude Code, `/oc-agents` runs
`oc-top-launch`. Each `oc` run writes `meta.json` (start metadata) and
`result.json` (final state) into its run directory.
