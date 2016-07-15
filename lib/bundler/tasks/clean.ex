defmodule Mix.Tasks.Release.Clean do
  @moduledoc """
  Cleans release artifacts from the current project.

  ## Examples

      # Cleans files associated with the latest release
      mix release.clean

      # Remove all release files
      mix release.clean --implode

      # Remove all release files, and do it without confirmation
      mix release.clean --implode --no-confirm

  """
  @shortdoc "Clean up any release-related files"
  use Mix.Task
  alias Mix.Releases.Logger

  def run(args) do
    Logger.configure(:debug)

    # make sure loadpaths are updated
    Mix.Task.run("loadpaths", [])

    opts = parse_args(args)

    implode? = Keyword.get(opts, :implode, false)
    no_confirm? = Keyword.get(opts, :no_confirm, false)
    cond do
      implode? && no_confirm? ->
        clean_all!
      implode? && confirm_implode? ->
        clean_all!
      :else ->
        clean!
    end
  end

  defp clean_all! do
    Logger.debug "Cleaning all releases.."
    unless File.exists?("rel") do
      Logger.warn "No rel directory found! Nothing to do."
      exit(:normal)
    end
    File.rm_rf!("rel")
    Logger.success "Clean successful!"
  end

  defp clean! do
    # load release configuration
    Logger.debug "Cleaning last release.."

    unless File.exists?("rel/config.exs") do
      Logger.warn "No config file found! Nothing to do."
      exit(:normal)
    end

    config = Mix.Releases.Config.read!("rel/config.exs")
    releases = config.releases
    # build release
    paths = Path.wildcard(Path.join("rel", "*"))
    for release <- releases, Path.join("rel", "#{release.name}") in paths do
      Logger.notice "    Removing release #{release.name}:#{release.version}"
      clean_release(release, Path.join("rel", "#{release.name}"))
    end
    Logger.success "Clean successful!"
  end

  defp clean_release(release, path) do
    # Remove erts
    erts_paths = Path.wildcard(Path.join(path, "erts-*"))
    for erts <- erts_paths do
      File.rm_rf!(erts)
    end
    # Remove lib
    File.rm_rf!(Path.join(path, "lib"))
    # Remove releases/start_erl.data
    File.rm(Path.join([path, "releases", "start_erl.data"]))
    # Remove current release version
    File.rm_rf!(Path.join([path, "releases", "#{release.version}"]))
  end

  defp parse_args(argv) do
    {overrides, _} = OptionParser.parse!(argv, [implode: :boolean, no_confirm: :boolean])
    Keyword.merge([implode: false, no_confirm: false], overrides)
  end

  defp confirm_implode? do
    Bundler.IO.confirm """
    THIS WILL REMOVE ALL RELEASES AND RELATED CONFIGURATION!
    Are you absolutely sure you want to proceed?
    """
  end

end
