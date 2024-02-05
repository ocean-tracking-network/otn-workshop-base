---
title: Introduction to Git for Code
teaching: 45
exercises: 0
questions:
- "What is Git and why should I use it?"
- "How can you use Git for code management?"
- "What is the difference between GitHub and GitLab?"
- "Why does OTN use both GitHub and GitLab for project management?"
---


## Introduction to Git

Git is a common command-line interface software used by developers worldwide to share their work with colleagues and keep their code organized. Teams are not the only ones to benefit from version control: lone researchers can benefit immensely. Keeping a record of what was changed, when, and why is extremely useful for all researchers if they ever need to come back to the project later on (e.g., a year later, when memory has faded).

Version control is the lab notebook of the digital world: it’s what professionals use to keep track of what they’ve done and to collaborate with other people. Every large software development project relies on it, and most programmers use it for their small jobs as well. And it isn’t just for software: books, papers, small data sets, and anything that changes over time or needs to be shared can and should be stored in a version control system.

Git is the version control software and tool, while GitHub is the website where Git folders/code can be shared and edited by collaborators.

This lesson is accompanied by [this Powerpoint presentation.](https://docs.google.com/presentation/d/1WmdewmYbiUJMqYreQxPjLQiTKNAeo7cNZPkQ03CJXNs/edit?usp=sharing)


![PhD Comic](../Resources/phd101212s.png)


### What can Git do for you?

- Archive all your code changes, for safekeeping and posterity
- Share and build code within your group and across the globe

### Why Git is valuable 

Think about Google Docs or similar... but for code and data!
- Version Control 
- Collaboration
- One True Codebase – authoritative copy shared among colleagues
- Documentation of any changes
- Mark and retrieve the exact version you ran from any point in time, even if it's been "overwritten"
- Resolve conflicts when editors change the same piece of content
- Supporting open science, open code, and open data. A requirement for a lot of publications!

![Conflicts](../Resources/conflict.svg)

### Basic commands

Turn my code folder into a Git Repository
1. `git init`
1. `git add .` adds ALL files to Git's tracking index
1. `git commit -m 'add your initial commit message here, describing what this repo will be for'` saves everything that has been "added" to the tracking index. 

You will always need to ADD then COMMIT each new file.

Link your Git Repository to the GitHub website, for storage and collaboration
1. `git remote add origin [url]` telling git the web-location with which to link
1. `git push -u origin master` pushes your work up to the website, in the "master" master!

To add the latest changes to the web-version while you're working you will always have to ADD, then COMMIT, then PUSH the changes.

Clone a Git Repository to your computer to work on it
1. `git clone [paste the url]` 
1. `git pull` to get the newest changes from the web-version at any time!

In summary, you should PULL any new changes to keep your repository synced with the website where other people are working, then ADD/COMMIT/PUSH your changes back to the website for other people to see!


![Git remote Github](../Resources/github-repo-after-first-push.svg)

**As an alternative** - you can use an app like [TortoiseGit (Windows)](https://tortoisegit.org/download/) or [SourceTree (MAC)](https://www.sourcetreeapp.com) to stay away from command line. GitHub also has an app! The commands will be the same (ADD, PUSH, etc.) but you will be able to do them by pushing buttons instead of writing them into a command line terminal.

### Resources

- An excellent introductory lesson is available from [the Carpentries](https://swcarpentry.github.io/git-novice/)
- [Oh shit, git](https://ohshitgit.com/) is a website that helps you troubleshoot Git with plain-language search terms
- NYU has a curriculum for sharing within labs - available [here](https://nyu-cdsc.github.io/learningr/)
- [This article](https://towardsdatascience.com/why-git-and-how-to-use-git-as-a-data-scientist-4fa2d3bdc197) explains why data scientists (us!) should be using Git


### GitHub

GitHub is the website where Git folders/code can be shared and edited by collaborators. This is the "cloud" space for your local code folders, allowing you to share with collaborators easily.


### GitLab

At OTN, we use both GitHub and GitLab to manage our repositories. Both services implement Git, the version-control software, but GitHub repositories are publicly viewable, while GitLab gives the option to control access to project information and repository contents. This allows us to maintain privacy on projects that are not ready for public release, or that may have sensitive data or information included in their code. GitLab also (at time of writing) has a more robust set of continuous integration/testing tools, which are useful for ensuring the continued integrity of some of OTN's core projects and data pipelines.

GitLab provides a broad range of versioning control functionality through its web interface; however, technical explanations of how to use them are beyond the scope of this document. This lesson is more about why we at OTN use GitLab and where it fits in our processes. GitLab maintains its own comprehensive documentation, however. If you have used any Git-derived service before, many of the concepts will be familiar to you. Here are a few links to relevant documentation: 
- [Creating a Project](https://docs.gitlab.com/ee/user/project/)
- [Opening Merge Requests](https://docs.gitlab.com/ee/user/project/merge_requests/index.html)
- [Working with Issues](https://docs.gitlab.com/ee/user/project/issues/index.html)

Why use both GitHub and GitLab? There are several reasons, chief among them that GitLab provides more robust access control for private repositories. In the course of OTN's work, it is not uncommon to have code that we need to work on or even distribute, but not make entirely public. A good example are the iPython Utilities notebooks that we and our node managers use to upload data into our database. Node Managers outside of OTN need to be able to use and potentially modify these notebooks, but we don't wish for them to be publicly available, since they may contain code that we don't want anyone oustide of the node network to run. We therefore want to keep the repository private in macro, but allow specific users to pull the repository and use it. GitHub only allows private repositories for free users to have a maximum of three collaborators, whereas GitLab imposes no such limits. This makes GitLab the preferred option for code that needs to remain private. We do sometimes migrate code from GitLab to our GitHub page when we are ready for the code to be more public, as with resonATe. In other words, we use GitHub and GitLab at different stages of the software development process depending on who needs access. 

At the time of writing, GitLab also has a different approach to automated CI/CD and testing than GitHub. GitHub's recent feature, GitHub Actions, allows for a range of automated processes that can influence both the code base and a project's online GitHub portal. GitLab's CI/CD automation focuses more on testing and deploying code, and is currently more robust and established than Actions. This situation may change with time. 

In a more general sense, we use both GitHub and GitLab because having familiarity with both platforms allows us to future-proof ourselves against one or the other changing with short notice. Absent any consideration of features and appropriateness for a given project, the nature of GitHub and its corporate ownership means that it can change very quickly, possibly in ways that make it unsustainable for our needs. Likewise, GitLab is open-core, and may introduce new features from community developers that are not desirable for certain projects. Using both at this stage and developing familiarity along both axes means that we can migrate projects to and from each as appropriate. It also ensures that the dev team is used to working in multiple environments, in case we need to introduce or adopt different version-control services in the future.
