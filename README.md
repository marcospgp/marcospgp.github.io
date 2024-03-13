# marcospereira.me / marcospgp.github.io

Repo for Jekyll based personal website.

Theme documentation [here](PIXYLL.md).

## Deployment

This project uses a GitHub Action to deploy to GitHub Pages from the master branch.

## Usage

To run the website locally, install Docker and run `docker compose up`.

Remember to restart manually when changing `_config.yml`.

Run `docker compose rm` to delete the container.

### Dependency mismatch

Note that dependency versions may not match exactly with the GitHub Action that generates & deploys the site. This can cause subtle issues, such as:

`{{ post.excerpt | strip_html | truncatewords: 30 }}`

Which locally outputs:

```text
In this post we summarize the math behind deep learning and implement a simple network that achieves 85% accuracy classifying digits from the MNIST dataset. It is assumed that the...
```

And on the deployed site outputs:

```text
In this post we summarize the math behind deep learning and implement a simple network that achieves 85% accuracy classifying digits from the MNIST dataset.
```

## Header ID generation

There is [a custom plugin](/_plugins/header-id-hierarchy.rb) to generate hierarchical IDs for headers.

This is meant to avoid issues when linking to IDs when the document contains duplicate headers (under different parent headers), causing a conflict.

AnchorJS is used to add anchor links in [footer.html](/_includes/footer.html).
