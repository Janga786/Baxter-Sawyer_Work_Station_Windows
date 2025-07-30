# Baxter Station (for Windows)

This project provides a Dockerized environment to run Baxter Station on a Windows machine.

## Prerequisites

- [Git for Windows](https://git-scm.com/download/win)
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)

## Getting Started

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/Baxter_Station_Windows.git
    cd Baxter_Station_Windows
    ```

2.  **Build and run the application:**
    ```sh
    docker-compose up
    ```

## How to Use

Once the container is running, you can access the application by opening your browser and navigating to [http://localhost:8080](http://localhost:8080).

## Troubleshooting

- **Docker is not running:** Make sure Docker Desktop is running before you execute the `docker-compose up` command.
- **Port conflicts:** If you have another application using port 8080, you can change the port mapping in the `docker-compose.yml` file.
