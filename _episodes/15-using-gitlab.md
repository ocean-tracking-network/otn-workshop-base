---
title: Using Gitlab for Project Management
teaching: 15
exercises: 0
questions:
- "What is the difference between GitHub and GitLab?"
- "Why does OTN use both GitHub and GitLab for project management?"
---

At OTN, we use both GitHub and GitLab to manage our repositories. Both services implement Git, the version-control software, but GitHub repositories are publicly viewable, while GitLab gives the option to control access to project information and repository contents. This allows us to maintain privacy on projects that are not ready for public release, or that may have sensitive data or information included in their code. GitLab also (at time of writing) has a more robust set of continuous integration/testing tools, which are useful for ensuring the continued integrity of some of OTN's core projects and data pipelines.

GitLab provides a broad range of versioning control functionality through its web interface; however, technical explanations of how to use them are beyond the scope of this document. This lesson is more about why we at OTN use GitLab and where it fits in our processes. GitLab maintains its own comprehensive documentation, however. If you have used any Git-derived service before, many of the concepts will be familiar to you. Here are a few links to relevant documentation: 
- [Creating a Project](https://docs.gitlab.com/ee/user/project/)
- [Opening Merge Requests](https://docs.gitlab.com/ee/user/project/merge_requests/index.html)
- [Working with Issues](https://docs.gitlab.com/ee/user/project/issues/index.html)

Why use both GitHub and GitLab? There are several reasons, chief among them that GitLab provides more robust access control for private repositories. In the course of OTN's work, it is not uncommon to have code that we need to work on or even distribute, but not make entirely public. A good example are the iPython Utilities notebooks that we and our node managers use to upload data into our database. Node Managers outside of OTN need to be able to use and potentially modify these notebooks, but we don't wish for them to be publicly available, since they may contain code that we don't want anyone oustide of the node network to run. We therefore want to keep the repository private in macro, but allow specific users to pull the repository and use it. GitHub only allows private repositories for free users to have a maximum of three collaborators, whereas GitLab imposes no such limits. This makes GitLab the preferred option for code that needs to remain private. We do sometimes migrate code from GitLab to our GitHub page when we are ready for the code to be more public, as with resonATe. In other words, we use GitHub and GitLab at different stages of the software development process depending on who needs access. 

At the time of writing, GitLab also has a different approach to automated CI/CD and testing than GitHub. GitHub's recent feature, GitHub Actions, allows for a range of automated processes that can influence both the code base and a project's online GitHub portal. GitLab's CI/CD automation focuses more on testing and deploying code, and is currently more robust and established than Actions. This situation may change with time. 

In a more general sense, we use both GitHub and GitLab because having familiarity with both platforms allows us to future-proof ourselves against one or the other changing with short notice. Absent any consideration of features and appropriateness for a given project, the nature of GitHub and its corporate ownership means that it can change very quickly, possibly in ways that make it unsustainable for our needs. Likewise, GitLab is open-core, and may introduce new features from community developers that are not desirable for certain projects. Using both at this stage and developing familiarity along both axes means that we can migrate projects to and from each as appropriate. It also ensures that the dev team is used to working in multiple environments, in case we need to introduce or adopt different version-control services in the future.


