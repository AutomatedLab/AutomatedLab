# Contributing
Your help is greatly appreciated! This project, as all other open-source projects, thrives through an active community. But: With great power comes great responsibility. So we have devised a few ground rules that should be followed when contributing.

## How can you contribute?
There are a couple of ways you can help us out.
* [Issues](#Issues): The easiest way to contribute is to identify that something is broken or that a feature is missing and create an issue from it. Even better would be fixing an open issue that has no assignee yet. You can of course do both - find something that is missing and fix it yourself!
* [Reviews](#Reviews): With more contributions coming in we will likely see more pull requests. Reviewing them is not always the most fun, but it is very necessary and would help a lot.
* [Documentation](#Documentation): Documentation is probably most people's least favorite item on the agenda. However, we need good docs. If you have a great scenario you would like to document, or if you would like to update an existing document, this would be awesome.

## Issues
### Standard issues
Opening issues is very easy. Head to our [Issues tab](https://github.com/automatedlab/automatedlab/issues) and open one if it does not exist already. If an issue exists that might have something to do with yours, e.g. is the basis for something your are requesting, please link this issue to yours.  
### Bugs, errors and catastrophies
If you encounter an error during a lab setup, there are some basic details we need to be able to help you.
1. The script you used. Feel free to strip out any incriminating details, but it must be able to be executed.
2. The verbose and error output of the script! Either set `$VerbosePreference = 'Continue'` or use the verbose switch for Install-Lab.
1. If possible, the result of `New-PSFSupportPackage -Include All`.
### Fixing an issue
Fixing issues also does not require a lot of administrative work. The basic steps are:
1. Leave a comment to tell us that you are working on it.
2. Fork our repository, and base your changes off of the 'develop' branch. Please create a new branch from develop which contains your changes. How you call it? We don't care.
3. Fix the issue! No biggie...
4. For good measure, check for any changes to the repo:
    ```powershell
    git remote add upstream https://github.com/automatedlab/automatedlab
    git fetch upstream
    # If there are changes, pull and work on merge conflicts
    git pull --rebase upstream develop
    ```
4. Make sure you have pushed your commits to your new branch and then create a pull request.
5. Sit back and wait for us to take credit for your code - just kidding. All the fame and glory is yours.

## Reviews
We are using GitHub's internal capabilites for our code reviews. Either we, the AutomatedLab team, or you, the community, can review the changes and add comments. The author of the pull request can then go through all issues, fix them and add commits to his branch, which will show up in the pull request. When all issues are fixed and there is nothing else to do, we will gladly merge your pull request.

## Documentation
We are using readthedocs.io and mkdocs to generate our documentation, so any document you want to look for should be in the `Help` directory. The cmdlet help is
grouped by module, and there is a dedicated folder for the Wiki content. Especially Wiki content is always very welcome. All content is visible on <https://automatedlab.org>.

The process is the same as fixing an [Issue](#Issues). Check out a new branch in your fork, update the docs, send us a PR. After it is merged, you
can immediately see the changes on automatedlab.org, if you select the current docs branch. This should be selected by default.