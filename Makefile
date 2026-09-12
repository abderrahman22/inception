include srcs/.env
export

all: build up

build:
	mkdir -p /home/inception/data/db_data
	mkdir -p /home/inception/data/wp_data
	docker compose -f srcs/docker-compose.yml build

up:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af

fclean: clean
	docker volume rm srcs_db_data srcs_wp_data 2>/dev/null || true
	sudo rm -rf /home/inception/data

re: fclean all

.PHONY: all build up down clean fclean re