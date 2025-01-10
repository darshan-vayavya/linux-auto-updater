# Linux Auto-updates script

This repo contains automation to update linux system on a periodic basis. It utilizes Linux Task automation to run a script periodically to keep your linux system up-to-date.

## To install and run the automation

1. Get the script:

```bash
curl -o installer.sh https://raw.githubusercontent.com/darshan-vayavya/linux-auto-updater/refs/heads/main/install.sh
```

2. Verify the signature (Optional - But good practice):

- Get my public key (if not done before) -

```bash
gpg --recv-keys EC5FA67D1FC13FEAE955E826C8906CC6629D01D9
```

- Download the signature file and verify -

```bash
curl -o installer.sig https://raw.githubusercontent.com/darshan-vayavya/linux-auto-updater/refs/heads/main/install.sh.sig && gpg --verify installer.sig installer.sh
```

> Ensure that it shows **Good signature from "Darshan (Darshan's Signing Key for Code at Work) <darshanp@vayavyalabs.com>"**

3. Run the `installer.sh` shell script:

```bash
chmod +x installer.sh && sudo ./installer.sh && rm -f ./installer.sh ./installer.sig
```

> Optionally, you can specify the time to run the script automatically by passing the argument as:
> ```sudo ./installer.sh 9```
> *9* means **9 AM**. The Default value is `11 AM`

---

To check the update logs, you can use the command:

```bash
cat /var/log/auto_updater
```
