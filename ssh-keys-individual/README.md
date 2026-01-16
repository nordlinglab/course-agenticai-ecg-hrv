# SSH Public Keys - Individual Submission

This folder contains SSH public keys for individual student access to the NordlingLab computing resources.

## Why Submit Your SSH Key?

The TA will create a personal account for you on our lab's **Mac Studio M3 Ultra** (512GB RAM) so you can:

- Access your ECG and video recording data securely
- Run AI models (including local LLMs) on powerful hardware
- Process large datasets that won't fit on your laptop
- Collaborate with your group on shared computing resources

**Server:** `140.116.155.8` (Port `8801`)

---

## CRITICAL: Public Key vs Private Key

SSH uses a **key pair**: a public key and a private key. Understanding the difference is essential for security.

### How to Recognize Your Keys

| File | Name | Starts with | Safe to share? |
|------|------|-------------|----------------|
| **Public key** | `id_ed25519.pub` or `id_rsa.pub` | `ssh-ed25519 AAAA...` or `ssh-rsa AAAA...` | **YES - Submit this one** |
| **Private key** | `id_ed25519` or `id_rsa` (no extension) | `-----BEGIN OPENSSH PRIVATE KEY-----` | **NEVER share this!** |

### The Key Analogy

Think of your SSH keys like a house key system:

- **Public key** = The lock on your door. You can give copies to anyone who needs to let you in. It's useless without the matching key.
- **Private key** = The actual key to your house. **Keep it secret, keep it safe.** Anyone with this key can pretend to be you.

### What to Submit

**ONLY submit your PUBLIC key** (the `.pub` file).

```bash
# CORRECT - View your PUBLIC key (safe to share)
cat ~/.ssh/id_ed25519.pub
# Output: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your.email@example.com

# WRONG - This is your PRIVATE key (NEVER share!)
cat ~/.ssh/id_ed25519
# Output: -----BEGIN OPENSSH PRIVATE KEY-----
#         (If you see this, STOP! This is the wrong file!)
```

> **WARNING:** If you accidentally submit your private key, your security is compromised. Anyone with access to this repository could impersonate you. You must immediately generate a new key pair and notify the TA.

---

## Ed25519 vs RSA Keys

### What's the Difference?

| Feature | Ed25519 | RSA |
|---------|---------|-----|
| **Algorithm** | Elliptic curve (Curve25519) | Prime number factorization |
| **Key size** | 256 bits (fixed) | 2048-4096 bits (variable) |
| **Security** | Equivalent to RSA-3072 | Depends on key size |
| **Speed** | Faster signing/verification | Slower |
| **Key length** | Short (~68 characters) | Long (~400+ characters for 4096-bit) |
| **Introduced** | 2014 | 1977 |
| **Compatibility** | Modern systems (OpenSSH 6.5+) | All systems |

### Which Should You Use?

**Ed25519 (Recommended)** - Use this unless you have a specific reason not to:
- Shorter, more manageable keys
- Faster and more secure
- Modern standard
- Works on all modern systems (macOS, Windows 10+, recent Linux)

**RSA (4096-bit)** - Use only if:
- You need to connect to very old servers (pre-2014)
- Your organization requires RSA specifically
- You're using legacy hardware that doesn't support Ed25519

### Example Key Comparison

**Ed25519 public key** (short):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzSomeRandomChars your.email@example.com
```

**RSA-4096 public key** (long):
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLotsOfCharactersHereLotsOfCharactersHereLotsOfCharactersHereLotsOfCharactersHereLotsOfCharactersHereLotsOfCharactersHereLotsOfCharactersHereLotsOfCharactersHere... your.email@example.com
```

---

## Requirements

### File Format
- **Format:** OpenSSH public key (`.pub` file content pasted into a text file)
- **Naming:** `YYYY-FamilyName-FirstName.pub` (ASCII only)
- **Key Type:** Ed25519 (recommended) or RSA (4096-bit minimum)

### Example Submission

File: `2026-Chen-Wei.pub`

Contents:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzSomeRandomCharactersHere your.email@example.com
```

---

## Generating SSH Keys

### macOS

**Step 1: Open Terminal**

Press `Cmd + Space`, type "Terminal", and press Enter.

**Step 2: Generate SSH Key**

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Enter a passphrase (recommended) or press Enter for none
```

**Step 3: View Your Public Key**

```bash
cat ~/.ssh/id_ed25519.pub
```

**Step 4: Copy to Clipboard**

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Create your submission file (`2026-YourFamilyName-YourFirstName.pub`) and paste the contents.

---

### Windows

**Step 1: Install OpenSSH (if not already installed)**

Windows 10/11 includes OpenSSH. To verify or install:

1. Open **Settings** → **Apps** → **Optional Features**
2. Search for "OpenSSH Client"
3. If not listed, click **Add a feature** → search "OpenSSH Client" → **Install**

**Step 2: Open PowerShell or Command Prompt**

Press `Win + X` and select "Windows PowerShell" or "Terminal".

**Step 3: Generate SSH Key**

