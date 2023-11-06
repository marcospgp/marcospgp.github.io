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

## Anchors

AnchorJS is used to add anchor links to headers. There is some [custom scripting](https://github.com/marcospgp/marcospgp.github.io/blob/432ed970cd9d8f3739fc9e4c5e4f2535f08fe6f5/_includes/footer.html#L16-L42) that includes parent headers when creating links starting at `h3`.
