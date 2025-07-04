MAKEFLAGS += --silent
.DEFAULT_GOAL := help

include .env
export $(shell sed 's/=.*//' .env)

help:
	@grep -hE '(^[a-zA-Z0-9 \./_-]+:.*?##.*$$)|(^##)|(^###)|(^####)' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; \
	/^## / {printf "\n \033[1;37m%s\033[0m\n", substr($$0, 4); next}; \
	/^### / {printf " > \033[4;37m%s\033[0m\n", substr($$0, 5); next}; \
	/^#### / {printf "\n\033[0;33m## %s\033[0m\033[2;37m\n", substr($$0, 6); next}; \
	/^[a-zA-Z0-9\-\. ]+:.*?##/ { \
		cmd = $$1; desc = $$2; \
		n = split(cmd, parts, " "); \
		formatted = parts[1]; \
		vislen = length(parts[1]); \
		for (i = 2; i <= n; i++) { \
			alias = parts[i]; \
			formatted = formatted " \033[0;36m(" alias ")\033[0m"; \
			vislen += length(alias) + 3; \
		} \
		padding = 20 - vislen; if (padding < 1) padding = 1; \
		printf " ─ \033[0;32m%s\033[0m%*s \033[0;39m%s\n", formatted, padding, "", desc; \
	} END { print "" }'
#### VPN
start on 1: ## Start the VPN connection
	docker compose up -d
	sleep 2
	echo "\n\033[35mOpen this URL in your browser and log in (ctrl + click):\033[0m\n"
	$(MAKE) print_url

stop off 0: ## Stop the VPN connection
	if docker ps | grep -q 'aws-vpn-client-1'; then \
  		docker compose stop; \
	else \
		echo "VPN is not running!"; \
	fi

restart 2: off on ## Restart VPN connection

status s: ## Check if VPN is running
	status_code=$$(curl -m 1 --write-out %{http_code} --silent --output /dev/null $(HOST_TO_CHECK_VPN_CONECTION)); if [ "$$status_code" -ne 302 ]; then echo "\033[31mVPN is OFF\033[0m"; else echo "\033[32mVPN is ON\033[0m"; fi

#### Docker
build: ## Rebuild the docker container
	docker compose build --no-cache --pull

log l: ## Print out docker logs
	docker logs aws-vpn-client

grep_test:
	docker logs --tail 1 aws-vpn-client

print_url pu: ## Try to print the generated URL
	@URL=$$(docker logs --tail 100 aws-vpn-client-1 | grep -Eo 'https?://[^ ]+' | tail -n 1); \
	echo "\n\033[36m$$URL\033[0m\n"; \
	(xdg-open $$URL 2>/dev/null || open $$URL 2>/dev/null || start $$URL 2>/dev/null) &
