# RW Target Root Resolution Contract

Purpose:
- Define one canonical way to resolve the active RW target root.

Authoritative resolver:
- `scripts/rw-resolve-target-root.sh`

Required behavior:
1) Run the resolver against workspace root.
2) Load emitted key/value pairs:
   - `TARGET_ACTIVE_ID_FILE`
   - `TARGET_REGISTRY_DIR`
   - `TARGET_POINTER_FILE`
   - `TARGET_ID`
   - `RAW_TARGET`
   - `TARGET_ROOT`
3) Ignore any prompt argument for target-root resolution.
4) Preserve resolver auto-repair behavior exactly as implemented in the script.
5) Treat `TARGET_ROOT` as authoritative for all `<...>` path bindings.

Validation baseline:
- `TARGET_ROOT` must be a non-empty absolute path.
- `TARGET_ROOT` directory must exist and be readable.

Failure token:
- `RW_TARGET_ROOT_INVALID`
