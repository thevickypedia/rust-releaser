# rust-releaser
Internal GHA to build, test and upload artifact for a rust release

### Sample Usage

```yaml
name: Rust Releaser

on:
  push:
    branches: "*"

jobs:
  build:
    uses: thevickypedia/rust-releaser/.github/workflows/releaser.yml@main
    secrets: inherit
```
