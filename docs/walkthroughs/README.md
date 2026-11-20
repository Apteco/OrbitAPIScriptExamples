# Walkthroughs

Worked examples that combine several scripts to do a bigger job.

| Walkthrough | What it shows |
| --- | --- |
| [Create a modified copy of a dashboard](copy-and-modify-a-dashboard.md) | Run five scripts in an interactive session to copy a dashboard with a text value replaced |
| [Change the tile titles in a dashboard](update-dashboard-tile-titles.md) | Run four scripts in an interactive session to change every tile title in one dashboard |
| [Replace text in all of a user's dashboards](modify-all-user-dashboards.md) | How `ModifyAllUserDashboards.ps1` works |
| [Set the theme for a specific dashboard](set-dashboard-theme.md) | How `SetDashboardTheme.ps1` works |

## Adding a walkthrough

Write it as a Markdown file in this folder with these sections, then list it in `registry.yaml`:

- A one-paragraph introduction under the title
- **Scripts used**: a list linking each script it calls
- **How it works**: the steps, as a numbered list
- **Example session** (for steps you run yourself) or **Example output** (for a script in `Powershell/Workflows`)
- **Notes**, if there's anything else worth knowing

For a script in `Powershell/Workflows`, point its `registry.yaml` entry at the walkthrough with `walkthrough:`. For a walkthrough with no script of its own, add a new entry with `doc:` instead of `script:`.
