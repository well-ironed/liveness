# Liveness [![CircleCI](https://circleci.com/gh/well-ironed/liveness.svg?style=svg)](https://circleci.com/gh/well-ironed/liveness)

A declarative busy wait.


## Use in tests

Use this library to assert on liveness properties of a system.  A typical use case is
waiting for some asynchronous process to finish in the background before
the assertion can be checked.

An example of this might be writing data to an eventually consistent store and
then waiting for a read operation to return the same data.

```elixir

assert eventually(fn -> {:ok, "expected_result"} == SUT.read() end)

```

## Use in applications

You can also use this library to set up a synchronization point in your code.
The wrapped expression will be re-run multiple times, either until the
condition succeeds or the maximum number of retries is reached (which causes an
exception to be raised). This way you can be certain that the specified
condition holds after `eventually` returns.

An example of this might be calling an external resource that we expect to fail
intermittently (sigh).

```elixir

credentials = XYZ.fresh_credentials()
user_id = eventually(fn -> FlakyUserService.register_user!(credentials) end)
proceed_with(user_id)

```

## Semantics

The call to `eventually` will succeed if the passed function returns some value
other than `false` within the provided number of retries.  Otherwise, it will
either raise a `Liveness` exception or reraise the last exception raised by the
function.

By default, `eventually` will attempt to execute the function 250 times, every
20 milliseconds. Both parameters can be altered by passing them to
`eventually`.

So, this:
```elixir
eventually(fn -> ... end)
```

Is equivalent to this:
```elixir
eventually(fn -> ... end, 250, 20)
```

## Installation

The library is [available on hex.pm](https://hex.pm/packages/liveness). You can
use it in your project by adding it to dependencies:


```elixir
defp deps() do
  [
    {:liveness, "~> 1.0.0"}
  ]
end
```

## License

This library is licensed under the [MIT License](LICENSE).
