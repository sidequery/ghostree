# Contributing to Ghostree

Thank you for your interest in contributing to Ghostree! We welcome contributions of all kinds: bug reports, feature requests, documentation improvements, and code changes.

## How to Contribute

### Reporting Bugs

- Search [existing issues](https://github.com/sidequery/ghostree/issues) to avoid duplicates.
- Open a new issue with a clear title and detailed description.
- Include steps to reproduce the bug, expected behavior, and actual behavior.
- Include your OS version and the output of `ghostty +version`.

### Suggesting Features

- Open an issue describing the feature and why it would be useful.

### Submitting Changes

1. Fork the repository and create a branch from `main`.
2. Make your changes.
3. Test your changes locally (see [HACKING.md](HACKING.md) for build instructions).
4. Open a pull request with a clear description of what you changed and why.

### Translations

See the [Translator's Guide](po/README_TRANSLATORS.md) for contributing translations.

## Code of Conduct

Be respectful and constructive. We're all here to make Ghostree better.

["contributor friendly"]: https://github.com/ghostty-org/ghostty/issues?q=is%3Aissue%20is%3Aopen%20label%3A%22contributor%20friendly%22

### I'd like to translate Ghostty to my language

We have written a [Translator's Guide](po/README_TRANSLATORS.md) for
everyone interested in contributing translations to Ghostty.
Translations usually do not need to go through the process of issue triage
and you can submit pull requests directly, although please make sure that
our [Style Guide](po/README_TRANSLATORS.md#style-guide) is followed before
submission.

### I have a bug! / Something isn't working

First, search the issue tracker and discussions for similar issues. Tip: also
search for [closed issues] and [discussions] — your issue might have already
been fixed!

> [!NOTE]
>
> If there is an _open_ issue or discussion that matches your problem,
> **please do not comment on it unless you have valuable insight to add**.
>
> GitHub has a very _noisy_ set of default notification settings which
> sends an email to _every participant_ in an issue/discussion every time
> someone adds a comment. Instead, use the handy upvote button for discussions,
> and/or emoji reactions on both discussions and issues, which are a visible
> yet non-disruptive way to show your support.

If your issue hasn't been reported already, open an ["Issue Triage"] discussion
and make sure to fill in the template **completely**. They are vital for
maintainers to figure out important details about your setup.

> [!WARNING]
>
> A _very_ common mistake is to file a bug report either as a Q&A or a Feature
> Request. **Please don't do this.** Otherwise, maintainers would have to ask
> for your system information again manually, and sometimes they will even ask
> you to create a new discussion because of how few detailed information is
> required for other discussion types compared to Issue Triage.
>
> Because of this, please make sure that you _only_ use the "Issue Triage"
> category for reporting bugs — thank you!

[closed issues]: https://github.com/ghostty-org/ghostty/issues?q=is%3Aissue%20state%3Aclosed
[discussions]: https://github.com/ghostty-org/ghostty/discussions?discussions_q=is%3Aclosed
["Issue Triage"]: https://github.com/ghostty-org/ghostty/discussions/new?category=issue-triage

### I have an idea for a feature

Like bug reports, first search through both issues and discussions and try to
find if your feature has already been requested. Otherwise, open a discussion
in the ["Feature Requests, Ideas"] category.

["Feature Requests, Ideas"]: https://github.com/ghostty-org/ghostty/discussions/new?category=feature-requests-ideas

### I've implemented a feature

1. If there is an issue for the feature, open a pull request straight away.
2. If there is no issue, open a discussion and link to your branch.
3. If you want to live dangerously, open a pull request and
   [hope for the best](#pull-requests-implement-an-issue).

### I have a question which is neither a bug report nor a feature request

Open an [Q&A discussion], or join our [Discord Server] and ask away in the
`#help` forum channel.

Do not use the `#terminals` or `#development` channels to ask for help —
those are for general discussion about terminals and Ghostty development
respectively. If you do ask a question there, you will be redirected to
`#help` instead.

> [!NOTE]
> If your question is about a missing feature, please open a discussion under
> the ["Feature Requests, Ideas"] category. If Ghostty is behaving
> unexpectedly, use the ["Issue Triage"] category.
>
> The "Q&A" category is strictly for other kinds of discussions and do not
> require detailed information unlike the two other categories, meaning that
> maintainers would have to spend the extra effort to ask for basic information
> if you submit a bug report under this category.
>
> Therefore, please **pay attention to the category** before opening
> discussions to save us all some time and energy. Thank you!

[Q&A discussion]: https://github.com/ghostty-org/ghostty/discussions/new?category=q-a
[Discord Server]: https://discord.gg/ghostty

## General Patterns

### Issues are Actionable

The Ghostty [issue tracker](https://github.com/ghostty-org/ghostty/issues)
is for _actionable items_.

Unlike some other projects, Ghostty **does not use the issue tracker for
discussion or feature requests**. Instead, we use GitHub
[discussions](https://github.com/ghostty-org/ghostty/discussions) for that.
Once a discussion reaches a point where a well-understood, actionable
item is identified, it is moved to the issue tracker. **This pattern
makes it easier for maintainers or contributors to find issues to work on
since _every issue_ is ready to be worked on.**

If you are experiencing a bug and have clear steps to reproduce it, please
open an issue. If you are experiencing a bug but you are not sure how to
reproduce it or aren't sure if it's a bug, please open a discussion.
If you have an idea for a feature, please open a discussion.

### Pull Requests Implement an Issue

Pull requests should be associated with a previously accepted issue.
**If you open a pull request for something that wasn't previously discussed,**
it may be closed or remain stale for an indefinite period of time. I'm not
saying it will never be accepted, but the odds are stacked against you.

Issues tagged with "feature" represent accepted, well-scoped feature requests.
If you implement an issue tagged with feature as described in the issue, your
pull request will be accepted with a high degree of certainty.

> [!NOTE]
>
> **Pull requests are NOT a place to discuss feature design.** Please do
> not open a WIP pull request to discuss a feature. Instead, use a discussion
> and link to your branch.
>>>>>>> upstream-main
