use Mix.Config

[
  read_from:              [
    Bunyan.Source.Api,
    Bunyan.Source.ErlangErrorLogger,
  ],
  write_to:               [
    {
      Bunyan.Writer.Device, [
        name:  :stdout_logging,

        main_format_string:        "$time [$level] $remote_info$message_first_line",
        additional_format_string:  "$message_rest\n$extra",

        level_colors:   %{
          @debug => faint(),
          @info  => green(),
          @warn  => yellow(),
          @error => light_red() <> bright(),
        },
        message_colors: %{
          @debug => faint(),
          @info  => reset(),
          @warn  => yellow(),
          @error => light_red(),
        },
        timestamp_color: faint(),
        extra_color:     italic() <> faint(),

        use_ansi_color?: true
      ]
    },
    {
      Bunyan.Writer.Device, [
        name:  :critical_errors,
        device:            "myapp_errors.log",
        pid_file_name:     "myapp.pid",
        rumtime_log_level: :error,
        use_ansi_color?:   false,
      ]
    },
    {
       Bunyan.Writer.Remote, [

          # assumes there's a Bunyan.Source.GlobalReader with
          # `global_name: MyApp.GlobalLogger` running on
          # the given two nodes

          send_to: MyApp.GlobalLogger,
          send_to_nodes:  [
            :"main_logger@192.168.1.2",
            :"backup_logger@192.68.1.2",
          ],
          runtime_log_level: :warn,
      ]
    },
  ]
]