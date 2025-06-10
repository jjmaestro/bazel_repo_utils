"utils.bzl unit tests"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:utils.bzl", Utils = "utils")
load("//tests:mock.bzl", Mock = "mock")
load("//tests:suite.bzl", _test_suite = "test_suite")

def _get_dupes__no_dupes_impl(ctx):
    env = unittest.begin(ctx)

    values = [1, 2, 3]
    res = Utils.get_dupes(values)
    asserts.equals(env, [], res)

    return unittest.end(env)

get_dupes__no_dupes_test = unittest.make(_get_dupes__no_dupes_impl)

def _get_dupes__dupes_impl(ctx):
    env = unittest.begin(ctx)

    values = [1, 2, 3, 1]
    res = Utils.get_dupes(values)
    asserts.equals(env, [1], res)

    return unittest.end(env)

get_dupes__dupes_test = unittest.make(_get_dupes__dupes_impl)

def _replace_in_place__missing_key_impl(ctx):
    env = unittest.begin(ctx)

    d = dict(foo = "foo", bar = "bar")
    replacement = dict(foo = "FOO", foobar = "FOOBAR")

    res = Utils.replace_in_place(d, "foobar", replacement, _fail = Mock.fail)
    asserts.true(env, res.startswith("Key to replace not found"))

    return unittest.end(env)

replace_in_place__missing_key_test = unittest.make(_replace_in_place__missing_key_impl)

def _replace_in_place__valid_key_impl(ctx):
    env = unittest.begin(ctx)

    d = dict(foo = "foo", bar = "bar")
    replacement = dict(FOO = "FOO", FOOBAR = "FOOBAR")

    res = Utils.replace_in_place(d, "foo", replacement)
    asserts.equals(env, ["FOO", "FOOBAR", "bar"], res.keys())
    asserts.equals(env, ["FOO", "FOOBAR", "bar"], res.values())

    return unittest.end(env)

replace_in_place__valid_key_test = unittest.make(_replace_in_place__valid_key_impl)

TEST_SUITE_NAME = "lib/utils"

TEST_SUITE_TESTS = {
    "get_dupes/dupes": get_dupes__dupes_test,
    "get_dupes/no_dupes": get_dupes__no_dupes_test,
    "replace_in_place/missing_key": replace_in_place__missing_key_test,
    "replace_in_place/valid_key": replace_in_place__valid_key_test,
}

test_suite = lambda: _test_suite(TEST_SUITE_NAME, TEST_SUITE_TESTS)
