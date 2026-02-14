#!/usr/bin/env bash
#
# validate-smoke-result.sh
#
# Validates a smoke result JSON file against the smoke result schema.
#
# Usage:
#   ./scripts/validate-smoke-result.sh <result-json> [schema-json]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <result-json> [schema-json]"
  exit 1
fi

RESULT_JSON="$1"
SCHEMA_JSON="${2:-$REPO_ROOT/.ai/templates/SMOKE-RESULT-SCHEMA.json}"

if [ ! -f "$RESULT_JSON" ]; then
  echo "result json not found: $RESULT_JSON"
  exit 1
fi

if [ ! -f "$SCHEMA_JSON" ]; then
  echo "schema json not found: $SCHEMA_JSON"
  exit 1
fi

python3 - "$RESULT_JSON" "$SCHEMA_JSON" <<'PY'
import json
import sys

result_path = sys.argv[1]
schema_path = sys.argv[2]

with open(result_path, encoding="utf-8") as f:
    result = json.load(f)
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)

errors = []

def type_matches(value, expected):
    if expected == "object":
        return isinstance(value, dict)
    if expected == "string":
        return isinstance(value, str)
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "null":
        return value is None
    return False

def validate(value, node, path):
    expected_type = node.get("type")
    if expected_type is not None:
        candidates = expected_type if isinstance(expected_type, list) else [expected_type]
        if not any(type_matches(value, t) for t in candidates):
            errors.append(f"{path}: invalid type, expected {candidates}")
            return

    if "enum" in node and value not in node["enum"]:
        errors.append(f"{path}: value {value!r} not in enum {node['enum']}")

    if isinstance(value, int) and "minimum" in node and value < node["minimum"]:
        errors.append(f"{path}: value {value} is less than minimum {node['minimum']}")

    if not isinstance(value, dict):
        return

    required = node.get("required", [])
    props = node.get("properties", {})

    for key in required:
        if key not in value:
            errors.append(f"{path}.{key}: missing required field")

    if node.get("additionalProperties") is False:
        for key in value:
            if key not in props:
                errors.append(f"{path}.{key}: additional property not allowed")

    for key, prop_schema in props.items():
        if key in value:
            validate(value[key], prop_schema, f"{path}.{key}")

validate(result, schema, "$")

if errors:
    print("SMOKE_RESULT_INVALID")
    for err in errors:
        print(f"- {err}")
    sys.exit(1)

print("SMOKE_RESULT_VALID")
PY
