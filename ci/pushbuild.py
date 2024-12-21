#! /usr/bin/env python

import json
import pprint
import subprocess
from pathlib import Path

import git

# Configuration
project = "TODO"
itch_project = f"idbrii/{project}"
export_root = Path("C:/code/builds/") / project


def parse_and_build_version(version_path, repo_path):
    """Builds a version from a json and git repo.

    parse_and_build_version(Path, git.Repo) -> str
    """

    with version_path.open("r") as f:
        ver = json.load(f)
    repo = git.Repo(repo_path)
    short_sha = repo.git.rev_parse("HEAD", short=True)
    return f"v{ver['major']}.{ver['minor']}.{short_sha}"


def build_platform(platform, export_root, output_artifact):
    export_path = export_root / platform
    if output_artifact:
        output_artifact = export_path / output_artifact
    else:
        output_artifact = export_path

    # TODO: Do we need to delete if it already exists?
    export_path.mkdir(parents=True, exist_ok=True)

    print()
    print(f"Building {platform} build...")
    godot = Path.home() / "scoop/apps/godot/current/godot.exe"
    if not godot.is_file():
        godot = "godot"

    print("Using godot:", godot.as_posix())

    # pprint.pprint(
    subprocess.check_call(
        [
            godot,
            "--headless",
            "--export-release",
            platform,
            output_artifact,
            project_path,
        ]
    )

    if platform == "web":
        # Enforce itchio's restrictions on web builds that I'm likely to hit.
        # https://itch.io/docs/creators/html5#zip-file-requirements
        MEGA = 1024 * 1024
        total_files = 0
        total_mb = 0
        for f in export_path.iterdir():
            total_files += 1
            size_mb = f.stat().st_size / MEGA
            total_mb += size_mb
            if size_mb > 200:
                print(
                    "Error: file exceeds itch.io maximum file size (200 MB): {} is {:.2f} MB".format(
                        f, size_mb
                    )
                )
                return

        if total_files > 1000:
            print(
                "Error: game exceeds itch.io maximum file count (1000 files):",
                total_files,
            )

        if total_mb > 500:
            print(
                "Error: game exceeds itch.io maximum file size (500 MB): {:.2f} MB".format(
                    total_mb
                )
            )

    if itch_project:
        itch_channel = f"{itch_project}:{platform}"
        print("Uploading as version", itch_channel, version)
        # pprint.pprint(
        subprocess.check_call(
            [
                "butler",
                "push",
                export_path,
                itch_channel,
                "--userversion",
                version,
            ]
        )
    else:
        print("Skipping itchio upload (empty itch_project)")


project_root = Path(__file__).resolve().parent.parent
project_path = project_root / "project.godot"
version_path = project_root / "ci/version.json"

version = parse_and_build_version(version_path, project_root)

build_platform("web", export_root, "index.html")
build_platform("win", export_root, project + ".exe")
