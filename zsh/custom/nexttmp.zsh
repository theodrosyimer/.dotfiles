function nextjs() {
 pnpm create next-app $1 --app --typescript --tailwind --eslint --use-pnpm --src-dir
}

# Usage: create-next-app <project-directory> [options]

###################################
# CLI Options for create-next-app #
###################################
#
# Options:
#   -V, --version
#     output the version number
#
#   --ts, --typescript
#     Initialize as a TypeScript project. (default)
#
#   --js, --javascript
#     Initialize as a JavaScript project.
#
#   --tailwind
#     Initialize with Tailwind CSS config. (default)
#
#   --eslint
#     Initialize with ESLint config.
#
#   --app
#     Initialize as an App Router project.
#
#   --src-dir
#     Initialize inside a `src/` directory.
#
#   --import-alias <alias-to-configure>
#     Specify import alias to use (default "@/*").
#
#   --use-npm
#     Explicitly tell the CLI to bootstrap the app using npm
#
#   --use-pnpm
#     Explicitly tell the CLI to bootstrap the app using pnpm
#
#   --use-yarn
#     Explicitly tell the CLI to bootstrap the app using Yarn
#
#   -e, --example [name]|[github-url]
#     An example to bootstrap the app with. You can use an example name
#     from the official Next.js repo or a GitHub URL. The URL can use
#     any branch and/or subdirectory
#
#   --example-path <path-to-example>
#     In a rare case, your GitHub URL might contain a branch name with
#     a slash (e.g. bug/fix-1) and the path to the example (e.g. foo/bar).
#     In this case, you must specify the path to the example separately:
#     --example-path foo/bar
#
#   --reset-preferences
#     Explicitly tell the CLI to reset any stored preferences
#
#   -h, --help
#     output usage information

