load("@rules_rust//rust:defs.bzl", "rust_shared_library", "rust_static_library")

def _impl(settings, attr):
    _ignore = (settings, attr)
    return {"@rules_rust//rust/toolchain/channel": "nightly"}

_platform_transition = transition(
    implementation = _impl,
    inputs = [],
    outputs = ["@rules_rust//rust/toolchain/channel"],
)

# The implementation of transition_rule: all this does is copy the
# rust_binary's output to its own output and propagate its runfiles.
def _transition_rule_impl(ctx):
    actual_binary = ctx.attr.actual_binary[0]
    rust_binary_outfile = actual_binary[DefaultInfo].files.to_list()[0]
    outfile = ctx.actions.declare_file("lib%s.%s" % (ctx.label.name, rust_binary_outfile.extension))
    ctx.actions.run_shell(
        inputs = [rust_binary_outfile],
        outputs = [outfile],
        command = "cp %s %s" % (rust_binary_outfile.path, outfile.path),
    )
    return [DefaultInfo(
        files = depset([outfile]),
        data_runfiles = actual_binary[DefaultInfo].data_runfiles,
    )]

_transition_rule = rule(
    implementation = _transition_rule_impl,
    attrs = {
        # Outgoing edge transition
        "actual_binary": attr.label(cfg = _platform_transition),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def rust_shared_library_nightly(name, visibility, **kwargs):
    binary_name = name + "_nightly"
    _transition_rule(
        name = name,
        actual_binary = ":%s" % binary_name,
    )
    rust_shared_library(
        name = binary_name,
        visibility = visibility,
        **kwargs
    )

def rust_static_library_nightly(name, visibility, **kwargs):
    binary_name = name + "_nightly"
    _transition_rule(
        name = name,
        actual_binary = ":%s" % binary_name,
    )
    rust_static_library(
        name = binary_name,
        visibility = visibility,
        **kwargs
    )
