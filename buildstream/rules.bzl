"""Rules for importing buildstream elements into bazel projects"""

def _bst_build(ctx, project):
    bst_options = []
    if ctx.attr.bst_options:
        bst_options += [option for option in ctx.attr.bst_options]

    build_options = []
    if ctx.attr.bst_options:
        build_options += [option for option in ctx.attr.build_options]

    element = ctx.attr.element
    build_args = ["build"] + build_options + [element]

    # Setting use_default_shell_env means bst can be found on the $PATH. Given
    # the myriad ways of installing buildstream which can lead to it being in
    # all sorts of places, this seems sensible as a starting point.
    #
    # There are no output files for a build action.
    ctx.actions.run_shell(
        executable = "bst",
        arguments = bst_options + build_args,
        inputs = ctx.files, # The entire buildstream project
        use_default_shell_env = True,
    )

def _bst_checkout(ctx, project):
    bst_options = []
    if ctx.attr.bst_options:
        bst_options += [option for option in ctx.attr.bst_options]

    checkout_dir = "."
    checkout_options = []
    if ctx.attr.checkout_options:
        checkout_options += [option for option in ctx.attr.checkout_options]

    element = ctx.attr.element
    checkout_args = ["artifact", "checkout", "--directory", "."] + checkout_options + [element]

    # Register that the checkout directory will be an output of the rule
    ctx.actions.declare_directory(checkout_dir)
    # Run bst to generate the contents of this directory
    ctx.actions.run_shell(
        executable = "bst",
        arguments = bst_options + checkout_args,
        inputs = ctx.files, # The entire buildstream project
        use_default_shell_env = True,
    )


def _bst_element_impl(ctx):
    # Note ctx.actions.symlink is experimental and must be enabled using
    # --experimental_allow_unresolved_symlinks
    if ctx.attr.build_file and ctx.attr.build_file_content:
        fail("Specify one of 'build_file' or 'build_file_content', but not both.")
    elif ctx.attr.build_file:
        ctx.actions.symlink(ctx.attr.build_file, "BUILD")
    elif ctx.attr.build_file_content:
        ctx.actions.write("BUILD", content = ctx.attr.build_file_content)
    else:
        ctx.actions.symlink("BUILD", Label("@rules_buildstream//buildstream:BUILD.pkg"))

    # We're assuming there is a single dependency and that it's output is a
    # directory tree containing a single BuildStream project
    input_files = ctx.attr.deps[0][DefaultInfo].files
    project = None
    for f in input_files:
        if f.basename == "project.conf" and not project_path:
            project_path = f.dirname
        elif f.basename == "project.conf" and project_path:
            fail("Found multiple buildstream projects. Only one expected.")
    if not project:
        fail("No buildstream project provided in input")

    _bst_build(ctx, project)
    _bst_checkout(ctx, project)


bst_element = rule(
    implementation = _bst_element_impl,
    attrs = {
        "build_file": attr.label(),
        "build_file_content": attr.string(),
        "repository": attr.label(mandatory = True),
        "build_options": attr.string_list(),
        "checkout_options": attr.string_list(),
        "element": attr.string(mandatory = True),
        "bst_options": attr.string_list(),
    },
)
