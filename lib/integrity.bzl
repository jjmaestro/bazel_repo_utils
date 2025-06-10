"""
# Subresource Integrity (SRI)

See: https://w3c.github.io/webappsec-subresource-integrity/
"""

load("@aspect_bazel_lib//lib:base64.bzl", "base64")
load("@aspect_bazel_lib//lib:strings.bzl", "chr", "hex", "ord")

# default cryptographic hash functions per the SRI spec:
# https://w3c.github.io/webappsec-subresource-integrity/#hash-functions
_ALGO_TO_HEX_DIGEST_LENGTH = {
    "sha256": 64,
    "sha384": 96,
    "sha512": 128,
}

def _is_valid_integrity_algo(algo):
    return algo in _ALGO_TO_HEX_DIGEST_LENGTH

def _is_valid_hex_digest_length(algo, hex_digest):
    return len(hex_digest) == _ALGO_TO_HEX_DIGEST_LENGTH[algo]

def _is_valid_hex_string(hex_string):
    for idx in range(len(hex_string)):
        char = hex_string[idx].upper()
        if not (char.isdigit() or (("A" <= char) and (char <= "F"))):
            return False
    return True

def _is_valid_hex_digest(algo, hex_digest):
    return all([
        _is_valid_integrity_algo(algo),
        _is_valid_hex_digest_length(algo, hex_digest),
        _is_valid_hex_string(hex_digest),
    ])

def _digest_base64_to_hex(digest_base64):
    decoded = base64.decode(digest_base64)
    return "".join([
        ("0" if ord(decoded[idx]) < 16 else "") + hex(ord(decoded[idx]))[2:]
        for idx in range(len(decoded))
    ])

def _digest_hex_to_base64(digest_hex):
    digest_bytes = "".join([
        chr(int(digest_hex[idx:idx + 2], 16))
        for idx in range(0, len(digest_hex), 2)
    ])

    return base64.encode(digest_bytes)

def _parse_sri(sri):
    # SRI (sub-resource integrity) format
    algo, digest_base64 = sri.split("-", 1)

    return algo.lower(), digest_base64

def _is_valid_sri(sri):
    algo, digest_base64 = _parse_sri(sri)
    hex_digest = _digest_base64_to_hex(digest_base64)
    return _is_valid_hex_digest(algo, hex_digest)

def _is_sri(integrity):
    return "-" in integrity

def _is_valid(integrity):
    if _is_sri(integrity):
        return _is_valid_sri(integrity)
    else:
        return _is_valid_hex_digest("sha256", integrity)

def _new(integrity, _fail = fail):
    if _is_sri(integrity):
        sri = integrity

        if not _is_valid_sri(sri):
            return _fail("Invalid integrity SRI: {}".format(sri))

        algo, digest_base64 = _parse_sri(sri)
        hex_digest = _digest_base64_to_hex(digest_base64)
    else:
        hex_digest = integrity.lower()
        algo = _ALGO_TO_HEX_DIGEST_LENGTH.get(len(hex_digest), "sha256")

        if not _is_valid_hex_digest(algo, hex_digest):
            return _fail("Invalid integrity hex digest: {}".format(hex_digest))

        sri = "%s-%s" % (algo, _digest_hex_to_base64(hex_digest))

    return struct(
        algo = algo,
        sri = sri,
        hex_digest = hex_digest,
        is_sha256 = algo == "sha256",
    )

integrity = struct(
    new = _new,
    is_valid = _is_valid,
    __test__ = struct(
        _digest_hex_to_base64 = _digest_hex_to_base64,
        _digest_base64_to_hex = _digest_base64_to_hex,
    ),
)
