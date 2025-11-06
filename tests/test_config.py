from app.config import Settings


def test_get_upstream_for_path_longest_prefix():
    s = Settings(
        upstreams={
            "/api": "http://a",
            "/api/v1": "http://v1",
            "/": "http://root",
        }
    )
    # longest match should be "/api/v1"
    assert s.get_upstream_for_path("/api/v1/resource") == ("/api/v1", "http://v1")


def test_resolve_upstream_trims_prefix_and_returns_base_and_path():
    s = Settings(
        upstreams={
            "/api": "http://a",
        }
    )
    base, trimmed = s.resolve_upstream("/api/resource/1")
    assert base == "http://a"
    assert trimmed == "/resource/1"


def test_resolve_upstream_exact_prefix_returns_root_path():
    s = Settings(
        upstreams={
            "/api": "http://a",
        }
    )
    base, trimmed = s.resolve_upstream("/api")
    assert base == "http://a"
    assert trimmed == "/"


def test_resolve_upstream_handles_no_leading_slash_input():
    s = Settings(
        upstreams={
            "/api": "http://a",
        }
    )
    base, trimmed = s.resolve_upstream("api/resource")
    assert base == "http://a"
    assert trimmed == "/resource"


def test_resolve_upstream_empty_prefix_matches_as_default():
    s = Settings(
        upstreams={
            "": "http://default",
            "/test": "http://b",
        }
    )
    base, trimmed = s.resolve_upstream("/some/path")
    assert base == "http://default"
    assert trimmed == "/some/path"


def test_resolve_upstream_prefers_longer_prefix_over_empty_default():
    s = Settings(
        upstreams={
            "": "http://default",
            "/x": "http://x",
        }
    )
    base, trimmed = s.resolve_upstream("/x/hello")
    assert base == "http://x"
    assert trimmed == "/hello"


def test_get_upstream_for_path_returns_none_when_no_match():
    s = Settings(
        upstreams={
            "/other": "http://o",
        }
    )
    assert s.get_upstream_for_path("/foo") is None


def test_resolve_upstream_root_prefix_slash():
    s = Settings(
        upstreams={
            "/": "http://root",
        }
    )
    base, trimmed = s.resolve_upstream("/")
    assert base == "http://root"
    assert trimmed == "/"