```powershell
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Press Enter to accept default location (C:\Users\YourName\.ssh\id_ed25519)
# Enter a passphrase (recommended) or press Enter for none
```

**Step 4: View Your Public Key**

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

**Step 5: Copy to Clipboard**

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard
```

Create your submission file and paste the contents.

---

### Linux (Ubuntu/Debian)

**Step 1: Open Terminal**

Press `Ctrl + Alt + T` or search for "Terminal" in your applications.

**Step 2: Generate SSH Key**

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Enter a passphrase (recommended) or press Enter for none
```

**Step 3: View Your Public Key**

```bash
cat ~/.ssh/id_ed25519.pub
```

**Step 4: Copy to Clipboard**

```bash
# Install xclip if needed
sudo apt install xclip

# Copy to clipboard
xclip -selection clipboard < ~/.ssh/id_ed25519.pub
```

Create your submission file and paste the contents.

---

## Software to Install

Install the following software on your computer to connect to and work with the lab server.

### macOS

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# SSH client (built-in, no installation needed)
# Terminal (built-in)

# Screen sharing / VNC viewer (for remote desktop)
brew install --cask vnc-viewer    # RealVNC Viewer

# Optional: Better terminal
brew install --cask iterm2

# Optional: File transfer
brew install --cask cyberduck     # SFTP client
```

### Windows

1. **SSH Client:** Built into Windows 10/11 (PowerShell or Command Prompt)

2. **Terminal (recommended):** Windows Terminal from Microsoft Store
   - https://aka.ms/terminal

3. **VNC Viewer (for remote desktop):**
   - Download RealVNC Viewer: https://www.realvnc.com/en/connect/download/viewer/

4. **Optional - SFTP Client:**
   - WinSCP: https://winscp.net/
   - FileZilla: https://filezilla-project.org/

5. **Optional - Better SSH experience:**
   - PuTTY: https://www.putty.org/ (includes PuTTYgen for key management)

### Linux (Ubuntu/Debian)

```bash
# SSH client (usually pre-installed)
sudo apt install openssh-client

# VNC viewer (for remote desktop)
sudo apt install remmina remmina-plugin-vnc

# Or RealVNC Viewer
# Download from: https://www.realvnc.com/en/connect/download/viewer/

# Optional: File transfer
sudo apt install filezilla
```

---

## Connecting to the Server

Once the TA has created your account, you can connect:

### Basic SSH Connection

```bash
# Connect to the server (replace YOUR_USERNAME with your assigned username)
ssh -p 8801 YOUR_USERNAME@140.116.155.8

# First connection: Type 'yes' to accept the server's fingerprint
```

### SSH Config (Recommended)

Add this to your `~/.ssh/config` file for easier connections:

```
Host nordlinglab
    HostName 140.116.155.8
    Port 8801
    User YOUR_USERNAME
    IdentityFile ~/.ssh/id_ed25519
```

Then simply connect with:

```bash
ssh nordlinglab
```

---

## Keeping Processes Alive

When running long computations, you need to ensure they continue even if your SSH connection drops.

### Using tmux (Recommended)

`tmux` is a terminal multiplexer that keeps your sessions alive on the server.

```bash
# Start a new tmux session
tmux new -s mysession

# Run your long-running command
python train_model.py

# Detach from session (keeps it running): Press Ctrl+b, then d

# Reconnect later
ssh nordlinglab
tmux attach -t mysession

# List all sessions
tmux ls

