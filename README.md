# GitHub Actions for Testing Setup

This repository contains a collection of reusable GitHub Actions designed to help set up different testing frameworks and tools in your projects.

## Available Actions

### 1. Setup Testing Framework Action

Sets up a testing framework (Kraken, Puppeteer, Playwright, or Cypress) in your repository.

```yaml
- uses: Uniandes-MISW4103/proyecto-base-actions/.github/actions/setup-framework@main
  with:
    framework: kraken # Required: kraken, puppeteer, playwright, or cypress
    repository: ${{ github.repository }} # Required: target repository
    token: ${{ secrets.GITHUB_TOKEN }} # Optional: defaults to github.token
```

### 2. Setup Recognition Tools Action

Sets up either Monkey or Ripper testing tools in your repository.

```yaml
- uses: Uniandes-MISW4103/proyecto-base-actions/.github/actions/setup-reconocimiento@main
  with:
    tool: monkey # Required: monkey or ripper
    repository: ${{ github.repository }} # Required: target repository
    token: ${{ secrets.GITHUB_TOKEN }} # Optional: defaults to github.token
```

### 3. Setup Visual Regression Testing (VRT) Action

Sets up a visual regression testing framework in your repository.

```yaml
- uses: Uniandes-MISW4103/proyecto-base-actions/.github/actions/setup-vrt@main
  with:
    framework: resemblejs # Required: resemblejs, pixelmatch, or backstopjs
    repository: ${{ github.repository }} # Required: target repository
    token: ${{ secrets.GITHUB_TOKEN }} # Optional: defaults to github.token
```

## Usage Examples

### Setting up Kraken Testing Framework

```yaml
name: Setup Kraken
on:
  workflow_dispatch:
    inputs:
      framework:
        type: choice
        description: Framework de automatización
        options:
          - kraken
          - puppeteer
          - playwright
          - cypress

jobs:
  setup:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: read
    steps:
      - uses: Uniandes-MISW4103/proyecto-base-actions/.github/actions/setup-framework@main
        with:
          framework: ${{ github.event.inputs.framework }}
          repository: ${{ github.repository }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Setting up Monkey Testing Tool

```yaml
name: Setup Monkey
on:
  workflow_dispatch:
    inputs:
      tool:
        type: choice
        description: Recognition tool to setup
        options:
          - monkey
          - ripper

jobs:
  setup:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: read
    steps:
      - uses: Uniandes-MISW4103/proyecto-base-actions/.github/actions/setup-reconocimiento@main
        with:
          tool: ${{ github.event.inputs.tool }}
          repository: ${{ github.repository }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Setting up ResembleJS for VRT

```yaml
name: Setup VRT
on:
  workflow_dispatch:
    inputs:
      framework:
        type: choice
        description: Framework de regresión visual
        options:
          - resemblejs
          - pixelmatch
          - backstopjs

jobs:
  setup:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: read
    steps:
      - uses: Uniandes-MISW4103/proyecto-base-actions/.github/actions/setup-vrt@main
        with:
          framework: ${{ github.event.inputs.framework }}
          repository: ${{ github.repository }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

## What These Actions Do

Each action performs the following tasks:

1. Sets up Node.js 24
2. Clones the target repository
3. Clones the corresponding template repository based on your selection
4. Copies the template files to the appropriate directory in your repository
5. Configures npm scripts in your package.json
6. Commits and pushes the changes to your repository

Steps 4 and 5 live in [`scripts/install-module.sh`](scripts/install-module.sh), shared by the three
actions. The teaching team runs the same script locally to reproduce a student setup:

```bash
scripts/install-module.sh <e2e|vrt|reconocimiento> <id> <module-checkout> <student-repo-checkout>
```

## Required Permissions

The job that calls an action must grant these permissions (permissions cannot be set inside an action):

- `contents: write` - To push changes to your repository
- `packages: read` - To access npm packages

## Notes

- All actions use Node.js 24 (`actions/setup-node@v7`) and `actions/checkout@v7`.
- The module is copied to `<group>/misw-4103-<id>/` (`e2e`, `vrt` or `reconocimiento`) without its
  `.git`, `.github` and `package-lock.json`. Only npm scripts are added to the root `package.json`;
  the npm workspaces are already declared by `proyecto-base`.
- All changes are committed and pushed automatically to the branch the workflow ran on.
- Callers use these actions at `@main`, and the module repositories are checked out at their default
  branch: merging to `main` here, or in any module repository, changes what new setups receive
  immediately.
- Module repositories must be public: the student's `GITHUB_TOKEN` cannot read private repositories
  of the organization.
- Running the same setup twice without changes in the module fails at the commit step (nothing to
  commit).

## Runner Image

`docker/runner.Dockerfile` defines `ghcr.io/uniandes-misw4103/misw4103-runner`, the Linux image
that runs every course module (Cypress, Playwright, Puppeteer, Kraken, BackstopJS, PixelMatch,
ResembleJS, monkey and ripper). Students use it through `npm run docker -- <script>` in their
project repository (the `runner` service of `proyecto-base/compose.yml`); the teaching team uses it
to verify the modules and, later, to evaluate the projects in GitHub Actions.

**Contents.** Debian 13 with Node.js 24, the system libraries of the tools (Cypress prerequisites,
Playwright's Chromium dependencies, the libraries to build `canvas`), Debian's Chromium, Xvfb, git
and rsync. It contains no course code, no `node_modules` and no tool browsers: each repository
installs them from its own lockfile, into Docker volumes.

**Entrypoint** (`docker/entrypoint.sh`). Every command runs:

- as the owner of `/work`, the repository mounted from the host, so the files it writes belong to
  the user on Linux (uid 1000 when the owner is root, as Docker Desktop reports). It starts as root
  only to give that user the volumes Docker creates owned by root;
- with a virtual display (`DISPLAY=:99`), which Cypress and Kraken need;
- on `linux/arm64`, with Debian's Chromium for Puppeteer and BackstopJS, because Chrome for Testing
  has no build for that platform.

**Publishing** (`.github/workflows/publish-runner.yml`). On every push to `main` that changes
`docker/`, on the first day of each month (security updates of the base image and Debian packages)
and on demand, the workflow:

1. builds the image for `linux/amd64` and checks it (user, display, Node.js, Chromium, git, rsync);
2. builds it for `linux/amd64` and `linux/arm64` (QEMU) and pushes it to GHCR with the tags
   `node24`, which `proyecto-base/compose.yml` uses, and `node24-<commit>`, a fixed tag to go back
   to a previous image.

It authenticates with the workflow's `GITHUB_TOKEN` (`packages: write`); no secret is needed. The
GHCR package must be public so that students can pull it without logging in.

To build it locally:

```bash
docker build -t ghcr.io/uniandes-misw4103/misw4103-runner:node24 -f docker/runner.Dockerfile docker
```

## License

This project is licensed under the terms of the LICENSE file in the root directory.
