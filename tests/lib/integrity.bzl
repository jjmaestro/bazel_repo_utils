"integrity.bzl unit tests"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:integrity.bzl", Integrity = "integrity")
load("//tests:mock.bzl", Mock = "mock")
load("//tests:suite.bzl", _test_suite = "test_suite")

def _digest_hex_to_base64_impl(ctx):
    env = unittest.begin(ctx)

    hex_digest = "ec7a01752aa6484fd477ef0fce4725a4cf1eddeb3df8f27891e3364bd2a8ea99"
    expected = "7HoBdSqmSE/Ud+8PzkclpM8e3es9+PJ4keM2S9Ko6pk="

    res = Integrity.__test__._digest_hex_to_base64(hex_digest)
    asserts.equals(env, expected, res)

    return unittest.end(env)

digest_hex_to_base64_test = unittest.make(_digest_hex_to_base64_impl)

def _digest_base64_to_hex_impl(ctx):
    env = unittest.begin(ctx)

    base64 = "7HoBdSqmSE/Ud+8PzkclpM8e3es9+PJ4keM2S9Ko6pk="
    expected = "ec7a01752aa6484fd477ef0fce4725a4cf1eddeb3df8f27891e3364bd2a8ea99"

    res = Integrity.__test__._digest_base64_to_hex(base64)
    asserts.equals(env, expected, res)

    return unittest.end(env)

digest_base64_to_hex_test = unittest.make(_digest_base64_to_hex_impl)

def _is_valid_impl(ctx):
    env = unittest.begin(ctx)

    valid_sri = "sha256-3q2zP96tsz/erbM/3q2zP96tsz/erbM/3q2zP96tsz8="
    asserts.true(env, Integrity.is_valid(valid_sri))

    valid_hex_digest = "deadb33f" * 8
    asserts.true(env, Integrity.is_valid(valid_hex_digest))

    invalid_integrities = [
        valid_hex_digest[:-1],  # invalid hex digest length
        "X234" * 16,  # invalid hex char
        valid_sri[:-1],  # invalid SRI base64
    ]

    for invalid_integrity in invalid_integrities:
        asserts.false(env, Integrity.is_valid(invalid_integrity))

    return unittest.end(env)

is_valid_test = unittest.make(_is_valid_impl)

def _new_impl(ctx):
    env = unittest.begin(ctx)

    expected_sri = "sha256-3q2zP96tsz/erbM/3q2zP96tsz/erbM/3q2zP96tsz8="
    expected_algo = "sha256"
    expected_hex_digest = "deadb33f" * 8

    for integrity in (expected_sri, expected_hex_digest):
        res = Integrity.new(integrity)

        asserts.equals(env, expected_algo, res.algo)
        asserts.equals(env, expected_sri, res.sri)
        asserts.equals(env, expected_hex_digest, res.hex_digest)
        asserts.true(env, res.is_sha256)

    invalid_integrities = [
        expected_hex_digest[:-1],  # invalid hex digest length
        "X234" * 16,  # invalid hex char
        expected_sri[:-1],  # invalid SRI base64
    ]

    for invalid_integrity in invalid_integrities:
        err = Integrity.new(invalid_integrity, _fail = Mock.fail)
        asserts.true(env, err.startswith("Invalid integrity"))

    return unittest.end(env)

new_test = unittest.make(_new_impl)

TEST_SUITE_NAME = "lib/integrity"

TEST_SUITE_TESTS = dict(
    digest_base64_to_hex = digest_base64_to_hex_test,
    digest_hex_to_base64 = digest_hex_to_base64_test,
    is_valid = is_valid_test,
    new = new_test,
)

test_suite = lambda: _test_suite(TEST_SUITE_NAME, TEST_SUITE_TESTS)
