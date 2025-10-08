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

1. Sets up Node.js with the latest LTS version
2. Clones the target repository
3. Clones the corresponding template repository based on your selection
4. Copies the template files to the appropriate directory in your repository
5. Configures npm scripts in your package.json
6. Commits and pushes the changes to your repository

## Required Permissions

All actions require the following permissions:

- `contents: write` - To push changes to your repository
- `packages: read` - To access npm packages

## Notes

- All actions use Node.js LTS (Iron) version
- The actions will create appropriate directory structures in your repository
- NPM workspace configuration will be added to your package.json
- All changes are committed and pushed automatically

## License

This project is licensed under the terms of the LICENSE file in the root directory.
