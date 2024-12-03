# Linux Auto-updates script

This repo contains automation to update linux system on a periodic basis. It utilizes Linux Task automation to run a script periodically to keep your linux system up-to-date.

## To install and run the automation

1. Get the script:

```bash
curl -o installer.sh https://raw.githubusercontent.com/darshan-vayavya/linux-auto-updater/refs/heads/main/install.sh
```

2. Run the `installer.sh` shell script:

```bash
chmod +x installer.sh && sudo ./installer.sh && rm -fr ./installer.sh
```

> Optionally, you can specify the time to run the script automatically by passing the argument as:
> ```sudo ./installer.sh 9```
> *9* means **9 AM**. The Default value is `11 AM`

---

To check the update logs, you can use the command:

```bash
cat /var/log/auto_updater
```
