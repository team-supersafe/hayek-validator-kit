# Ubuntu 24.04 CIS Benchmark Audit Automation

This project automates the auditing of Ubuntu 24.04 LTS systems using a collection of custom CIS benchmark scripts. It ensures system compliance by running checks and saving their results in a structured format.

##  Features

- Verifies the system is Ubuntu **24.04 LTS**
- Runs all `.sh` audit scripts under the `script/` directory
- Requires **root privileges** for full access to system settings
- Saves detailed output per script in the `result/` folder
- Captures system info (hostname, timestamp, Ubuntu version)
- Packages all results into a ZIP archive


##  Requirements

- **Ubuntu 24.04 LTS**
- Must run with **root** privileges (`sudo`)
- Bash shell

## ✅ Usage

```bash
sudo ./Ubuntu.sh
```
##  Output
Individual audit results: result/AUDIT_script_name.txt

System info summary: result/System_Info.txt

All outputs zipped: audit_reports.zip

##  Output Result Types
Each script returns one of the following result types:

Result	Description
- PASS	The system meets the CIS benchmark requirement.
- FAIL	The system does not meet the CIS benchmark requirement.
- MANUAL	The check must be verified manually (e.g., requires visual review).
- SKIP	The check is not applicable to this system or intentionally ignored.

##  Customize
Add or edit scripts inside the script/ directory to expand coverage or tailor checks for your environment.

##  Security Note
This tool performs read-only audits and does not apply any changes to the system.

