# ElixirMintZendesk

Reproduce a HTTP2 error when hitting the zendesk api.

## Build

```elixir
mix escript.build
```

## Running
./elixir_mint_zendesk

## What Happens

ConnectionProcess is sent a Mint.HTTPError immediately after the first request.
It is picked up on handle_info and writen to an emergency log.

The original pid is no longer useable at that point.
