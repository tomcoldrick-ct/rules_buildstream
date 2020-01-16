"""Rules for importing buildstream elements into bazel projects"""

def _buildstream(repository_ctx):
    bst_path = repository_ctx.which("bst")
    if not bst_path:
        fail("""rules_buildstream requires a working buildstream.
             Please put buildstream in your path""")

    common_args = [bst_path]

    bst_repository = repository_ctx.attr.repository

    # repository_ctx.path only works on files, workaround required to extract dir name
    # https://github.com/bazelbuild/bazel/issues/3901
    project_path = repository_ctx.path(bst_repository.relative(":project.conf")).dirname
    common_args += [
        "--directory",
        project_path,
    ]

    return common_args

def _bst_build(repository_ctx):
    build_args = _buildstream(repository_ctx)
    if repository_ctx.attr.build_options:
        for option in repository_ctx.attr.build_options:
            build_args += [option]

    element = repository_ctx.attr.element
    build_args += [
        "build",
        element,
    ]

    result = repository_ctx.execute(build_args, quiet=False, timeout=3600)
    if result == 256:
        fail("""BuildStream execution timed out.
	     Try populating your local cache""")
    if result != 0:
        fail("""BuildStream build failed""")
    repository_ctx.report_progress("Built buildstream element: {0}".format(element))

def _bst_checkout(repository_ctx):
    checkout_dir = "."
    checkout_args = _buildstream(repository_ctx)
    repository_ctx.file("{0}/emptyfile".format(checkout_dir), "")
    if repository_ctx.attr.checkout_options:
        for option in repository_ctx.attr.checkout_options:
            checkout_args += [option]
    element = repository_ctx.attr.element
    checkout_args += [
        "artifact",
        "checkout",
        "--force",
        element,
        "--directory",
        checkout_dir,
    ]

    result = repository_ctx.execute(checkout_args, quiet=False)
    if result != 0:
        fail("""BuildStream checkout failed""")
    repository_ctx.report_progress("Checked out buildstream element: {0}".format(element))

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
