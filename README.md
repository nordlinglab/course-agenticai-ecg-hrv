# Agentic AI Course - Student Submissions Repository

This repository contains all student submissions for the **Agentic AI** course (代理式人工智慧) at National Cheng Kung University.

---

## IMPORTANT NOTICES

### License Requirements

All submitted material **must** be licensed under one of the following:

- **Apache License 2.0** (for code)
- **CC-BY-4.0** (Creative Commons Attribution 4.0, for documentation and data)

You may **only** submit material that you have the right to make public under these licenses. Each submission folder and file **must** clearly indicate its license.

### Privacy and Data Protection

**NO PERSONALLY IDENTIFIABLE INFORMATION (PII) MAY BE INCLUDED.**

This includes but is not limited to:
- Names linked to data (other than author attribution, which naturally must be included)
- Student IDs, national IDs, or any identification numbers
- Photos of identifiable individuals
- Health data linked to identifiable persons
- Contact information of subjects
- Any information that could link collected data to a specific person

**Violation of this policy may result in immediate removal of your submission and disciplinary action.**

---

## Repository Structure

```
student-material-ecg-hrv/
│
├── README.md                      # This file
├── Syllabus_....md                # Course syllabus (reference)
│
├── ssh-keys-individual/           # Individual SSH public keys (for server access)
├── case-brief-individual/         # Individual case briefs (Markdown)
├── report-individual/             # Individual technical reports (Markdown)
├── reflection-group/              # Group reflection documents (Markdown)
│
├── data-group/                    # Group data submissions (folder per group)
│   └── 2026-Chen-Lin-Wang-data/   # Example: git submodule
│
├── project-code-group/            # Group project code (folder per group)
│   └── 2026-Chen-Lin-Wang-code/   # Example: git submodule
│
├── tests-group/                   # Group test cases and results document (Markdown)
│
├── slides-demonstration-group/    # Group presentation slides (Beamer .tex)
└── system-design-group/           # Group system design diagrams (draw.io .drawio)
```

### Example Submodules

The example data and code repositories are included as git submodules:

| Submodule | HTTPS URL | SSH URL |
|-----------|-----------|---------|
| `data-group/2026-Chen-Lin-Wang-data` | `https://github.com/nordlinglab/course-agenticai-ecg-hrv-example-data.git` | `git@github.com:nordlinglab/course-agenticai-ecg-hrv-example-data.git` |
| `project-code-group/2026-Chen-Lin-Wang-code` | `https://github.com/nordlinglab/course-agenticai-ecg-hrv-example-code.git` | `git@github.com:nordlinglab/course-agenticai-ecg-hrv-example-code.git` |

**For maintainers:** To set up these submodules, run from the main course repository:
```bash
# From nordlinglab-course-agenticai/ directory
chmod +x src/setup_example_submodules.sh
./src/setup_example_submodules.sh --help    # See all options
./src/setup_example_submodules.sh           # Use defaults
./src/setup_example_submodules.sh --register  # Initialize, push, and register
```

---

## File Naming Convention

### IMPORTANT: ASCII Characters Only

**Use only ASCII characters in file and folder names. No Chinese characters, spaces, or special characters.**

### Individual Submissions

Format: `YYYY-FamilyName-FirstName.md`

Examples:
- `2026-Chen-Wei.md`
- `2026-Lin-MeiLing.md`
- `2026-Wang-XiaoMing.md`

### Group Submissions

Format: `YYYY-FamilyName1-FamilyName2-FamilyName3/` (folder) or `YYYY-FamilyName1-FamilyName2-FamilyName3.ext` (file)

List all group members' family names in alphabetical order.

Examples:
- `2026-Chen-Lin-Wang-code` (folder for group code submissions)
- `2026-Chen-Lin-Wang.tex` (Beamer slides)
- `2026-Chen-Lin-Wang.drawio` (system design)

---

## Submission Format Requirements

