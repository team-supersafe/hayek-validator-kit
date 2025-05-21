# Fork into a private repo

In GitHub you cannot fork a public repo and have the destination be a private repo. The GitHub Forking Network is exclusively for public -> public repositories and open source community contributions.

However, we want to be able to accomplish something similar to the public -> public forking, but instead, do it public -> private. This is how:

To do this, follow the steps below:

```bash
# Clone your private repo into your workstation
git clone https://github.com/team-supersafe/hayek-validator-kit-private.git

# Link private repo to remote public one
git remote add public https://github.com/team-supersafe/hayek-validator-kit.git

# Create a merge commit 
# from the public repo's main branch 
# to your local private repo branch
git pull public main
# Push
# from the local private repo branch
# to the remote private repo branch
git push origin main
```

The End
