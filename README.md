# Stoat

Stoat is a little CLI based helper that assists the New Relic Ruby agent team
with various chores related to releasing new gem versions.

![A stoat with a white winter coat in the snow](./stoat.jpg)


## Installation

- Clone the repo
- Run `bin/setup` to install dependencies
- Run `gem build`
- Run `gem install --local stoat`


## Setup

To perform GitHub based operations, you will need to obtain a personal access
token for dedicated New Relic usage. To create a new token, head to
[https://github.com/settings/tokens](https://github.com/settings/tokens) and
create a token with the 'repo' and 'workflow' scopes (only).

Once you have created a personal access token, set it as the value for the
`NR_GITHUB_TOKEN` environment variable:

```shell
export NR_GITHUB_TOKEN=f0x_AnDb@dg3rG0outF0r@4unTt0g3th3RT0n1ght
```


## Usage

After installation, the executable `stoat` binary should be in your PATH.

Run `stoat`, `stoat -h` or `stoat --help` for usage information.

The following subcommands are offered:

- `stoat coverage`: Fetch and view the latest combined code coverage artifact
- `stoat gemfile --path /path/to/app`: Update an app's Bundler and Papers files
- `stoat perf`: Fetch and evaluate the latest perf tests artifact


## Development

- Clone the repo
- Run `bin/setup` to install dependencies
- Run `bundle exec rake` to run the tests and linter
- Open `coverage/index.html` to view code coverage results
