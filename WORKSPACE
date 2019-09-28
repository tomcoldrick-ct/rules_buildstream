workspace(name = "rules_buildstream")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@rules_buildstream//buildstream:rules.bzl", "bst_element")


local_repository(
     name = "bazel_toolchains_fdsdk",
     path = "/home/christopherphang/Documents/bazel-toolchains-fdsdk",
)

#git_repository(
#    name = "bazel_toolchains_fdsdk",
#    commit = "a9dd423fb26f732d9f809441a721d3d695ced8a9",
#    remote = "https://gitlab.com/CodethinkLabs/bazel-resources/bazel-toolchains-fdsdk.git",
#)

bst_element(
    name = "fdsdk",
    build_file = "@bazel_toolchains_fdsdk//:BUILD",
    repository = "@bazel_toolchains_fdsdk",
    element = "toolchain-complete-x86_64.bst",
)
