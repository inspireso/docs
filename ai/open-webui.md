# open-webui

## install

```bash
mkdir /opt/open-webui
cd /opt/open-webui

cat <<EOF > /opt/open-webui/docker-compose.yaml
services:
  pipelines:
    image: ghcr.io/open-webui/pipelines:main
    restart: always
    ports:
      - "9099:9099"
    volumes:
      - /opt/open-webui/pipelines:/app/pipelines
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    restart: always
    ports:
      - "3000:8080"
    volumes:
      - /opt/open-webui/data:/app/backend/data
    depends_on:
      - pipelines
    environment:
      - VIRTUAL_HOST=aix.fibee.vip
      - VIRTUAL_PORT=3000
      - LETSENCRYPT_HOST=aix.fibee.vip
  watchtower:
    image: containrrr/watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 300 open-webui
    depends_on:
      - open-webui
EOF

docker compose up -d

```
