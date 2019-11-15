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

def _bst_element_impl(repository_ctx):
    if repository_ctx.attr.build_file and repository_ctx.attr.build_file_content:
        fail("Specify one of 'build_file' or 'build_file_content', but not both.")
    elif repository_ctx.attr.build_file:
        repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD")
    elif repository_ctx.attr.build_file_content:
        repository_ctx.file("BUILD", content = repository_ctx.attr.build_file_content)
    else:
        repository_ctx.template("BUILD", Label("@rules_buildstream//buildstream:BUILD.pkg"))

    _bst_build(repository_ctx)
    _bst_checkout(repository_ctx)

bst_element = repository_rule(
    implementation = _bst_element_impl,
    attrs = {
        "build_file": attr.label(),
        "build_file_content": attr.string(),
        "repository": attr.label(mandatory = True),
        "build_options": attr.string_list(),
        "checkout_options": attr.string_list(),
        "element": attr.string(mandatory = True),
    },
)