# Kill a session when done
tmux kill-session -t mysession
```

**Essential tmux shortcuts:**
| Shortcut | Action |
|----------|--------|
| `Ctrl+b d` | Detach from session |
| `Ctrl+b c` | Create new window |
| `Ctrl+b n` | Next window |
| `Ctrl+b p` | Previous window |
| `Ctrl+b [` | Scroll mode (q to exit) |
| `Ctrl+b %` | Split vertically |
| `Ctrl+b "` | Split horizontally |

### Using screen (Alternative)

```bash
# Start a new screen session
screen -S mysession

# Run your command
python train_model.py

# Detach: Press Ctrl+a, then d

# Reconnect later
screen -r mysession

# List sessions
screen -ls
```

### Using nohup (Simple, No Multiplexer)

For simple one-off commands:

```bash
# Run command that survives logout
nohup python train_model.py > output.log 2>&1 &

# Check if still running
ps aux | grep train_model

# View output
tail -f output.log
```

---

## Remote Desktop Access (VNC Tunneling)

For GUI applications, use VNC over SSH tunnel (secure, no X11).

### Step 1: Start VNC Server on Lab Machine (First Time Setup)

The TA will help you set this up if needed. Once configured:

```bash
# SSH into the server
ssh nordlinglab

# Start VNC server (if not already running)
# The server will tell you which display number (e.g., :1, :2)
vncserver -geometry 1920x1080

# Note the display number (e.g., ":1" means port 5901)
```

### Step 2: Create SSH Tunnel

On your local machine:

```bash
# Create tunnel (replace :1 with your display number)
# Local port 5901 -> Remote VNC port 5901
ssh -L 5901:localhost:5901 -p 8801 YOUR_USERNAME@140.116.155.8 -N

# Or using your SSH config
ssh -L 5901:localhost:5901 nordlinglab -N

# The -N flag means "don't execute a command, just forward ports"
# Keep this terminal open while using VNC
```

### Step 3: Connect with VNC Viewer

1. Open your VNC viewer application
2. Connect to: `localhost:5901` (or `127.0.0.1:5901`)
3. Enter your VNC password when prompted

### One-Line Connection (SSH + VNC)

Create a script or alias for convenience:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias vnc-lab='ssh -L 5901:localhost:5901 nordlinglab -N &; sleep 2; open vnc://localhost:5901'
```

### Stopping VNC Server

```bash
# List running VNC servers
vncserver -list

# Stop a specific display
vncserver -kill :1
```

---

## File Transfer

### Using scp (Secure Copy)

```bash
# Upload file to server
scp -P 8801 local_file.txt YOUR_USERNAME@140.116.155.8:~/

# Download file from server
scp -P 8801 YOUR_USERNAME@140.116.155.8:~/remote_file.txt ./

# Upload entire folder
scp -P 8801 -r local_folder/ YOUR_USERNAME@140.116.155.8:~/

# Using SSH config
scp local_file.txt nordlinglab:~/
```

### Using rsync (Better for Large Transfers)

```bash
# Sync folder to server (upload)
rsync -avz -e "ssh -p 8801" local_folder/ YOUR_USERNAME@140.116.155.8:~/remote_folder/

# Sync from server (download)
rsync -avz -e "ssh -p 8801" YOUR_USERNAME@140.116.155.8:~/remote_folder/ ./local_folder/

# Using SSH config
rsync -avz local_folder/ nordlinglab:~/remote_folder/
```

### Using SFTP

```bash
# Interactive SFTP session
sftp -P 8801 YOUR_USERNAME@140.116.155.8

# Or with SSH config
sftp nordlinglab

# SFTP commands:
# ls, cd, pwd       - navigate remote
# lls, lcd, lpwd    - navigate local
# get file          - download
# put file          - upload
# exit              - quit
```

---

## Troubleshooting

### "Permission denied (publickey)"

Your public key hasn't been added to the server yet, or there's a mismatch.

1. Verify you submitted the correct public key
2. Contact the TA to verify your account setup
3. Check you're using the correct private key:
   ```bash
   ssh -i ~/.ssh/id_ed25519 -p 8801 YOUR_USERNAME@140.116.155.8 -v
   ```

### "Connection refused" or "Connection timed out"

1. Verify the server address and port (140.116.155.8:8801)
2. Check if you're on the university network or VPN
3. Contact the TA if the server may be down

### VNC Connection Issues

1. Ensure the SSH tunnel is running (check the terminal)
2. Verify VNC server is running on the lab machine
3. Check you're connecting to `localhost:590X` (not the server IP directly)

### SSH Key Not Working

```bash
# Check key permissions (should be 600 for private, 644 for public)
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Test SSH with verbose output
ssh -v -p 8801 YOUR_USERNAME@140.116.155.8
```

---

## Submission Checklist

Before submitting, verify:

- [ ] File named correctly: `YYYY-YourFamilyName-YourFirstName.pub`
- [ ] Only ASCII characters in filename
- [ ] **CRITICAL: File contains the PUBLIC key, NOT the private key!**
  - Starts with `ssh-ed25519` or `ssh-rsa` (PUBLIC - correct)
  - Does NOT start with `-----BEGIN OPENSSH PRIVATE KEY-----` (PRIVATE - wrong!)
- [ ] Key is a single line (no line breaks)
- [ ] Key includes your email as comment at the end
- [ ] You have saved your private key securely and will never share it
- [ ] You have tested that your key pair works locally:
  ```bash
  # This should show the key fingerprint and type
  ssh-keygen -l -f ~/.ssh/id_ed25519.pub
  # Example output: 256 SHA256:abc123... your.email@example.com (ED25519)
  ```

---

## Security Reminders

### Protect Your Private Key Like a House Key

Your private key is like the key to your house. If someone copies it, they can enter whenever they want, and you won't know until it's too late.

1. **NEVER share your private key** (`id_ed25519` without `.pub`)
   - The private key file has NO extension
   - If you see `-----BEGIN OPENSSH PRIVATE KEY-----`, that's the private key - STOP!

2. **ONLY submit the public key** (the `.pub` file)
   - The public key starts with `ssh-ed25519` or `ssh-rsa`
   - It's a single line of text
   - Double-check before submitting!

3. **Use a passphrase** for your private key
   - This adds a second layer of protection
   - Even if someone steals your key file, they can't use it without the passphrase

4. **Keep your private key in a secure location**
   - Default location (`~/.ssh/`) is fine
   - Don't copy it to USB drives, cloud storage, or email
   - Don't commit it to git repositories

5. **If your private key is compromised:**
   - Generate a new key pair immediately
   - Notify the TA to update your authorized keys
   - Remove the old public key from all servers

6. **On shared servers:**
   - Don't store sensitive personal data unencrypted
   - Log out when done with your session
   - Don't leave sensitive information in command history
