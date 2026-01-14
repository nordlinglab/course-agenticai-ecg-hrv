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
├── case-brief-individual/         # Individual case briefs (Markdown)
├── reflection-group/              # Group reflection documents (Markdown)
├── report-individual/             # Individual technical reports (Markdown)
│
├── data-group/                    # Group data submissions (folder per group)
├── project-code-group/            # Group project code (folder per group)
├── tests-group/                   # Group test cases and results (folder per group)
│
├── slides-demonstration-group/    # Group presentation slides (Beamer .tex)
└── system-design-group/           # Group system design diagrams (draw.io .drawio)
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
- `2026-Chen-Lin-Wang/` (folder for group submissions)
- `2026-Chen-Lin-Wang.tex` (Beamer slides)
- `2026-Chen-Lin-Wang.drawio` (system design)

---

## Submission Format Requirements

| Submission Type | Format | Location |
|-----------------|--------|----------|
| Case Brief (Individual) | Markdown `.md` | `case-brief-individual/` |
| Reflection (Group) | Markdown `.md` | `reflection-group/` |
| Technical Report (Individual) | Markdown `.md` | `report-individual/` |
| Data (Group) | Folder with data files incl. `README.md` | `data-group/` |
| Project Code (Group) | Folder with code incl. `README.md` | `project-code-group/` |
| Test Cases (Group) | Folder with test files incl. `README.md` | `tests-group/` |
| Presentation Slides (Group) | Beamer `.tex` (NordlingLab 16:9 template) | `slides-demonstration-group/` |
| System Design (Group) | draw.io `.drawio` XML (UML standard) | `system-design-group/` |

See the `README.md` in each folder for detailed requirements, grading criteria, and examples.

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

### Step 3: Fork the Repository

Since you have **read-only access** to this repository, one member in each group must create your own copy (fork) and ask the other group members to fork it:

1. Log in to your Atlassian account, then go to [this repository on Bitbucket](https://bitbucket.org/nordlinglab/nordlinglab-course-agenticai-ecg-hrv/)
2. Click the **"..."** button in the upper right corner
3. Select **"Fork this repository"**
4. Give your fork a name (e.g., `agenticai-submissions-yourname`), don't check `Private repository` since then your group member cannot read it unless you give them permission
5. Click **"Fork repository"**

You now have your own copy where you can make changes.

### Step 4: Clone Your Fork

```bash
# Navigate to where you want to store the project
cd ~/Documents

# Clone YOUR fork (not the original repository)
git clone git@bitbucket.org:YOUR_USERNAME/YOUR_FORK_NAME.git

# Enter the project directory
cd YOUR_FORK_NAME
```

### Step 5: Create Your Submission

1. Navigate to the appropriate folder
2. Create your file following the naming convention
3. Add required content (see folder README for requirements)

Example for case brief:
```bash
cd case-brief-individual

# Create your file (use a text editor)
# File must be named: YYYY-YourFamilyName-YourFirstName.md
```

### Step 6: Stage and Commit Your Changes

```bash
# Check what files have changed
git status

# Stage your new file(s)
git add case-brief-individual/YYYY-YourFamilyName-YourFirstName.md

# Commit with a descriptive message
git commit -m "Add case brief for YourName"
```

### Step 7: Push to Your Fork

```bash
git push origin main
```

### Step 8: Create a Pull Request

1. Go to **your fork** on Bitbucket
2. Click **"Create pull request"** (or find it under the "+" menu)
3. Set:
   - **Source:** your fork's `main` branch
   - **Destination:** the original repository's `main` branch
4. Add a title: `Submission: YYYY-YourFamilyName-YourFirstName - [type]`
5. Add description of what you're submitting
6. Click **"Create pull request"**

The TA will review your submission and merge it if it meets the requirements.

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

```bash
# Add the original repo as "upstream" (do this once)
git remote add upstream git@bitbucket.org:nordlinglab/nordlinglab-course-agenticai-ecg-hrv.git

# Fetch updates from original
git fetch upstream

# Merge updates into your branch
git merge upstream/main

# Push updates to your fork
git push origin main
```

---

## Troubleshooting

### "Permission denied" when pushing

You're trying to push to the original repository instead of your fork. Make sure you cloned your fork, not the original.

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

---

## Getting Help

- **Git documentation:** https://git-scm.com/doc
- **Bitbucket tutorials:** https://www.atlassian.com/git/tutorials
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
