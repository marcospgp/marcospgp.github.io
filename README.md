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
