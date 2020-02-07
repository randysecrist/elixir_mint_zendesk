use Mix.Config

config :lager, :colored, true
config :lager, :error_logger_redirect, false

config :lager,
  handlers: [
    lager_console_backend: [
      {:level, :debug},
      {:formatter, :lager_default_formatter},
      {:formatter_config,
       [
         :time,
         " ",
         " [",
         :severity,
         "] [",
         :module,
         ":",
         :line,
         "] ",
         :color,
         :message,
         "\e[0m\r\n"
       ]}
    ],
    lager_file_backend: [
      {:file, 'log/error.log'},
      {:level, :warning},
      {:size, 10_485_760},
      {:date, '$D0'},
      {:count, 5},
      {:formatter, :lager_default_formatter},
      {:formatter_config,
       [
         :time,
         " ",
         " [",
         :severity,
         "] [",
         :module,
         ":",
         :line,
         "] ",
         :color,
         :message,
         "\e[0m\r\n"
       ]}
    ],
    lager_file_backend: [
      {:file, 'log/console.log'},
      {:level, :info},
      {:size, 10_485_760},
      {:date, '$D0'},
      {:count, 5},
      {:formatter, :lager_default_formatter},
      {:formatter_config,
       [
         :time,
         " ",
         " [",
         :severity,
         "] [",
         :module,
         ":",
         :line,
         "] ",
         :color,
         :message,
         "\e[0m\r\n"
       ]}
    ]
  ]

import_config "#{Mix.env()}.exs"
import_config "*local.exs"
