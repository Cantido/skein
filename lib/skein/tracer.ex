defmodule Skein.Tracer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{outbound_references: %{}, inbound_references: %{}}}
  end

  def trace({:alias_reference, _meta, module}, env) do
    count_reference(env, module)
  end

  def trace({:remote_function, _meta, module, _name, _arity}, env) do
    count_reference(env, module)
  end

  def trace(_event, _env) do
    :ok
  end

  defp count_reference(%Macro.Env{} = from_env, to_module) do
    # IO.puts("counting reference from #{from_env.module} to #{to_module}")
    if should_count?(from_env, to_module) do
      :ok = GenServer.call(__MODULE__, {:count_reference, from_env.module, to_module})
    end

    :ok
  end

  defp should_count?(from_env, to_module) do
    from_env.module != to_module
  end

  def report(app) do
    case GenServer.call(__MODULE__, :report) do
      {:ok, trace} ->
        Application.load(app)
        app_mods = Application.spec(app, :modules) || []

        view = Boundary.view(app)

        app_mods
        |> Enum.uniq()
        |> Enum.reject(&function_exported?(&1, :__impl__, 1))
        |> Enum.filter(&String.starts_with?(Atom.to_string(&1), "Elixir."))
        |> Enum.reject(fn module ->
          is_nil(Boundary.for_module(view, module))
        end)
        |> Enum.reduce(%{}, fn module, report ->
          boundary = Boundary.for_module(view, module)

          boundary_inbound_reference_count =
            Map.get(trace.inbound_references, module, [])
            |> Enum.reject(fn inbound_reference_module ->
              from_boundary = Boundary.for_module(view, inbound_reference_module)
              is_nil(from_boundary) or boundary.name == from_boundary.name
            end)
            |> Enum.count()

          boundary_outbound_reference_count =
            Map.get(trace.outbound_references, module, [])
            |> Enum.reject(fn outbound_reference_module ->
              to_boundary = Boundary.for_module(view, outbound_reference_module)

              is_nil(to_boundary) or boundary.name == to_boundary.name
            end)
            |> Enum.count()

          is_abstract = is_module_abstract?(module)

          report =
            Map.put_new(
              report,
              boundary.name,
              %{
                abstract_modules: 0,
                module_count: 0,
                afferent_coupling: 0,
                efferent_coupling: 0
              }
            )

          Map.update!(
            report,
            boundary.name,
            fn boundary_report ->
              boundary_report
              |> Map.update!(:abstract_modules, &(&1 + if is_abstract, do: 1, else: 0))
              |> Map.update!(:module_count, &(&1 + 1))
              |> Map.update!(:afferent_coupling, &(&1 + boundary_inbound_reference_count))
              |> Map.update!(:efferent_coupling, &(&1 + boundary_outbound_reference_count))
            end
          )
        end)
        |> Enum.map(fn {boundary, report} ->
          afferent = report.afferent_coupling
          efferent = report.efferent_coupling

          denominator = afferent + efferent
          instability = if denominator == 0, do: 0.0, else: efferent / denominator

          abstractness =
            if report.module_count == 0 do
              0
            else
              report.abstract_modules / report.module_count
            end

          d = abs(abstractness + instability - 1)

          stats = %{
            afferent_coupling: afferent,
            efferent_coupling: efferent,
            instability: instability,
            abstractness: abstractness,
            distance_from_main_sequence: d
          }

          {boundary, stats}
        end)
        |> then(&{:ok, &1})
      err ->
        err
    end
  end

  defp is_module_abstract?(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        Enum.any?(docs, fn
          {:attribute, _, :behaviour, _} -> true
          {:attribute, _, :protocol, _} -> true
          _ -> false
        end)

      _ ->
        false
    end
  end

  def handle_call(:report, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:count_reference, from_module, to_module}, _from, state) do
    outbound_references = Map.update(state.outbound_references, from_module, [to_module], &[to_module | &1])
    inbound_references = Map.update(state.inbound_references, to_module, [from_module], &[from_module | &1])

    state = %{state | outbound_references: outbound_references, inbound_references: inbound_references}

    {:reply, :ok, state}
  end
end
