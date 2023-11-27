# Kuiq - Sidekiq UI

Kuiq (**UI** for Side**kiq**, pronounced "quick") is a native desktop application for Sidekiq administration. It uses the Glimmer toolkit for building native GUIs in Ruby.

Please note this is a prototype and nothing official or usable at the moment.

If you are unfamiliar with Glimmer, you can see a large set of helpful examples by running `gem install glimmer-dsl-libui; glimmer examples`.

## Installation

Stable release (not available yet):

```
gem install kuiq
```

Latest version:

```
git clone git@github.com:mperham/kuiq.git
cd kuiq && bundle
bundle exec bin/kuiq
```

## Usage

You'll need to check out the latest code and run Kuiq manually.
Specify your Redis location with `REDIS_URL`:

```
REDIS_URL=redis://localhost:6379/0 bundle exec bin/kuiq
```