.. _branches:

Using Branches
==============

In our discussion about collaborating on code in :ref:`prs`, we just stuck to the default *branches* in our repos for simplicity. This is fine if you're working on just one thing at a time - but what if you have more than one idea you're pursuing at once? This is what *branching* is meant to accommodate in git.

To follow this tutorial, you should be comfortable with everything we did in :ref:`prs`.

Creating and Managing Branches
------------------------------

Suppose you're working on some API improvements, but it's a big project and you expect you'll have to work on something else before you're completely done. You're going to want to be able to switch between these trains of thought, so each will need its own branch; start by setting one up for your API work:

1. From your project directory on your machine, go back to the main branch of the project, called ``main`` in most Argovis projects, and make sure you're up to date with the upstream repos:

   .. code:: bash

      argovisNg $ git checkout main
      argovisNg $ git pull upstream main

2. Make a branch named ``api`` for your API feature work:

   .. code:: bash

      argovisNg $ git checkout -b api

   From this point, you are on the ``api`` branch. Doing ``git commit`` will add commits to this branch instead of ``main``. To set up pull requests, do exactly what you did in :ref:`prs`, but using ``api`` (or whatever you named your branch) instead of ``main``. So for example, ``git push origin api`` will send your ``api`` branch up to GitHub, and when clicking through setting up your pull request, you'll want to select ``api`` as the originating branch from your repo, and ``main`` as the target branch in the upstream repo.

3. Now suppose you're half way through your API work, when someone reports a critical bug somewhere else in the same repo! You need to drop what you're doing and fix the bug, but you don't want your API work and the bugfix to get tied up together; remember from :ref:`prs`, you want each of your PRs to focus on only one thing, so you'll have to make a new branch for your bugfix.

   ALWAYS start by going back to the main branch first! It is almost never a good idea to make a feature branch off of another feature branch; this leads to confusion and misery.

   .. code:: bash

      argovisNg $ git checkout main
      argovisNg $ git pull upstream main
      argovisNg $ git checkout -b bugfix

   We now have (at least) three branches: the ``main`` version of the code, our API work on the ``api`` branch, and an new branch ``bugfix`` where we'll add commits fixing the bug. If you're ever confused, do ``git branch`` with no arguments, and git will list branches and indicate which one you're currently on. You can switch between existing branches with ``git checkout <branchname>``.

.. admonition:: Seriously

   Seriously - don't forget to ``git checkout main`` right before making a new branch with ``git checkout -b``. Git will happily let you make a branch from whatever branch you want since it isn't technically wrong and there are some extremely rare cases where you might want to, but almost always this is not what you want and will lead to problems.

*Last reviewed --*