| Submission Type | Format | Location |
|-----------------|--------|----------|
| SSH Public Key (Individual) | OpenSSH `.pub` | `ssh-keys-individual/` |
| Case Brief (Individual) | Markdown `.md` | `case-brief-individual/` |
| Data (Group) | Folder with data files incl. `README.md` | `data-group/` |
| Project Code (Group) | Folder with code incl. `README.md` | `project-code-group/` |
| Test Cases (Group) | Markdown `.md` with reference to `tests/` in project code | `tests-group/` |
| System Design (Group) | draw.io `.drawio` XML (UML standard) | `system-design-group/` |
| Presentation Slides (Group) | Beamer `.tex` (NordlingLab 16:9 template) | `slides-demonstration-group/` |
| Reflection (Group) | Markdown `.md` | `reflection-group/` |
| Technical Report (Individual) | Markdown `.md` | `report-individual/` |

See the `README.md` in each folder for detailed requirements, grading criteria, and examples.

### Deadline Summary

| Date | Time | Submissions Due |
|------|------|-----------------|
| Fri 2026-01-16 | 10:00 | SSH Public Key, Case Brief |
| Tue 2026-01-20 | 13:00 | Data, Project Code, Test Cases, System Design |
| Wed 2026-01-21 | 13:00 | Presentation Slides, Reflection |
| Fri 2026-01-23 | 13:00 | Technical Report |

**All times are Taiwan Standard Time (UTC+8).**

---

## Git Guide for Beginners

If you have never used Git before, follow these steps carefully.

### Step 1: Install Git

**macOS:**
```bash
# Open Terminal and run:
xcode-select --install
```

**Windows:**
Download and install from: https://git-scm.com/download/win

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install git
```

### Step 2: Configure Git

Open your terminal and set your identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Step 3: Create a GitHub Account and Install the GitHub CLI

#### If you don't have a GitHub account:

1. Go to https://github.com/signup
2. Enter your email (you can use your university email)
3. Create a password and username
4. Complete the verification and sign up

#### Install the GitHub CLI (`gh`)

The GitHub CLI makes forking, cloning, and creating pull requests much easier from the terminal.

**macOS:**
```bash
brew install gh
```

**Windows:**
```bash
# Using winget (recommended)
winget install --id GitHub.cli

# Or using scoop
scoop install gh

# Or using choco
choco install gh
```

**Linux (Ubuntu/Debian):**
```bash
# Add GitHub CLI repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

#### Authenticate the GitHub CLI

```bash
gh auth login
```

Follow the prompts:
1. Select **GitHub.com**
2. Select **HTTPS** (recommended for beginners) or **SSH**
3. Authenticate with your browser when prompted

Verify authentication:
```bash
gh auth status
```

### Step 4: Fork the Repository

Since you have **read-only access** to the original repository, you must create your own copy (fork):

#### Option A: Using the GitHub CLI (Recommended)

```bash
# Fork the repository (creates YOUR_USERNAME/course-agenticai-ecg-hrv on GitHub)
gh repo fork nordlinglab/course-agenticai-ecg-hrv --clone=false

# Verify the fork was created
gh repo list --fork
```

#### Option B: Using the Web Interface

