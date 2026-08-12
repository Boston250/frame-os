# Module convention

Each module will contain `domain`, `application`, `infrastructure`, and `ui` folders as needed. Domain code cannot import the web framework, database client, or another module's infrastructure. Cross-module behavior goes through public application services.
