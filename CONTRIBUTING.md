# Contributing

New scripts and walkthroughs are welcome, whether you work at Apteco, at a partner, or at a company that uses Orbit. Each one also gets a page in the Orbit API cookbook on the Apteco Help Hub, with you credited as the author.

Have a question, or an idea you'd like to talk through first? [Open an issue](https://github.com/Apteco/OrbitAPIScriptExamples/issues).

## Get a copy to work on

If you work at Apteco, clone the repository and create a branch for your change.

If you don't, [fork the repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo), which gives you your own copy on GitHub, and make your change on a branch there. You can either:

- clone your fork and work on your own computer, or
- work in your browser on GitHub, without installing anything. In your fork, select **Add file** to add a script, or open a file and select the pencil icon to edit it.

## Add a script

1. Put it in the folder for its area, such as `Powershell/Dashboards` or `Powershell/Connect`. A script that runs other scripts goes in `Powershell/Workflows`.
2. Start it with comment-based help: a one-line `.SYNOPSIS`, a `.DESCRIPTION`, a `.PARAMETER` for each parameter, and at least one `.EXAMPLE`. The Help Hub builds the script's page from this help, and uses `.SYNOPSIS` as its introduction.
3. Follow the pattern of the existing scripts. Take `-BaseUrl`, `-DataViewName`, and `-AccessToken` as parameters, and expect the token to come from `Login.ps1`.
4. Add the script to the tables in the [README](README.md).
5. Add an entry for it to [registry.yaml](registry.yaml), and add yourself to `authors` there. The comments at the top of that file explain each field.

For a script in `Powershell/Workflows`, also add a walkthrough that explains how it works. See [docs/walkthroughs](docs/walkthroughs/README.md).

## Keep it safe to share

This repository is public. Before you open a pull request, check that nothing in it, including example output, contains:

- a real hostname, URL, or system name. Use `example.com` and `holidays`.
- a real username. Use `myuser`.
- a password, access token, or API key
- customer data

## Test it

Run the script against a test system, not a live one, and check that its `.EXAMPLE` works. If the script changes or deletes anything, say so in its `.DESCRIPTION`.

## Open a pull request

Open a pull request into `main`. If you worked in a fork, see [creating a pull request from a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork).

Keep each pull request to one script or walkthrough, and in its description say:

- what the script does, and why it's useful
- how you tested it, including the Orbit version you tested against

We review every pull request, but can't promise to merge every one. Once yours is merged, your script appears on the Help Hub the next time the cookbook is updated.

## Report a security problem

If you find a security problem in one of the scripts, don't report it in a public issue. [Contact Apteco support](https://portal.apteco.com/contact-support) instead.

## Licence

By contributing, you agree that your contribution is licensed under the [Apache License 2.0](LICENSE), like the rest of this repository.
