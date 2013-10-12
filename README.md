# MongoidConnectionPool

If you have ever use Mongoid in a threaded environment such as Sidekiq
with Rubinius or JRuby, you will quickly find out that it is not safe to use Mongoid.

Mongoid by default gives every thread it's own database connection and doesn't
clean up after itself, so these connections remain open.
MongoDB will quickly become overloaded and you will no longer be able to connect.
Often times MongoDB will also likely crash.

This gem monkey patches Mongoid (>= 3.1 < 4.0) to add connection pooling.
We take over how Mongoid handles it's connections, so there is nothing you need
to do to take advantage of it.

This was originally submitted as a PR to the Mongoid project but was turned down
since Moped 2.0(MongoDB database driver used by Mongoid) includes it's own
implementation of connection pooling.
This is all well and good but it is still as of yet to be released, and won't
be supported on Mongoid versions < 4.0 (also unreleased).

This monkey patche passes all of Mongoid's specs.

## Installation

Add this line to your application's Gemfile:

    gem 'mongoid_connection_pool'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid_connection_pool

## Usage

Just require mongoid_connection_pool AFTER Mongoid.  That's it.  Easy-peasy.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
