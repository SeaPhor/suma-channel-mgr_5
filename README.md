# suma5

In 2017 I was asked to give a presentation and speech at SUSECon-2017 based on the process and execution for automating Patch LifeCycle Management through this scripted portable, scaleable, and automate-able set of commands and API calls on SUSE-Manager. I was not able to attend due to an employer conflict, but, it was an honor just to be asked.

Lifecycle-Management
- According to "SUSE Manager Best Practices" and "Advanced Patch Lifecycle Management with SUSE Manager" [By Jeff Price, SUSE] ... "SUSE provided channels should NEVER be assigned to managed systems. One reason is that you do not have control over when the content is updated and made available." [Chapter 5-1 of the Administration guide for SUSE Manager and is also in the 2 titles mentioned above.]
- - EXAMPLE => Patch Non-Production one week/month to test the patches prior to implementing to Production, and then patch the Production the following week/month => packages will be different and test in Non-Production will be invalid.

- There are 2 ways to accomplish this, 
- - 1 => Manually in WebUI with some manual CLI as well <= NOT Discussed in this writing
- - 2 => Use my script, or create your own, to automate this entire process.

- - My Automation Script
- - - Requirements-
- - - - Package => "spacewalk-utils" (in the repository for SUSE Manager)
- - - - - This will give you the "spacewalk-manage-channel-lifecycle" command used in my script.
- - - - - Upon the first run of the script it will check for this package and offer to install it for you if it not installed.
- - - - Source File for Local credentials and custom additions.
- - - - - Upon the first run of the script it will check for this file and offer to create it for you if it does not exist.

- - - Script Actions
- - - - First Run (Every run will check and verify)
- - - - - Check for a "credentials" file to be sourced, and offer to create it if not present.
- - - - - Source the "credentials" file
- - - - - Check for the "spacewalk-utils" package and offer to install it for you if it not installed.
- - - - - Check for the "~/.mgr-sync" file and create and populate it if not present
- - - - - Refresh and sync all SUSE Channel Trees using the "mgr-sync -s refresh" and the "spacewalk-repo-sync" commands.
- - - - - Check for the "dev-..." channel tree to determine first-run or not
- - - - - - Run the "spacewalk-manage-channel-lifecycle" command with the "--init" option in the first-run only, it uses the "--promote" thereafter.
- - - - - - - This will clone the SUSE Channel Tree/s into "dev-..." trees as in "sles12-sp3-pool-x86_64" => "dev-sles12-sp3-pool-x86_64" and all child channels accordingly.
- - - - - - If not present it will create an "Activation Key" for each "dev-..." pool.
- - - - - - If not present it will create a "Bootstrap Script" with it's activation key for each "dev-..." pool.
- - - - - Check for the "test-..." channel tree to determine first-run or not
- - - - - - Run the "spacewalk-manage-channel-lifecycle" command with the "--promote" option.
- - - - - - - This will Promote (clone) the "dev-..." Channel Trees into "test-..." as in "dev-sles12-sp3-pool-x86_64" => "test-sles12-sp3-pool-x86_64" and all child channels accordingly.
- - - - - - If not present it will create an "Activation Key" for each "test-..." pool.
- - - - - - If not present it will create a "Bootstrap Script" with it's activation key for each "test-..." pool.
- - - - - - - This will Promote (clone) the "test-..." Channel Trees into "prod-..." as in "test-sles12-sp3-pool-x86_64" => "prod-sles12-sp3-pool-x86_64" and all child channels accordingly.
- - - - - - If not present it will create an "Activation Key" for each "prod-..." pool.
- - - - - - If not present it will create a "Bootstrap Script" with it's activation key for each "prod-..." pool.
- - - - - Run any Custom functions added to the "credentials" file- NOTE => this function call needs to be manually created and called either in the "credentials" file or in the script itself.
- - - - - Email the named recipient with the results.
- - - - All logging is done in '~/reposync.log'
- - - - The script and the "credentials" file are located in '~/bin/'
- - - - The first-run will not run them out of sequence- they must be run i order- -b, -d, then -p

- - - - All runs after the first run will require no user interaction and can be put into cron-job/s.

APPENDIX A Lifecycle-Management
Here's how I manage mine-
- First Monday of every Month at 1am, 3am, 5am =>
- [-b], [-d], [-p]
- Every Monday at 1am =>
- - [-b] <= This channel is exclusively used for our PCI and other Compliance clients that MUST be kept patched at least Every Month with the Latest available packages.
- We patch Non-Production PCI and other Compliance clients on a Monday, and then their Production counterparts on the following Thursday, allowing 3 days for OS and Application/s testing.
- NON-Compliance clients are patched Quarterly, by groups, 1 group per month with the Non-Prod done in the first week of the month and the Production done in the third or fourth week of the month.

