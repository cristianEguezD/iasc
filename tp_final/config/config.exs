use Mix.Config

format = "[$time] [$level] $message $metadata\n"

config :logger,
	backends: [:console, {LoggerFileBackend, :logger_file_backend}],
  compile_time_purge_matching: [
		[level_lower_than: :info]
	]

config :logger, :console,
  format: format,
  metadata: [:mfa, :pid, :registered_name]

config :logger, :logger_file_backend,
	format: format,
  path: "log.log",
  level: :info,
	metadata: [:registered_name, :mfa, :file, :line, :initial_call, :pid]