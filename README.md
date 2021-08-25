# Arch Linux Easy Install
This is a set of scripts that I wrote after learning how to install Arch Linux. It essentially takes the core commands from the [installation guide](https://wiki.archlinux.org/index.php/Installation_guide) and condenses them into a script. I got irritated with doing all the steps after the 10th time I installed Arch by myself and thought this would be easier.

Who this is meant for:
- A novice just wanting to install and use Arch Linux without understanding it in depth
- An intermediate user like me who's tired of doing everything every single time

Who this is NOT meant for:
- An expert user. You clearly know more than me
- A novice/intermediate user who wants to learn what's going on behind the hood

I would also explicitly like to mention that though I find the whole process tedious now, it is by doing the installation those 10 times earlier that I really learnt and understood what was happening in the installation process. The [Arch wiki](https://wiki.archlinux.org/) is a stellar source of information, not just about Arch Linux, but about Linux and UNIX-style systems in general, and anyone wanting to gain exposure to Linux internals would be well-served by going through the whole installation process by themselves and/or referring to the wiki.

## Usage
- Copy/Download the repo into your live USB
- Edit the configuration in `arch_env` to your liking
- Once done, run `source arch_runme.sh` in the booted live USB
- After installation is complete:
	- reboot and login
	- enable `systemd-networkd`, `systemd-resolved`, `iwd` and `lightdm` services (`systemctl enable <services>`)
	- restart your computer or start the above enabled services (`systemctl start <services>`)

Feel free to post issues and/or suggestions, though I may not respond to them for a while. Cheers.