1. Log in to [GitHub](https://github.com/)
2. Go to [this repository](https://github.com/nordlinglab/course-agenticai-ecg-hrv)
3. Click the **"Fork"** button in the upper right corner
4. Select your account as the destination
5. Click **"Create fork"**

You now have your own copy at `https://github.com/YOUR_USERNAME/course-agenticai-ecg-hrv` where you can make changes.

### Step 5: Clone Your Fork

#### Option A: Using the GitHub CLI (Recommended)

```bash
# Navigate to where you want to store the project
cd ~/Documents

# Clone YOUR fork with submodules
gh repo clone YOUR_USERNAME/course-agenticai-ecg-hrv -- --recursive

# Enter the project directory
cd course-agenticai-ecg-hrv

# Add the original repository as upstream (for pulling updates)
git remote add upstream git@github.com:nordlinglab/course-agenticai-ecg-hrv.git

# Verify remotes
git remote -v
# origin    git@github.com:YOUR_USERNAME/course-agenticai-ecg-hrv.git (your fork)
# upstream  git@github.com:nordlinglab/course-agenticai-ecg-hrv.git (original)
```

#### Option B: Using git clone directly

```bash
# Navigate to where you want to store the project
cd ~/Documents

# Clone YOUR fork with submodules (not the original repository)
# Option 1: HTTPS (recommended for beginners)
git clone --recursive https://github.com/YOUR_USERNAME/course-agenticai-ecg-hrv.git

# Option 2: SSH (if you have SSH keys set up)
git clone --recursive git@github.com:YOUR_USERNAME/course-agenticai-ecg-hrv.git

# Enter the project directory
cd course-agenticai-ecg-hrv

# Add upstream remote
git remote add upstream https://github.com/nordlinglab/course-agenticai-ecg-hrv.git
```

**Note:** The `--recursive` flag initializes all git submodules (example data and code repositories).

If you already cloned without `--recursive`, initialize submodules with:

```bash
git submodule update --init --recursive
```

### Step 6: Create Your Submission

1. Navigate to the appropriate folder
2. Create your file following the naming convention
3. Add required content (see folder [README](./case-brief-individual/README.md) for requirements)

Example for case brief:
```bash
cd case-brief-individual

# Create your file (use a text editor)
# File must be named: YYYY-YourFamilyName-YourFirstName.md
```

### Step 7: Stage and Commit Your Changes

```bash
# Check what files have changed
git status

# Stage your new file(s)
# Option 1: If you are in the folder case-brief-individual
git add YYYY-YourFamilyName-YourFirstName.md
# Option 2: If you are in the root of the repository
git add case-brief-individual/YYYY-YourFamilyName-YourFirstName.md

# Commit with a descriptive message
git commit -m "Add case brief for YourName"
```

### Step 8: Push to Your Fork

```bash
git push origin main
```

### Step 9: Create a Pull Request

#### Option A: Using the GitHub CLI (Recommended)

```bash
# Create a pull request to the original repository
gh pr create --repo nordlinglab/course-agenticai-ecg-hrv \
  --title "Submission: YYYY-YourFamilyName-YourFirstName - [type]" \
  --body "Description of what you're submitting"

# Or interactively (prompts for title and body)
gh pr create --repo nordlinglab/course-agenticai-ecg-hrv

# To create a PR to a group member's fork instead:
gh pr create --repo GROUPMATE_USERNAME/course-agenticai-ecg-hrv \
  --title "Collaboration: Adding my work" \
  --body "Description of changes"
```

#### Option B: Using the Web Interface

1. Go to **your fork** on GitHub (`github.com/YOUR_USERNAME/course-agenticai-ecg-hrv`)
2. Click **"Contribute"** → **"Open pull request"** (or click the **"Pull requests"** tab → **"New pull request"**)
3. Set:

   - **base repository:** `nordlinglab/course-agenticai-ecg-hrv` (or the group member's fork)
   - **base:** `main`
   - **head repository:** `YOUR_USERNAME/course-agenticai-ecg-hrv`
   - **compare:** `main`

4. Add a title: `Submission: YYYY-YourFamilyName-YourFirstName - [type]`
5. Add description of what you're submitting
6. Click **"Create pull request"**

The TA or group member whose repository you forked will review your submission and merge it if it meets the requirements.

---

## Common Git Commands Reference

| Command | Description |
|---------|-------------|
| `git status` | Show changed files |
| `git add <file>` | Stage a file for commit |
| `git add .` | Stage all changed files |
| `git commit -m "message"` | Commit staged changes |
| `git push` | Upload commits to remote |
| `git pull` | Download updates from remote |
| `git log` | View commit history |
| `git diff` | Show unstaged changes |

---

## Updating Your Fork

If the original repository is updated, sync your fork:

#### Option A: Using the GitHub CLI (Easiest)

```bash
# Sync your fork with the upstream repository
gh repo sync YOUR_USERNAME/course-agenticai-ecg-hrv

# Then pull the updates to your local clone
git pull origin main

# Update submodules
git submodule update --init --recursive
```

#### Option B: Using git commands

```bash
# Add the original repo as "upstream" (do this once, if not already done)
# Option 1: HTTPS
git remote add upstream https://github.com/nordlinglab/course-agenticai-ecg-hrv.git
# Option 2: SSH
git remote add upstream git@github.com:nordlinglab/course-agenticai-ecg-hrv.git

# Or if you forked a group member's repository, add multiple upstreams:
git remote add upstream-prof git@github.com:nordlinglab/course-agenticai-ecg-hrv.git
git remote add upstream-groupmate git@github.com:GROUPMATE_USERNAME/course-agenticai-ecg-hrv.git

# Fetch updates from original (including submodules)
git fetch upstream
# Or fetch from all remotes
git fetch --all

# Merge updates into your branch
git merge upstream/main

# Update submodules to latest
git submodule update --init --recursive

# Push updates to your fork
git push origin main
```

---

## Reviewing Pull Requests

This section explains how to review code changes from your group members.

### Using the GitHub CLI (Recommended)

The `gh` CLI provides powerful commands for managing pull requests from your terminal.

#### Listing Pull Requests

```bash
# List PRs in the original repository
gh pr list --repo nordlinglab/course-agenticai-ecg-hrv

# List PRs in a group member's repository
gh pr list --repo GROUPMATE_USERNAME/course-agenticai-ecg-hrv

# List only PRs assigned to you for review
gh pr list --repo nordlinglab/course-agenticai-ecg-hrv --search "review-requested:@me"
```

#### Viewing a Pull Request

```bash
# View PR details in terminal
gh pr view 123 --repo nordlinglab/course-agenticai-ecg-hrv

# View PR in web browser
gh pr view 123 --repo nordlinglab/course-agenticai-ecg-hrv --web

# View the diff (changes)
gh pr diff 123 --repo nordlinglab/course-agenticai-ecg-hrv
```

#### Checking Out a PR Locally for Review

```bash
# Check out the PR branch locally to test/review the code
gh pr checkout 123 --repo nordlinglab/course-agenticai-ecg-hrv

# Run tests, review code, etc.
# ...

# Return to your main branch when done
git checkout main
```

#### Adding Comments

```bash
# Add a general comment to a PR
gh pr comment 123 --repo nordlinglab/course-agenticai-ecg-hrv --body "Your comment here"

# Add a comment interactively (opens editor)
gh pr comment 123 --repo nordlinglab/course-agenticai-ecg-hrv
```

#### Approving or Requesting Changes

```bash
# Approve the pull request
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --approve

# Approve with a comment
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --approve --body "Looks good!"

# Request changes
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --request-changes --body "Please fix the formatting in line 42"

# Add a comment without approving or requesting changes
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --comment --body "Question about line 15..."
```

#### Merging a Pull Request

```bash
# Merge with default strategy (merge commit)
gh pr merge 123 --repo nordlinglab/course-agenticai-ecg-hrv

# Squash merge (combines all commits into one)
gh pr merge 123 --repo nordlinglab/course-agenticai-ecg-hrv --squash

# Rebase merge (replay commits on top of main)
gh pr merge 123 --repo nordlinglab/course-agenticai-ecg-hrv --rebase

# Merge and delete the branch
gh pr merge 123 --repo nordlinglab/course-agenticai-ecg-hrv --squash --delete-branch
```

#### Merging a PR into Your Local Branch

After a PR is merged on GitHub, update your local repository:

```bash
# Fetch all updates from remotes
git fetch --all

# Merge the changes into your local branch
git merge origin/main

# Or pull directly
git pull origin main

# Update submodules if any changed
git submodule update --init --recursive
```

---

### In GitHub Web Interface

#### Viewing a Pull Request

1. Go to the repository on GitHub
2. Click **"Pull requests"** tab
3. Click on the pull request you want to review
4. You'll see:

   - **"Conversation"** tab: Description, comments, and status
   - **"Commits"** tab: Individual commits in the PR
   - **"Files changed"** tab: All changed files with line-by-line diff

#### Reviewing Changes

1. Click on the **"Files changed"** tab
2. Changes are shown with:

   - **Green background:** Added lines
   - **Red background:** Removed lines

3. Hover over a line number and click the **blue +** button to add a comment

#### Adding Comments and Requesting Changes

1. Click the **blue +** button next to any line in the **"Files changed"** tab
2. Type your comment (you can use Markdown)
3. Click **"Add single comment"** for immediate comment, or **"Start a review"** to batch multiple comments
4. When done reviewing, click **"Finish your review"** and select:

   - **Comment:** General feedback without approval
   - **Approve:** Approve the changes
   - **Request changes:** Block merging until issues are fixed

#### Resolving "This branch is X commits behind"

**Problem:** You see a warning like:
> "This branch is 3 commits behind nordlinglab:main"

**What this means:** The target branch has new commits that aren't in your PR branch. You need to update your branch.

**Solution (for the author of the pull request):**

```bash
# In your local repository
cd course-agenticai-ecg-hrv

# Fetch the latest from upstream
git fetch upstream

# Merge upstream changes into your branch
git merge upstream/main

# If there are conflicts, resolve them in your editor, then:
git add .
git commit -m "Merge upstream changes"

# Push the updated branch
git push origin main
```

**Alternative - Rebase (cleaner history):**

```bash
git fetch upstream
git rebase upstream/main

# If conflicts occur, resolve them, then:
git add .
git rebase --continue

# Force push the rebased branch (required after rebase)
git push origin main --force-with-lease
```

After pushing, the pull request will automatically update and the warning should disappear.

#### Merging a Pull Request

1. Once approved and all checks pass, click the green **"Merge pull request"** button
2. Choose merge strategy from the dropdown:

   - **Create a merge commit:** Preserves all commits
   - **Squash and merge:** Combines all commits into one (recommended for clean history)
   - **Rebase and merge:** Replays commits on top of main

3. Click **"Confirm merge"**
4. Optionally click **"Delete branch"** to clean up

---

### In the Terminal

#### Setting Up Better Diff Tools

The default `git diff` output can be hard to read. Here are better alternatives:

**Option 1: Colored diff with `colordiff`**

```bash
# Install colordiff
# macOS
brew install colordiff

# Ubuntu/Debian
sudo apt install colordiff

# Usage: pipe git diff through colordiff
git diff | colordiff

# Or set it as default pager
git config --global core.pager "colordiff | less -R"
```

**Option 2: `git-delta` (Modern, feature-rich)**

```bash
# Install delta
# macOS
brew install git-delta

# Ubuntu/Debian (download from GitHub releases)
# https://github.com/dandavison/delta/releases

# Windows (with scoop)
scoop install delta

# Configure git to use delta
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
```

Delta features:

- Syntax highlighting
- Side-by-side view
- Line numbers
- Word-level diff highlighting

#### Reviewing a Pull Request Locally (Alternative to `gh pr checkout`)

If you prefer using git commands directly:

```bash
# Fetch the pull request branch from your group member's fork
# First, add their fork as a remote (do this once)
git remote add groupmate git@github.com:GROUPMATE_USERNAME/course-agenticai-ecg-hrv.git

# Fetch their branches
git fetch groupmate

# View the diff between your main and their branch
# Option 1: built-in diff
git diff main..groupmate/main
# Option 2: delta for better visualization
git diff main..groupmate/main | delta

# View only file names that changed
git diff --name-only main..groupmate/main

# View diff statistics (lines added/removed per file)
git diff --stat main..groupmate/main
```

#### Checking Out a Pull Request Branch for Testing

```bash
# Option 1: Using gh CLI (recommended)
gh pr checkout 123 --repo nordlinglab/course-agenticai-ecg-hrv

# Option 2: Manual checkout from group member's remote
git checkout -b review-groupmate groupmate/main

# Run tests, check the code, etc.
# ...

# When done, switch back to your branch
git checkout main

# Delete the review branch
git branch -d review-groupmate
```

#### Viewing Commit History

```bash
# See commits in the PR
git log main..groupmate/main --oneline

# See commits with full details
git log main..groupmate/main

# See commits as a graph
git log main..groupmate/main --oneline --graph
```

#### Adding Comments via Command Line

Use the GitHub CLI for all PR interactions:

```bash
# Add a comment to a PR
gh pr comment 123 --repo nordlinglab/course-agenticai-ecg-hrv --body "Your comment here"

# Add a review comment
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --comment --body "Please check line 42"

# Approve the PR
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --approve --body "LGTM!"

# Request changes
gh pr review 123 --repo nordlinglab/course-agenticai-ecg-hrv --request-changes --body "Please fix the bug in function X"
```

**Alternative: Using the GitHub REST API directly:**

```bash
# Add a comment to a PR (requires personal access token)
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d '{"body": "Your comment here"}' \
  "https://api.github.com/repos/nordlinglab/course-agenticai-ecg-hrv/issues/123/comments"
```

For most users, the `gh` CLI is the easiest way to manage pull request comments from the terminal.

---

### In VS Code

#### Built-in Git Diff

1. Open VS Code in your repository folder
2. Click the **Source Control** icon (branch icon) in the left sidebar, or press `Ctrl+Shift+G` / `Cmd+Shift+G`
3. Changed files appear in the sidebar
4. Click any file to see a side-by-side diff view

#### Comparing Branches

1. Open the Command Palette: `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type **"Git: Checkout to..."** and select the branch to compare
3. Or use the **GitLens** extension for more powerful comparisons

#### Using GitLens Extension (Recommended)

**Install GitLens:**

1. Go to Extensions (`Ctrl+Shift+X` / `Cmd+Shift+X`)
2. Search for **"GitLens"**
3. Click **Install**

**Compare branches with GitLens:**

1. Click the **GitLens** icon in the sidebar
2. Expand **"Compare"** section
3. Click **"Compare References..."**
4. Select your branch (e.g., `main`)
5. Select the branch to compare against (e.g., `groupmate/main`)
6. GitLens shows:

   - List of changed files
   - Number of commits difference
   - Click any file to see the diff

**Review inline blame:**

- GitLens shows who changed each line and when
- Hover over any line to see the commit details

#### Fetching and Reviewing Remote Branches in VS Code

1. Open the Command Palette: `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type **"Git: Fetch From..."**
3. Select the remote (e.g., `groupmate`)
4. Now you can compare against `groupmate/main`

#### VS Code Pull Request Extension (Recommended for GitHub)

GitHub has excellent native VS Code support:

1. Install **"GitHub Pull Requests and Issues"** extension from Extensions (or use the built-in support)
2. Click the GitHub icon in the sidebar
3. Sign in to your GitHub account when prompted
4. You can now:

   - View all pull requests in the repository
   - Create new pull requests directly from VS Code
   - Review code with inline comments
   - Approve, request changes, or merge PRs
   - Check out PR branches with one click

---

## Troubleshooting

### "Permission denied" when pushing

**Problem:** You see "Permission denied" or "403 Forbidden" when trying to push.

**Cause:** You're either not authenticated or trying to push to a repository you don't have write access to.

**Solutions:**

1. **Check you're pushing to your fork, not the original:**

```bash
git remote -v
```

If it shows `nordlinglab` in the origin URL, you cloned the original instead of your fork. Fix it:

```bash
# Option 1: HTTPS
git remote set-url origin https://github.com/YOUR_USERNAME/course-agenticai-ecg-hrv.git

# Option 2: SSH
git remote set-url origin git@github.com:YOUR_USERNAME/course-agenticai-ecg-hrv.git
```

2. **Re-authenticate with the GitHub CLI:**

```bash
gh auth login
gh auth status  # Verify you're logged in
```

3. **Check your SSH key is added (if using SSH):**

```bash
ssh -T git@github.com
# Should say: "Hi USERNAME! You've successfully authenticated..."
```

### "Repository not found" error

**Problem:** Git says the repository doesn't exist when you try to clone or push.

**Solutions:**

1. Check the URL is correct (no typos)
2. Ensure the repository exists and is not private (or you have access)
3. Verify you're authenticated: `gh auth status`

### Fork not showing in your account

**Problem:** You clicked "Fork" but can't find the repository in your account.

**Solution:** Check your repositories:

```bash
gh repo list --fork
```

Or visit: `https://github.com/YOUR_USERNAME?tab=repositories`

### Merge conflicts

If your pull request shows conflicts:

1. Pull the latest changes: `git pull upstream main`
2. Resolve conflicts in your editor
3. Commit the resolved files
4. Push again

### Wrong file name

If you named your file incorrectly:
```bash
# Rename the file
git mv old-name.md YYYY-CorrectName-Format.md
git commit -m "Fix file naming"
git push
```

### Authentication issues with HTTPS

**Problem:** Git keeps asking for username/password when pushing/pulling.

**Solution: Use the GitHub CLI for authentication (Recommended)**

```bash
# Authenticate with GitHub
gh auth login

# Choose HTTPS when prompted
# This stores credentials securely

# Verify authentication
gh auth status
```

**Alternative: Use a Personal Access Token**

1. Go to https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Give it a name, set expiration, and select `repo` scope
4. Copy the token
5. Use the token as your password when git prompts

**Best solution: Set up SSH keys (More convenient long-term)**

SSH keys let you authenticate without entering credentials each time. Follow the instructions below for your operating system.

---

### Setting up SSH Keys for GitHub

#### macOS

**Step 1: Check for existing SSH keys**

```bash
ls -la ~/.ssh
```
If you see `id_ed25519` and `id_ed25519.pub` (or `id_rsa` and `id_rsa.pub`), you already have keys. Skip to Step 3.

**Step 2: Generate a new SSH key**

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

- Press Enter to accept the default file location
- Enter a passphrase (optional but recommended) or press Enter for no passphrase

**Step 3: Start the SSH agent and add your key**

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Step 4: Copy your public key**

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```
This copies the key to your clipboard.

**Step 5: Add the key to GitHub**

1. Go to https://github.com/settings/keys
2. Click **"Add key"**
3. Give it a label (e.g., "My MacBook")
4. Paste the key (Cmd+V)
5. Click **"Add key"**

**Step 6: Test the connection**

```bash
ssh -T git@github.com
```
You should see: "Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access."

**Step 7: Update your repository to use SSH**

```bash
cd course-agenticai-ecg-hrv
git remote set-url origin git@github.com:YOUR_USERNAME/course-agenticai-ecg-hrv.git
```

---

#### Windows

**Step 1: Open Git Bash**

If you installed Git for Windows, you have Git Bash. Search for "Git Bash" in the Start menu.

**Step 2: Check for existing SSH keys**

```bash
ls -la ~/.ssh
```
If you see `id_ed25519` and `id_ed25519.pub`, you already have keys. Skip to Step 4.

**Step 3: Generate a new SSH key**

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

- Press Enter to accept the default file location
- Enter a passphrase (optional) or press Enter for no passphrase

**Step 4: Start the SSH agent and add your key**

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Step 5: Copy your public key**

```bash
clip < ~/.ssh/id_ed25519.pub
```
This copies the key to your clipboard.

**Step 6: Add the key to GitHub**

1. Go to https://github.com/settings/keys
2. Click **"Add key"**
3. Give it a label (e.g., "My Windows PC")
4. Paste the key (Ctrl+V)
5. Click **"Add key"**

**Step 7: Test the connection**

```bash
ssh -T git@github.com
```
You should see: "Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access."

**Step 8: Update your repository to use SSH**

```bash
cd course-agenticai-ecg-hrv
git remote set-url origin git@github.com:YOUR_USERNAME/course-agenticai-ecg-hrv.git
```

---

#### Linux (Ubuntu/Debian)

**Step 1: Check for existing SSH keys**

```bash
ls -la ~/.ssh
```
If you see `id_ed25519` and `id_ed25519.pub`, you already have keys. Skip to Step 3.

**Step 2: Generate a new SSH key**

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```
- Press Enter to accept the default file location
- Enter a passphrase (optional but recommended) or press Enter for no passphrase

**Step 3: Start the SSH agent and add your key**

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Step 4: Copy your public key**

```bash
# Install xclip if not installed
sudo apt install xclip

# Copy to clipboard
xclip -selection clipboard < ~/.ssh/id_ed25519.pub
```

Or manually display and copy:
```bash
cat ~/.ssh/id_ed25519.pub
```
Then select and copy the output.

**Step 5: Add the key to GitHub**

1. Go to https://github.com/settings/keys
2. Click **"Add key"**
3. Give it a label (e.g., "My Linux PC")
4. Paste the key (Ctrl+Shift+V in terminal, or Ctrl+V in browser)
5. Click **"Add key"**

**Step 6: Test the connection**

```bash
ssh -T git@github.com
```
You should see: "Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access."

**Step 7: Update your repository to use SSH**

```bash
cd course-agenticai-ecg-hrv
git remote set-url origin git@github.com:YOUR_USERNAME/course-agenticai-ecg-hrv.git
```

---

## Getting Help

- **Git documentation:** https://git-scm.com/doc
- **GitHub documentation:** https://docs.github.com/
- **GitHub CLI manual:** https://cli.github.com/manual/
- **TA contact:** See course syllabus for TA information

---

## License and Disclaimer

**Author:** Torbjörn E. M. Nordling, PhD

Unless otherwise specified, content in this repository is licensed under:

- **Documentation:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **Source Code:** [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

See individual submissions for specific license declarations.

THIS DOCUMENT AND ALL ASSOCIATED CODE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THIS DOCUMENT OR THE USE OR OTHER DEALINGS IN THIS DOCUMENT.
