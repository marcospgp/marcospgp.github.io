# marcospereira.me / marcospgp.github.io

Repo for Jekyll based personal website.

Theme documentation [here](PIXYLL.md).

## Deployment

This site is deployed to GitHub Pages, which now relies on GitHub Actions for the deployment workflow.

We use the `jekyll.yml` action and not `jekyll-gh-pages.yml` because we depend on `jekyll-paginate-v2` (see [starter workflows here](https://github.com/actions/starter-workflows/tree/main/pages)).

## Usage

Adding new posts to this repo should update the website automatically, which is
done by a Github action.

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
