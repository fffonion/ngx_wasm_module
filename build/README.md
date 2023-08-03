# Bazel project for atc-router


To use in other Bazel projects, add the following to your WORKSPACE file:

```python

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

git_repository(
    name = "ngx_wasm_module",
    branch = "some-tag",
    remote = "https://github.com/Kong/atc-router",
)

load("@ngx_wasm_module//build:repos.bzl", "ngx_wasm_module_repositories")

ngx_wasm_module_repositories()

load("@ngx_wasm_module//build:deps.bzl", "ngx_wasm_module_dependencies")

ngx_wasm_module_dependencies(cargo_home_isolated = False) # use system `$CARGO_HOME` to speed up builds

load("@ngx_wasm_module//build:crates.bzl", "ngx_wasm_module_crates")

ngx_wasm_module_crates()


```

In your rule, add `ngx_wasm_module` as dependency:

```python
configure_make(
    name = "openresty",
    # ...
    deps = [
        "@ngx_wasm_module",
    ],
)
```

When building this library in Bazel, use the `-c opt` flag to ensure optimal performance. The default fastbuild mode produces a less performant binary.
