NAME = inception

#change the path
DATA_DIR = /home/inception/data

all:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	cd srcs && docker compose up --build -d

down:
	cd srcs && docker compose down

clean: down
	cd srcs && docker compose down -v --rmi all

fclean: clean
	docker system prune -af
	sudo rm -rf $(DATA_DIR)/mariadb/*
	sudo rm -rf $(DATA_DIR)/wordpress/*

re: fclean all

.PHONY: all down clean fclean re