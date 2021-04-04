# svencoop-dedicated-server

## Purpose

Provide an easy method to create a Sven Coop dedicated server rapidly and repeatably.

## Usage

### Build and Run

```bash
docker build -t v54io/svencoop-dedicated-server svencoop-dedicated-server/
docker run -d -it \
  -p 27016:27016/tcp \
  -p 27016:27016/udp \
  -p 26900:26900/udp \
  --name svencoop-dedicated-server \
  v54io/svencoop-dedicated-server
```

### Connecting

The `Sven Coop` server should appear under the `LAN` tab in the server browser, or you can use `connect localhost:27016` to connect directly from the in-game console.