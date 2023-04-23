# Skein

Skein is a tool that calculates various Elixir software metrics, like coupling and instability based on
boundaries established with [Boundary](https://github.com/sasa1977/boundary).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `skein` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:skein, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/skein>.

## Usage

The `skein.metrics` Mix task calculates several codebase metrics.

```sh
mix skein.metrics
```

The following metrics are calculated for each boundary:

- Afferent coupling - the number of references that other boundaries make to this one
- Efferent coupling - the number of references that this boundary makes to others
- Instability - the ratio of efferent coupling to the total number of references
- Abstractness - the ratio of behavior and protocol modules to concrete modules
- Distance from the main sequence - the balance between instability and abstractness

## License

MIT License

Copyright 2023 Rosa Richter

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
