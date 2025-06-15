"""e2e pg_src tests"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@pg_src//:repo.bzl", "REPO_NAME")
load("//:suite.bzl", _examples_suite = "test_suite")

def _repo_name_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "pg_src", REPO_NAME)

    return unittest.end(env)

repo_name_test = unittest.make(_repo_name_impl)

SUITE_NAME = "pg_src"

SUITE = dict(
    repo_name = repo_name_test,
)

examples_suite = lambda: _examples_suite(SUITE_NAME, SUITE)
