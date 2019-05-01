# ScriptRunner

This ain't pretty, but...

ScriptRunner was put together to automate an off-hours deployment process that needed to push multiple T-SQL deployment scripts to multiple servers in a specific order while avoiding Kerberos hop issues. 

This was leveraged in pre-production environments for automatic deployment testing after the environments refreshed each day and then, finally, used to deploy to production early on a Saturday morning.

## Things to know

### GO batch terminators

ScriptRunner attempts to handle GO commands in the T-SQL files by splitting the script using the following regex:

`[regex]::split($command,'\nGO[\t\s]*\r\n')`

I'm not a regex guru by any means and this took me a while to wrap my head around, so let me break down my understanding of this:
- `$command` is the raw text from the sql file
- `\nGO` – the GO must be preceded by a line feed
- `[\t\s]*` - match zero or more of the characters in the brackets
  - `\t` = tab
  - `\s` = space
- `\r\n` – must end with a carriage return and a linefeed

There are cases where this won't handle a GO, but it should handle a GO that was placed on a new line and may or may not have white-space after it before the next new line.

### Dependencies
#### SciptRunnerTasks.csv
ScriptRunner has a dependency on a comma-delimited _SciptRunnerTasks.csv_ file. This file should live in the same folder as the .ps1 file (unless you change the logic inside the .ps1) 

Each row should contain the following:

1. **A task ID** - this will define the order that your scripts are run in. You don't need to put them in order in the .csv - it's just more readable if you do.
2. **A target server name** - this is where the task ID will be executed
3. **A file path** - this is the path to the script that needs to run.

**Example**
```bash
1,Server1,\\path\Script1.sql
2,Server2,\\path\Script2.sql
3,Server3,\\path\Script3.sql
```

#### Permission

As with everything, make sure the account running this has permission to access all of the targets and all of the file locations.

### Output

Datetime stamped .txt files will be generated on each run and output to the same folder as the .ps1 file
