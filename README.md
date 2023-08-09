# OTN's Workshop Curriculum Base
Telemetry workshop materials created by OTN, to be curated and taught to future groups.

## Cloning/Remixing OTN Workshop Base

First, you will need to create a copy of the repository. We do this by forking the repository. 

*How to fork a repo:*

1. Go to the otn-workshop-base repository homepage

2. In the top right-hand of the page (just under the profile picture), click the 'Fork' button (between "Unwatch" and "Star").

3. Make sure the 'Owner' is set to 'ocean-tracking-network.'

4. Give the repo a meaningful name. Typical format is yyyy-organization-subject-workshop, where yyyy is the year the workshop is taking place, organization is the audience to whom we're giving it, and subject is the course material we're teaching.

5. Provide a useful description.

6. Click Create Fork.

Once the fork is created, you will need to follow a few short steps to get the site up and running.

*How to stand up the website:*

1. In your new fork's repo site, go to the "Settings" tab (it's just under the 'Unwatch' button next to the 'Fork' button).

2. In the left sidebar of that page, click the 'Pages' tab.

3. Under the 'Source' section, set the source branch to gh-pages (the folder will default to /(root), this is fine). Click 'Save'. This step will happen automatically when you push a commit to gh-pages, but it's fine to do it manually too.

4. The site will now be published at the link on this page (in the highlighted box at the top of the settings). Note that it may take a while for the site to be visible, depending on your caching settings. Give it about 15 minutes.

If something goes wrong with the site build, you’ll receive an e-mail at the address associated with the GitHub account that owns the new repository. In this case, contact a developer to see that the error gets fixed. 

From here there are two branches with which you need to be concerned if you are building a workshop: `master` and `gh-pages`. ‘Master’ contains all of the R code for the lessons. If you want to make changes to the code, work with master as your base. Gh-pages is the branch that controls the display of the workshop website. If you want to change lesson content, work with gh-pages as your base. 

Note that while master contains the code itself, lessons in gh-pages contain references to, and snippets of, the code. Gh-pages will NOT be updated if you update the code in master- it is your responsibility to make sure that any changes you make to the code in master are reflected in gh-pages’ lesson text. 

You are also free to add or delete lessons from your branch as befits the workshop you are giving; however, note that if you do this, you WILL need to renumber the remaining lessons so that their titles feature sequential numbers. If you do not do this, the links between lessons will be broken. 

Lessons are written in Markdown so be sure that your formatting is correct. Additional Markdown guidance can be found [here](https://www.markdownguide.org/cheat-sheet/). 
 
You can find these instructions and more at the [OTW Wiki page](https://github.com/ocean-tracking-network/otn-workshop-base/wiki).

