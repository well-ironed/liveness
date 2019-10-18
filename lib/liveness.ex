defmodule Liveness do
  @moduledoc """
  `Liveness` offers the `eventually` higher-order function, which can be used
  to specify liveness properties, or to busy-wait for a particular condition.
  """

  defexception [:message]

  @doc """
  Runs `f` repeatedly until `f` succeeds or the number of `tries` is
  reached.

  Particular runs are separated in time by an interval of `interval`
  milliseconds. The interval period begins when the function begins
  execution. This means that if execution takes longer than `interval`
  milliseconds, the next try will be attempted immediately after `f` returns.

  A function is deemed to have failed if it returns `false` or `nil` (a falsy
  value), or if it crashes (exits, raises, or `:erlang.error`s out).

  If the function returns successfully, its return value becomes the value of
  the call to `eventually`.

  If the function returns a falsy value (`false` or `nil`) upon the last try,
  then the `Liveness` exception is raised.

  If the function raises an exception upon the last try, this exception is
  re-raised by `eventually` with the *original* stacktrace.

  """

  def eventually(f, tries \\ 250, interval \\ 20) do
    eventually(f, tries, interval, %RuntimeError{}, nil)
  end

  defp eventually(_, 0, _, last_exception, last_stacktrace) do
    case last_stacktrace do
      nil -> raise(last_exception)
      stacktrace -> reraise_or_exit(last_exception, stacktrace)
    end
  end

  defp eventually(f, tries, interval, _, _) do
    started_at = System.os_time(:millisecond)

    try do
      case f.() do
        x when is_nil(x) or false == x ->
          sleep_remaining(started_at, interval)
          exception = %__MODULE__{message: "function returned #{inspect(x)}"}
          eventually(f, tries - 1, interval, exception, nil)

        other ->
          other
      end
    rescue
      e in __MODULE__ ->
        reraise e, __STACKTRACE__

      exception ->
        sleep_remaining(started_at, interval)
        eventually(f, tries - 1, interval, exception, __STACKTRACE__)
    catch
      class, reason ->
        sleep_remaining(started_at, interval)
        eventually(f, tries - 1, interval, {class, reason}, __STACKTRACE__)
    end
  end

  defp sleep_remaining(started_at, interval) do
    case interval - (System.os_time(:millisecond) - started_at) do
      remaining when remaining > 0 -> Process.sleep(remaining)
      _other -> :noop
    end
  end

  defp reraise_or_exit({class, reason}, stacktrace) do
    :erlang.raise(class, reason, stacktrace)
  end

  defp reraise_or_exit(exception, stacktrace) do
    reraise(exception, stacktrace)
  end
end
