# To install just on a per-project basis
# 1. Activate your virtual environemnt
# 2. uv add --dev rust-just
# 3. Use just within the activated environment


drive_uuid := "77688511-78c5-4de3-9108-b631ff823ef4"
user :=  file_stem(home_dir())
def_drive := join("/media", user, drive_uuid, "env")
project := file_stem(justfile_dir())
local_env := join(justfile_dir(), ".env")
base_url := "http://localhost:8000"

pkg := "textual-spectess"
module := "spectess"

# list all recipes
default:
    just --list

# Install tools globally
tools:
    uv tool install twine
    uv tool install ruff

# Add conveniente development dependencies
dev:
    uv add --dev pytest

# Build the package
build:
    rm -fr dist/*
    uv build

# Publish the package to PyPi
publish: build
    twine upload -r pypi dist/*
    uv run --no-project --with {{pkg}} --refresh-package {{pkg}} \
        -- python -c "from {{module}} import __version__; print(__version__)"

# Publish to Test PyPi server
test-publish: build
    twine upload --verbose -r testpypi dist/*
    uv run --no-project  --with {{pkg}} --refresh-package {{pkg}} \
        --index-url https://test.pypi.org/simple/ \
        --extra-index-url https://pypi.org/simple/ \
        -- python -c "from {{module}} import __version__; print(__version__)"


# ---------------------------
# LICA Library handling stuff
# ---------------------------

# Adds lica source library as dependency. 'version' may be a tag or branch
lica-dev version="main":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Removing previous LICA dependency"
    uv remove lica || echo "Ignoring non existing LICA library";
    if [[ "{{ version }}" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "Adding LICA source library --tag {{ version }}"; 
        uv add git+https://github.com/guaix-ucm/lica --tag {{ version }};
    else
        echo "Adding LICA source library --branch {{ version }}";
        uv add git+https://github.com/guaix-ucm/lica --branch {{ version }};
    fi

# Adds lica release library as dependency with a given version
lica-rel version="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Removing previous LICA dependency"
    uv remove lica || echo "Ignoring non existing LICA library";
    echo "Adding LICA library {{ version }}";
    uv add --refresh-package lica lica[aiosqlalchemy] {{ version }};


# Backup .env to storage unit
env-bak drive=def_drive: (check_mnt drive) (env-backup join(drive, project))

# Restore .env from storage unit
env-rst drive=def_drive: (check_mnt drive) (env-restore join(drive, project))


# Post a TAS scan file with curl
post: (do_post join(justfile_dir(), "data", "TASC8F.txt") join(base_url, "upload"))

[private]
check_mnt mnt:
    #!/usr/bin/env bash
    set -euxo pipefail
    test -d {{ mnt }} || exit $?


[private]
env-backup bak_dir:
    #!/usr/bin/env bash
    set -euxo pipefail
    mkdir -p {{ bak_dir }} || exit $?
    cp {{ join(justfile_dir(), ".env") }} {{ bak_dir }}  || exit $?
    cp {{ join(justfile_dir(), "data", "TASC8F.txt") }} {{ bak_dir }} || exit $?

[private]
env-restore bak_dir:
    #!/usr/bin/env bash
    set -euxo pipefail
    cp {{ join(bak_dir, ".env" ) }} {{ join(justfile_dir(), ".env") }} || exit $?
    cp {{ join(bak_dir, "TASC8F.txt") }} {{ join(justfile_dir(), "data") }} || exit $?

[private]
do_post file url:
    #!/usr/bin/env bash
    set -euxo pipefail
    curl -X POST  -F file1=@{{file}} {{url}}