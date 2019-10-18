defmodule LivenessTest do
  use ExUnit.Case

  import Liveness

  test "it returns value immediately if fun neither returns false nor raises" do
    assert eventually(fn -> 123 end) == 123
    assert eventually(fn -> :ok end) == :ok
    assert eventually(fn -> "foo" end) == "foo"
  end

  test "it raises an exception if fun returns false" do
    assert_raise Liveness, "function returned false", fn ->
      eventually(fn -> false end, 2, 20)
    end
  end

  test "it raises an exception that fun raises" do
    assert_raise ArgumentError, "this is an argument error", fn ->
      eventually(fn -> raise(ArgumentError, "this is an argument error") end, 2, 20)
    end
  end

  test "it exits if fun exits" do
    assert catch_exit(eventually(fn -> exit("i am exiting") end, 2, 20)) == "i am exiting"
  end

  test "it errors out if fun errors out" do
    assert catch_error(eventually(fn -> :erlang.error("i am erroring out") end, 2, 20)) ==
             %ErlangError{original: "i am erroring out"}
  end

  test "it throws if fun throws" do
    assert catch_throw(eventually(fn -> throw("i am throwing up") end, 2, 20)) ==
             "i am throwing up"
  end

  test "it raises an exception if successful value is returned after retry limit is reached" do
    f = given_function_succeeding_from_attempt_no(3, :ok, fn -> raise "oops" end)

    assert_raise RuntimeError, "oops", fn -> eventually(f, 2, 20) end
  end

  test "it returns value if successful value is returned before retry limit is reached" do
    f = given_function_succeeding_from_attempt_no(3, :ok, fn -> raise "oops" end)
    assert eventually(f, 3, 20) == :ok
  end

  test "it waits for retry interval between tries" do
    f = given_function_succeeding_from_attempt_no(3, :ok, fn -> raise "oops" end)
    assert {time_us, :ok} = :timer.tc(fn -> eventually(f, 3, 500) end)
    assert time_us >= 1_000_000 and time_us < 1_500_000
  end

  test "it does include function execution time in the retry interval" do
    failure_fun = fn ->
      Process.sleep(500)
      raise "oops"
    end

    f = given_function_succeeding_from_attempt_no(4, :ok, failure_fun)

    assert {time_us, :ok} = :timer.tc(fn -> eventually(f, 4, 500) end)
    assert time_us >= 1_500_000 and time_us < 2_000_000
  end

  defp given_function_succeeding_from_attempt_no(n, success, failure_fun) do
    {:ok, agent} = Agent.start_link(fn -> {1, n} end)

    fn ->
      f =
        Agent.get_and_update(agent, fn {called, n} ->
          f =
            case called >= n do
              true -> fn -> success end
              false -> failure_fun
            end

          {f, {called + 1, n}}
        end)

      f.()
    end
  end
end
