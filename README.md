# LCOM aliases

Small launcher to start, stop, open, and SSH into your LCOM VirtualBox VM with short shell commands.

The installer adds these aliases:

- `alias lcomsh='LCOM_VM_NAME=<selected-vm> ~/.local/bin/lcom.sh --ssh'`
- `alias lcomshgui='LCOM_VM_NAME=<selected-vm> ~/.local/bin/lcom.sh --ssh --gui'`
- `alias lcomgui='LCOM_VM_NAME=<selected-vm> ~/.local/bin/lcom.sh --show'`
- `alias lcomstop='LCOM_VM_NAME=<selected-vm> ~/.local/bin/lcom.sh --stop'`
- `lcom_cd` (function set to shared folder)
- `alias lcomcd='lcom_cd'`

## Install

```bash
git clone --depth 1 https://github.com/afonsusousa/lcom-launcher.git && \
bash ./lcom-launcher/install.sh
```

This installs `lcom.sh` to `~/.local/bin/lcom.sh` and writes aliases to both `~/.bashrc` and `~/.zshrc`.
It prompts for a VM folder (Zenity picker when available), uses its folder name as the VM name, and sets `lcom_cd` to `<vm-folder>/shared`.
The selected VM folder must contain `MINIX-LCOM.vbox`, `MINIX-LCOM.vbox-prev`, and `MINIX-LCOM.vdi`.
