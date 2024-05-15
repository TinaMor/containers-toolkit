## Introduction

Provide a brief summary of the update.

## New Features

List the new features and give a short description of what the feature does

## Bug fixes

Bulleted list of bug fixes and issue resolutions: Discuss the resolved issues and their impact.

## Known issues

Ongoing issue that are still being worked on

## Quick start guide

### Install from PowerShell Gallery

```PowerShell
Install-Module -Name Containers-Toolkit -RequiredVersion "__NEW_VERSTION__"
```

If the module is already installed, update the module:

```PowerShell
Update-Module -Name Containers-Toolkit -RequiredVersion "__NEW_VERSTION__"
```

### Download Source Files

1. Open a new terminal
2. cd into the location of the downloaded files
    Example: If downloaded to the downloads folder:

    ```PowerShell
    cd "$env:USERPROFILE\Downloads\containers-toolkit"
    ```

3. Unblock the files

    ```PowerShell
    Get-ChildItem -Path . -Recurse | Unblock-File"
    ```

4. Import the module

See instructions in the [Installing and importting Containers-Toolkit module](../../README.md#download-source-files) section

## Visuals

(Screenshots, Side-by-side comparisons, 30-second videos)

## Discussions

For any questions or feedback on this release, see the discussion: [Containers.ToolKit v__NEW_VERSTION__](<LINK-TO-VERSION-DISCUSSION>)

## Release Authors

[ADD YOUR NAME HERE] (@[ADD YOUR GITHUB ID HERE])
