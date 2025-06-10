"schema.bzl unit tests"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:schema.bzl", Schema = "schema")
load("//tests:mock.bzl", Mock = "mock")
load("//tests:suite.bzl", _test_suite = "test_suite")

def _mock_index(versions = None, sources = ("src",), version = 1):
    return dict(
        version = version,
        sources = {s: {"url": "https://example.com/foo.tgz"} for s in sources},
        versions = {"1.0": {}} if versions == None else versions,
    )

def _expand_versions__list_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]

    # a list of versions is expanded to a dict of
    # version -> empty version context
    versions = ["1.0"]
    expected = {"1.0": {}}

    res = Schema.__test__._expand_versions(versions, sources)
    asserts.equals(env, expected, res)

    return unittest.end(env)

expand_versions__list_test = unittest.make(_expand_versions__list_impl)

def _expand_versions__single_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]

    # a dict of versions is expanded to a dict of version -> version context
    # where single values are expanded per-source
    versions = {
        "1.0": {
            "property": "foo",
        },
    }
    expected = {
        "1.0": {
            # expanded to source -> value
            "property": {
                "src1": "foo",
                "src2": "foo",
            },
        },
    }

    res = Schema.__test__._expand_versions(versions, sources)
    asserts.equals(env, expected, res)

    return unittest.end(env)

expand_versions__single_test = unittest.make(_expand_versions__single_impl)

def _expand_versions__dict_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]

    # a dict of versions is expanded to a dict of version -> version context
    # where dict values are NOT expanded and left as-is
    versions = {
        "1.0": {
            "property": {
                "src11": "foo",
                "src22": "bar",
            },
        },
    }
    expected = {
        "1.0": {
            # property was a dict so left as-is
            "property": {
                "src11": "foo",
                "src22": "bar",
            },
        },
    }

    res = Schema.__test__._expand_versions(versions, sources)
    asserts.equals(env, expected, res)

    return unittest.end(env)

expand_versions__dict_test = unittest.make(_expand_versions__dict_impl)

def _validate_v1__invalid_keys_impl(ctx):
    env = unittest.begin(ctx)

    # index level mandatory
    index_json = _mock_index()
    index_json.pop("sources")

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, "missing mandatory keys" in res)

    # invalid key
    index_json = _mock_index()
    index_json["foo"] = {}

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, "invalid keys" in res)

    # sources must have url
    index_json = _mock_index()
    index_json["sources"]["src"].pop("url")

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, "missing mandatory keys" in res)

    return unittest.end(env)

validate_v1__invalid_keys_test = unittest.make(_validate_v1__invalid_keys_impl)

def _validate_v1__invalid_version_impl(ctx):
    env = unittest.begin(ctx)

    index_json = _mock_index(version = 9999)

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, "Invalid index version" in res)

    return unittest.end(env)

validate_v1__invalid_version_test = unittest.make(_validate_v1__invalid_version_impl)

def _validate_v1__invalid_versions_empty_impl(ctx):
    env = unittest.begin(ctx)

    index_json = _mock_index(versions = {})

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, "Invalid index, empty 'versions'" in res)

    return unittest.end(env)

validate_v1__invalid_versions_empty_test = unittest.make(_validate_v1__invalid_versions_empty_impl)

def _validate_v1__invalid_versions_slash_impl(ctx):
    env = unittest.begin(ctx)

    index_json = _mock_index(versions = {"foo/bar": {}})

    res = Schema.validate_v1("foo", index_json, _print = Mock.print([]), _fail = Mock.fail)
    asserts.true(env, "invalid version name" in res)

    return unittest.end(env)

validate_v1__invalid_versions_slash_test = unittest.make(_validate_v1__invalid_versions_slash_impl)

def _validate_v1__invalid_versions_reserved_property_impl(ctx):
    env = unittest.begin(ctx)

    for property in Schema.__test__._RESERVED_PROPERTIES:
        index_json = _mock_index(versions = {"foo": {property: "foo"}})

        res = Schema.validate_v1("foo", index_json, _print = Mock.print([]), _fail = Mock.fail)
        asserts.true(env, "invalid version property (reserved)" in res)

    return unittest.end(env)

validate_v1__invalid_versions_reserved_property_test = unittest.make(_validate_v1__invalid_versions_reserved_property_impl)

