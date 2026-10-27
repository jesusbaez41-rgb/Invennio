#!/usr/bin/env python3
"""
Initialization script for Invenio RDM Starter
Uses Invenio CLI commands via subprocess for all operations.
The invenio CLI commands are Python-based, so they work in Docker Hardened Images
(DHI) which lack a shell (/bin/sh) for security reasons.
"""

import os
import subprocess
import sys
import urllib.error
import urllib.request


SEARCH_HOST = os.environ.get("SEARCH_HOST", "search:9200")
SEARCH_INDEX_PREFIX = os.environ.get("INVENIO_SEARCH_INDEX_PREFIX", "invenio-rdm-")

# Search objects that are NOT created by "invenio index init" but are required
# at runtime: the job-logs data stream (data-stream-only template) and the
# statistics aggregation indices referenced on record create/delete/download.
SEARCH_DATA_STREAMS = [SEARCH_INDEX_PREFIX + "job-logs"]
SEARCH_INDICES = [
    SEARCH_INDEX_PREFIX + "stats-record-view",
    SEARCH_INDEX_PREFIX + "stats-file-download",
]


def _search_request(method, path):
    """Perform a raw HTTP request against OpenSearch and return (status, body)."""
    url = f"http://{SEARCH_HOST}{path}"
    request = urllib.request.Request(url, method=method)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, response.read().decode(errors="replace")
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode(errors="replace")


def ensure_search_objects():
    """Create the data streams and indices not covered by "invenio index init"."""
    for data_stream in SEARCH_DATA_STREAMS:
        status, body = _search_request(
            "PUT", f"/_data_stream/{data_stream}"
        )
        if status in (200, 400) and "resource_already_exists_exception" in body:
            print(f"Data stream already exists: {data_stream}")
        elif status == 200:
            print(f"Created data stream: {data_stream}")
        else:
            print(
                f"Warning: could not create data stream {data_stream} "
                f"(HTTP {status}): {body[:200]}",
                file=sys.stderr,
            )
    for index in SEARCH_INDICES:
        status, body = _search_request("PUT", f"/{index}")
        if status == 200:
            print(f"Created index: {index}")
        elif "resource_already_exists_exception" in body:
            print(f"Index already exists: {index}")
        else:
            print(
                f"Warning: could not create index {index} "
                f"(HTTP {status}): {body[:200]}",
                file=sys.stderr,
            )


def run_command(cmd, check=True, capture_output=False):
    """Execute a shell command and return the result."""
    try:
        result = subprocess.run(
            cmd,
            shell=False,
            check=check,
            capture_output=capture_output,
            text=True,
        )
        return result
    except subprocess.CalledProcessError as e:
        if check:
            print(f"Error running command: {' '.join(cmd)}", file=sys.stderr)
            print(f"Error: {e}", file=sys.stderr)
            raise
        return e


def check_custom_field_exists():
    """Check if custom field journal:journal exists."""
    result = run_command(
        [
            "invenio",
            "rdm-records",
            "custom-fields",
            "exists",
            "-f",
            "journal:journal",
        ],
        check=False,
        capture_output=True,
    )
    return "exists" in result.stdout.lower() if result.stdout else False


def main():
    """Main initialization logic."""

    try:
        print("Creating database if not exists...")
        run_command(["invenio", "db", "init", "create"])

        print("Creating files location...")
        s3_bucket = os.environ.get("INVENIO_S3_BUCKET_NAME")
        if s3_bucket:
            run_command(
                [
                    "invenio",
                    "files",
                    "location",
                    "create",
                    "--default",
                    "s3-default",
                    f"s3://{s3_bucket}",
                ]
            )
        else:
            run_command(
                [
                    "invenio",
                    "files",
                    "location",
                    "create",
                    "--default",
                    "default",
                    "file:///opt/invenio/var/instance/data",
                ]
            )

        print("Creating superuser role...")
        run_command(["invenio", "roles", "create", "admin"])
        run_command(
            [
                "invenio",
                "access",
                "allow",
                "superuser-access",
                "role",
                "admin",
            ]
        )

        print("Creating administration access role...")
        run_command(["invenio", "roles", "create", "administration"])
        run_command(
            [
                "invenio",
                "access",
                "allow",
                "administration-access",
                "role",
                "administration",
            ]
        )

        # Creating admin user if credentials are provided
        admin_email = os.environ.get("INVENIO_ADMIN_EMAIL")
        admin_password = os.environ.get("INVENIO_ADMIN_PASSWORD")

        if admin_email and admin_password:
            print(f"Creating admin user: {admin_email}...")
            run_command(
                [
                    "invenio",
                    "users",
                    "create",
                    admin_email,
                    "--password",
                    admin_password,
                    "--active",
                    "--confirm",
                ]
            )
            run_command(["invenio", "roles", "add", admin_email, "admin"])

        print("Dropping and re-creating indices...")
        run_command(["invenio", "index", "destroy", "--force", "--yes-i-know"])
        run_command(["invenio", "index", "init"])
        print("Creating search objects not covered by index init...")
        ensure_search_objects()

        print("Database and search setup completed.")

        # Check if custom fields need to be initialized
        if not check_custom_field_exists():
            print("Creating custom fields for records...")
            run_command(["invenio", "rdm-records", "custom-fields", "init"])

            print("Creating custom fields for communities...")
            run_command(["invenio", "communities", "custom-fields", "init"])

            print("Creating rdm fixtures...")
            run_command(["invenio", "rdm-records", "fixtures"])

            print("Rebuilding all indices...")
            run_command(["invenio", "rdm", "rebuild-all-indices"])

            print("Declaring queues...")
            result = run_command(
                ["invenio", "queues", "declare"],
                check=False,
                capture_output=True,
            )
            if result.returncode != 0:
                print(
                    "Warning: Failed to declare queues. This is usually non-critical."
                )
                if result.stderr:
                    print(f"Queue declaration error: {result.stderr}")

            print("Custom fields and fixtures setup completed.")

        print("Initialization completed successfully.")
    except Exception as e:
        print(f"Initialization failed: {e}", file=sys.stderr)
        import traceback

        traceback.print_exc()
        sys.exit(1)

    # Execute the command passed as arguments (e.g., gunicorn, celery)
    if len(sys.argv) > 1:
        print(f"Starting application: {' '.join(sys.argv[1:])}")
        os.execvp(sys.argv[1], sys.argv[1:])
    else:
        print("No command provided to execute.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
