# BucStop-Goofin

![BucStop Logo](/Bucstop%20WebApp/BucStop/wwwroot/Logo.png)

## Overview

BucStop-Goofin is a modern microservices-based gaming platform developed as part of the Software Engineering II course. <br>This platform features classic arcade games (Snake, Tetris, and Pong) with a clean, responsive UI and a scalable architecture designed for cloud deployment.

[▶️ Watch the BucStop-Goofin Intro & Demo Video](https://vimeo.com/1079595088/f69404c8a6?ts=0&share=copy)



## Architecture

The application is built using a microservices architecture with the following components:

- **WebApp**: Main frontend service that handles user authentication, game selection, and user interface
- **API Gateway**: Orchestrates communication between the WebApp and game microservices
- **Game Microservices**: Independent services for each game (Snake, Tetris, Pong, BucKart)

![Architecture Diagram](/Documentation/CookedGraph.png)

## Technologies

- **Backend**: ASP.NET Core 
- **Frontend**: HTML5, CSS3, JavaScript
- **Containerization**: Docker, docker-compose
- **Deployment**: AWS EC2
- **Logging**: Serilog
- **CI/CD**: GitHub Actions


## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop)
- [docker-compose](https://www.geeksforgeeks.org/devops/installation-of-docker-compose/) - for running BucStop on instance
- [.NET 6 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) (for development only)
- [Git](https://git-scm.com/downloads)

### Local Development (with containerization)

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/BucStop-Goofin.git
   cd BucStop-Goofin
   ```

2. Start all services using Docker Compose:
   ```bash
   docker-compose up
   ```

3. Access the application:
   - WebApp: http://localhost:8080
   - API Gateway: http://localhost:8081
   - Snake: http://localhost:8082
   - Pong: http://localhost:8083
   - Tetris: http://localhost:8084
   - BucKart: http://localhost:8085

### Local Development Without Docker

While Docker Compose manages service discovery and networking between containers, Visual Studio provides a powerful <br> alternative for development that will probably be more familiar for students through its multiple project startup feature.

#### Using Visual Studio

1. Open the solution file `BucStop.sln` in Visual Studio.

2. Configure multiple startup projects:
   - Right-click on the Solution in Solution Explorer and select "add existing project"
   - Select the `csproj` file for each other service.
	 - Right click solution and select "configure multi-project startup".
   - Set the following projects to "Start" - use this specific order:
     - `APIGateway`
     - `Snake`
     - `Pong`
     - `Tetris`
     - `BucKart`
     - `BucStop` (WebApp)
   - Click "OK" to save the configuration

3. Press F5 or click the "Start" button to run all projects simultaneously.

Visual Studio automatically handles:
- Starting each project on a different port
- Configuring the correct environment variables
- Launching debug sessions for each project



## Deployment to AWS

### Setting Up AWS Resources

1. Create an AWS account if you don't have one
2. Create a new EC2 instance:
   - Recommended: t2.micro (or larger for production)
   - Amazon Linux or Ubuntu Server - if using Ubuntu, some commands may be different (ex: ec2-init.sh assumes Amazon Linux / RHEL system)
   - Configure security group to allow inbound traffic on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS), 8080 (WebApp), 8081 (Gateway), 8082-8085 (Games)

3. Connect to your EC2 instance:
	
   **Option 1: SSH Connection**
   ```bash
   ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-IP
   ```
   
   **Option 2: AWS Console**
   - Go to the AWS EC2 Console
   - Select your EC2 instance
   - Click "Connect" button at the top of the page
   - Choose the "EC2 Instance Connect" tab
   - Click "Connect" to access the browser-based terminal

4. Install required software packages by running [EC2-init.sh](/Scripts/ec2_init.sh):
   - **See note above under "Setting Up AWS Resources - #2"**
   - Using this script assumes Amazon Linux or other RHEL-like system.

6. Clone the repository and start the services:
   ```bash
   git clone https://github.com/<your-repo>/BucStop.git
   cd BucStop
   docker-compose up
   ```
7. Pruning Docker
   - For any issues encountered with Docker, best is to completely prune the system with `docker system prune`.
   - Note that this deletes all images, containers, volumes, and networks that Docker is using.

### Environment Configuration

The application supports multiple environments through configuration files:

- `appsettings.containersLocal.json`: Local Docker container settings
- `appsettings.containers.json`: Production container settings
- `appsettings.Development.json`: Local development settings (deprecated - consider removing)
- `appsettings.Production.json`: Production settings (deprecated - consider removing)

- When deploying to production, use the appropriate environment variable (consider persisting environment variable<br> by adding it to `.bashrc` or `/etc/profile`):

```bash
env=containers docker-compose up -d
```

alternatively, edit the .json files, changing the DOTNET ENVIRONMENT variable.

- When deploying to production, pay attention to IP addresses used. Should match AWS external IP address for your instance.
	- Recommended to use an elastic IP on the BucStop instance
 	- Recommended to add this IP to each `containers.json` file in the `Team-3-*` folders.

## Project Structure

```
BucStop-Goofin/
├── Bucstop WebApp/            # Main web application
│   └── BucStop/
│       ├── Controllers/       # MVC controllers
│       ├── Views/             # UI templates
│       ├── Models/            # Data models
│       ├── Services/          # Business logic
│       └── MicroServices/     # Service communication
├── Team-3-BucStop_APIGateway/ # API Gateway service
├── Team-3-BucStop_Snake/      # Snake game microservice
├── Team-3-BucStop_Tetris/     # Tetris game microservice
├── Team-3-BucStop_Pong/       # Pong game microservice
├── Team-3-BucStop_BucKart/       # Pong game microservice
├── Documentation/             # Project documentation
└── docker-compose.yml         # Container orchestration
```

## Contributing

1. Clone the repository 
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Common Issues

1. **Services not connecting properly**:
   - Ensure all services are running (`docker ps`)
   - Check if the API Gateway is configured with correct service URLs
   - Verify network connectivity between containers

2. **Game not loading**:
   - Check browser console for JavaScript errors
   - Verify that the game's microservice is running
   - Check API Gateway logs for routing issues

### Logs

All services use Serilog for structured logging:

```bash
# View logs for all containers
docker-compose logs

# View logs for a specific service
docker-compose logs bucstop
docker-compose logs api-gateway
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

* Original BucStop project that served as foundation from previous semesters
* All contributors to the project from the most recent semester:
	- @Christopher-Powers, @ChristopherOaks (other Chris), @Brofessortec, @nixonrs-bucs, @CurtisReece, @minknd, @Ismaelizzy, @Zach1204 
* Software Engineering II course instructor, Professor Kinser