def _validate_v1__invalid_sources_impl(ctx):
    env = unittest.begin(ctx)

    index_json = _mock_index(sources = ("foo/bar",))

    res = Schema.validate_v1("foo", index_json, _print = Mock.print([]), _fail = Mock.fail)
    asserts.true(env, "invalid source name" in res)

    return unittest.end(env)

validate_v1__invalid_sources_test = unittest.make(_validate_v1__invalid_sources_impl)

def _validate_v1__integrities_invalid_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]

    versions = {
        "1.0": {
            "integrity": {source: "foo" for source in sources},
            "sha256": {source: "foo" for source in sources},
        },
    }
    index_json = _mock_index(versions, sources)

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, res.endswith("use either 'sha256' or 'integrity' but not both"))

    return unittest.end(env)

validate_v1__integrities_invalid_test = unittest.make(_validate_v1__integrities_invalid_impl)

def _validate_v1__integrities_valid_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]
    integrity_sri = "sha256-3q2zP96tsz/erbM/3q2zP96tsz/erbM/3q2zP96tsz8="
    sha256 = "deadb33f" * 8

    versions = {
        "1.0": {
            "integrity": {sources[0]: integrity_sri},
            "sha256": {sources[1]: sha256},
        },
    }
    index_json = _mock_index(versions, sources)

    res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
    asserts.true(env, res.endswith("use either 'sha256' or 'integrity' but not both"))

    return unittest.end(env)

validate_v1__integrities_valid_test = unittest.make(_validate_v1__integrities_valid_impl)

def _validate_v1__integrities_missing_sources_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]
    integrity_sri = "sha256-3q2zP96tsz/erbM/3q2zP96tsz/erbM/3q2zP96tsz8="
    sha256 = "deadb33f" * 8
    integrities = [("integrity", integrity_sri), ("sha256", sha256)]

    for property, value in integrities:
        versions = {
            "1.0": {property: {source: value for source in sources[1:]}},
        }
        index_json = _mock_index(versions, sources)

        prints = []

        Schema.validate_v1("foo", index_json, _print = Mock.print(prints))
        asserts.true(env, 1, len(prints))
        asserts.true(env, "WARNING: missing integrity/sha256 for URL sources" in prints[0])

    return unittest.end(env)

validate_v1__integrities_missing_sources_test = unittest.make(_validate_v1__integrities_missing_sources_impl)

def _validate_v1__integrities_invalid_value_impl(ctx):
    env = unittest.begin(ctx)

    sources = ["src1", "src2"]
    integrity_sri = "sha256-3q2zP96tsz/erbM/3q2zP96tsz/erbM/3q2zP96tsz8="
    sha256 = "deadb33f" * 8
    integrities = [("integrity", integrity_sri), ("sha256", sha256)]

    for property, value in integrities:
        versions = {
            "1.0": {property: {source: value[:-1] for source in sources}},
        }
        index_json = _mock_index(versions, sources)

        res = Schema.validate_v1("foo", index_json, _fail = Mock.fail)
        asserts.true(env, "invalid '{}'".format(property) in res)

    return unittest.end(env)

validate_v1__integrities_invalid_value_test = unittest.make(_validate_v1__integrities_invalid_value_impl)

TEST_SUITE_NAME = "lib/schema"

TEST_SUITE_TESTS = {
    "validate_v1/integrities/invalid": validate_v1__integrities_invalid_test,
    "validate_v1/integrities/invalid_value": validate_v1__integrities_invalid_value_test,
    "validate_v1/integrities/missing_sources": validate_v1__integrities_missing_sources_test,
    "validate_v1/integrities/valid": validate_v1__integrities_valid_test,
    "validate_v1/invalid_keys": validate_v1__invalid_keys_test,
    "validate_v1/invalid_sources": validate_v1__invalid_sources_test,
    "validate_v1/invalid_version": validate_v1__invalid_version_test,
    "validate_v1/invalid_versions/empty": validate_v1__invalid_versions_empty_test,
    "validate_v1/invalid_versions/reserved_property": validate_v1__invalid_versions_reserved_property_test,
    "validate_v1/invalid_versions/slash": validate_v1__invalid_versions_slash_test,
    "_expand_versions/dict": expand_versions__dict_test,
    "_expand_versions/list": expand_versions__list_test,
    "_expand_versions/single": expand_versions__single_test,
}

test_suite = lambda: _test_suite(TEST_SUITE_NAME, TEST_SUITE_TESTS)
