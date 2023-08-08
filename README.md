# OTN's Workshop Curriculum Base
Telemetry workshop materials created by OTN, to be curated and taught to future groups.

## Cloning/Remixing OTN Workshop Base

First, you will need to create a copy of the repository. We do this with the GitHub importer. This lets us create a version of the workshop content that is untethered from the base template and will neither 
influence, nor be influenced by, the ton-workshop-base repository. 

1. Go to the Github importer here: https://github.com/new/import.
2. The first field asks for your ‘old’ repository’s clone URL. Go to the OTN Workshop Base repo (https://github.com/ocean-tracking-network/otn-workshop-base/tree/master), click the green “CODE” button, and 
select ‘HTTPS’. Then, copy the URL and paste it into the field on the import page. The URL will end in ‘.git’. If it doesn’t, make sure you copied it properly. 
3. Select the organization that will own the repository. In general you will want this to be ocean-tracking-network. 
4. Give the workshop repository a name. The standard so far is to date it and say who the workshop is for (I.e, 2022-fact-workshop). More detail can be provided at your discretion, but not less. 
5. Leave the repo visibility as “public.” 
6. Click ‘Begin Import’. The import will take a few minutes. 
7. When the import finishes, it will give you a link to your new repository. 

When you import the repository, Github will automatically generate a Pages site out of the gh-pages branch. This is how we build websites in the Carpentries style for each workshop. Github WILL do this 
automatically, you do not need to do anything. It may take some time for Github to build and deploy the site. If something goes wrong with this process, you’ll receive an e-mail at the address associated with 
the GitHub account that owns the new repository. In this case, contact a developer to see that the error gets fixed. 

From here there are two branches with which you need to be concerned if you are building a workshop: master and gh-pages. ‘Master’ contains all of the R code for the lessons. If you want to make changes to 
the code, work with master as your base. Gh-pages is the branch that controls the display of the workshop website. If you want to change lesson content, work with gh-pages at your base. 

Note that while master contains the code itself, lessons in gh-pages contain references to, and snippets of, the code. Gh-pages will NOT be updated if you update the code in master- it is your responsibility 
to make sure that any changes you make to the code in master are reflected in gh-pages’ lesson text. 

You are also free to add or delete lessons from your branch as befits the workshop you are giving; however, note that if you do this, you WILL need to renumber the remaining lessons so that their titles 
feature sequential numbers. If you do not do this, the links between lessons will be broken. 

Lessons are written in Markdown so be sure that your formatting is correct. Additional Markdown guidance can be found [here](https://www.markdownguide.org/cheat-sheet/). 


