.. _merge_conflict:

Dealing With Merge Conflicts
============================

When working with Git and GitHub, sooner or later you're going to get a *merge conflict* - this arises when you and a collaborator want to make different, contradictory changes to the same piece of code, and git's algorithm can't figure out how to sort things out. In this case, a human - you  - need to solve the problem.

To follow this tutorial, it's best to actually have a merge conflict in progress you need to debug. The most common time this happens is after doing a ``git pull`` to fetch new code from an upstream repository.

Merge Conflicts on Your Machine
-------------------------------

1. As noted, you'll probably encounter this problem when pulling code from GitHub that someone else has changed recently:

   .. code:: bash

      ~ $ git pull upstream main

          From https://github.com/BillMills/demo
           * branch            main     -> FETCH_HEAD
          Auto-merging demo.js
          CONFLICT (content): Merge conflict in demo.js
          Automatic merge failed; fix conflicts and then commit the result.

   Git is trying to be helpful with this output:

   - every line marked ``CONFLICT`` indicates a file that has a contradiction in it; in this case, there's just one: ``demo.js``.
   - git is reminding you of what to do in the last line: fix things by hand, and commit.

2. For every file with a reported ``CONFLICT``, open it up in your text editor; you'll see constructions like this:

   .. code:: bash

      <<<<<<< HEAD
      var index = 42
      =======
      var index = 1337
      >>>>>>> 75fa902451bda65e819278ce9edca24b6072328e

   This is git's way of indicating what the conflict is. The code between ``<<<<<<< HEAD`` and ``=======`` is one person's opinion of what the code should be; the code between ``=======`` and ``>>>>>>> 75fa902451bda65e819278ce9edca24b6072328e`` is the other person's opinion. Git tries to merge code automatically and usually succeeds, but it looks like in this case there's a disagreement in what ``index`` should be set to; there's no way git can know the right answer on its own, so you need to help it out. Choose what you think the right version of the code is, delete the wrong or out of date version, and delete the ``>>>>``, ``====`` and ``<<<<`` lines in the code.

   Note that there may be multiple conflicts per file; search for the string ``>>>>`` to make sure you catch them all.

   Repeat this process for every file git mentioned a ``CONFLICT`` for in the first step.

3. Once you've resolved all conflicts, commit the resolution:

   .. code:: bash

      ~ $ git commit -a -m 'fixed conflicts'

Merge Conflicts on GitHub
-------------------------

The other place you may hit merge conflicts is when setting up a PR on GitHub, which will block the merge of the PR. In this case, the easiest fix is to ``git pull`` the branch from the upstream repository into the branch you're working on on your own machine. Then you'll get the error message noted above, and can follow the same steps. Once done, commit the fix, and push to your PR on GitHub. If done correctly, the merge conflict will be resolved and the PR will be unblocked.

*Last reviewed --*