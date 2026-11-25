# Publication preflight

This policy applies to every contributor, including automated tools. It supplements [CONTRIBUTING.md](../CONTRIBUTING.md), [asset guidance](assets.md), [licensing](../LICENSING.md) and [attribution](../ATTRIBUTION.md). The public repository is the technical source of truth; its requirements and evidence must be independently usable.

## Check before publishing, not just before merging

Every public branch, draft PR, issue, comment, commit, workflow run, log and artifact may disclose information before integration. A later deletion or closed PR does not reliably remove it. Branch protection and CI are integration safeguards, not confidentiality barriers.

Routine public-safe source, tests, documentation and cleared assets can be contributed directly through the normal topic-branch workflow. Do not upload sensitive or uncertain material for the purpose of having it reviewed. Keep it outside the public repository until the maintainer has resolved the concern. Never upload credentials to any project repository.

## Contributor checklist

Before each public write (including intermediate commits and PR discussion), inspect the exact proposed material:

- Verify the destination repository, branch, base and current head; check the intended changed paths and content. Do not import unrelated history, local state or entire directories without inventorying them.
- Remove personal contact details, local account and machine names, identifying absolute paths, private URLs, internal correspondence and unrelated personal circumstances. Use portable paths, synthetic fixtures and neutral technical descriptions. Preserve technical requirements and reproducibility.
- Exclude secrets, access tokens, keys, credential files, private databases and sensitive logs. Inspect configuration, environment examples, command output and error messages; use placeholders, not real values.
- Inspect screenshots, videos, HTML/SVG, embedded data, binaries, generated files and archives for hidden content, metadata and identifiers as well as visible content. Inspect actual rendered output when relevant. Withhold material that cannot be adequately inspected.
- Confirm rights and provenance for new third-party assets, dependencies, adapted code and generated material; retain applicable notices and distinguish inspiration from incorporated work. Do not infer permission from attribution or public availability.
- Check commit messages, author/committer identity and email privacy, filenames, PR descriptions, comments and attachment contents. Use a permitted publication-safe identity; inspect actual commit metadata before updating a public ref where the workflow supports it. Do not publish if the identity is uncertain. Do not include private review records or links in public messages.
- Review the full outgoing commit range, not only the final diff, and verify the public ref and relevant content after publication. Review workflow changes for unexpected data collection, secret exposure, untrusted inputs and excessive permissions.

Use the actual bytes and metadata, not only a generated summary. If an inspection cannot be performed with available tools, withhold the affected material and ask the maintainer. Do not claim a check was performed if it was not.

## When to request prior review

Request maintainer review before publishing material with unresolved privacy, rights or provenance concerns; personal screenshots or logs; externally supplied assets or embedded media; bulk imports or history transfers; new release/distribution bundles; or changes that expose new diagnostic data or external services. Supply a safe description of the concern without posting sensitive contents publicly.

Routine technical work does not require an additional publication approval merely because it changes code or documentation. Existing technical review, licensing, validation and owner-controlled integration rules continue to apply.

## Suspected accidental disclosure

Stop further related publication. Notify the maintainer through a non-public channel with the affected locations, type of exposure and known scope; do not repeat the sensitive content. For exposed credentials, arrange immediate revocation or rotation with their owner. Assess all affected refs, commit history, PRs, logs, artifacts, caches and downstream copies. The maintainer coordinates containment and any necessary platform support or history cleanup. Do not independently rewrite shared history, delete evidence or promise erasure.

## Automated safeguards

Use available secret detection and push protection, and supplement them with local/pre-upload content and metadata checks. Proposed additional safeguards include checking forbidden paths, unexpected binary/archive types, embedded payloads and known identifier patterns, with narrowly reviewed exceptions for legitimate fixtures. Automated checks are incomplete and may run only after publication. A passing scan is not proof of privacy, legal clearance or safe provenance.

This document defines contributor responsibilities; it does not claim that any particular scanner, push protection setting or automated enforcement is installed.
