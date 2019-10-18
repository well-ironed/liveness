defmodule Liveness do
  defexception [:message]

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
        false ->
          sleep_remaining(started_at, interval)
          exception = %__MODULE__{message: "function returned false"}
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
