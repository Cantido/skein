defmodule Mix.Tasks.Skein.Metrics do
  use Mix.Task
  alias Skein.Tracer


  @impl Mix.Task
  def run(_argv) do
    Tracer.start_link()
    Mix.Task.Compiler.after_compiler(:app, &after_app_compiler(&1))

    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [Tracer | tracers])

    Mix.Task.run("compile", ["--force"])

    :ok
  end

  defp after_app_compiler(outcome) do
    case outcome do
      {status, diagnostics} when status in [:ok, :noop] ->

        app_name = Keyword.fetch!(Mix.Project.config(), :app)

        {:ok, report} = Tracer.report(app_name)

        report
        |> Enum.map(fn {module, stats} ->
          Map.put(stats, :module, module)
        end)
        |> Scribe.print(data: [:module, :instability, :afferent_coupling, :efferent_coupling, :abstractness, :distance_from_main_sequence])

        {:ok, diagnostics}
      other_outcome ->
        other_outcome
    end
  end

end
