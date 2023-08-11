---
title: Using Gitlab for Project Management
teaching: 15
exercises: 0
questions:
- "What is the difference between GitHub and GitLab?"
- "How do I use GitLab for version control?"
---

At OTN, we use both GitHub and GitLab to manage our repositories. If you are familiar with GitHub, many of the concepts in GitLab will be easy for you to pick up. Both services implement Git, the version-control software, but GitHub repositories are publicly viewable, while GitLab maintains only allows those with access to see repository contents. This allows you to maintain privacy on projects that are not ready for public release, or that may have sensitive data or information included in their code. GitLab also (at time of writing) has a more robust set of continuous integration/testing tools, which may be useful for your project. 

While GitLab mostly operates through a web interface, a functional knowledge of command-line Git is necessary for such operations as pulling, pushing, branching and merging repositories. Some of the basics will feature in this lesson but be aware that a comprehensive explanation of Git is beyond the scope of this lesson. 

Additionally, while this lesson will give you the fundamentals to stand up and use a repository, GitLab has a range of functionality that is beyond the scope of this lesson. We recommend that you also use the GitLab documentation [here] (https://docs.gitlab.com/ee/) to continue your learning and supplement this lesson.

With these two caveats in mind, we can begin by creating a project. To create a new project, click **Create New** at the top of the left hand sidebar and select **New Project/Repository**. You'll be presented with the option to build a blank project or to start from one of several templates. Templates will create your repository with a few default files that can help you start if you're building towards a specific goal. This lesson assumes you will create a blank project. 

You'll be asked to fill out a few pieces of information about your repository-to-be. When you're done, click the "Create Project" button. 

Alternatively, if you have a local repository out of which you want to create a GitLab repo, you can do that as well. You will need an SSH key for your GitLab account and permissions to create new projects in the repository. More information on the first can be found [here](https://docs.gitlab.com/ee/user/ssh.html#add-an-ssh-key-to-your-gitlab-account). For the second, if you do not already have it, you will need to request permissions from the person managing your organisation's GitLab account. 

Once you have fulfilled these requirements, though, you can push a local collection of folders into GitLab and make a repository out of it. When we push to GitLab, we can choose to use either SSH or HTTPS. SSH is more secure, since it relies on your own personal SSH keys, whereas HTTPS is for simple, password-based Git usage, and is less technical but also less secure. In general, we strongly recommend you use SSH. You can do this by opening your Terminal window and typing the following:
~~~
git push --set-upstream git@gitlab.example.com:namespace/myproject.git master
~~~
{:.language-bash}

This will push with SSH. If you would rather push with HTTPS, you can use the following command:

~~~
git push --set-upstream https://gitlab.example.com/namespace/myproject.git master
~~~
{:.language-bash}

However, as stated above, SSH is preferred. 


