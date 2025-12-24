FROM ibmjava:8-jre-alpine

# Install required packages
RUN apk add --no-cache bash curl unzip netcat-openbsd

# Create minecraft user and directory
RUN addgroup -g 1000 minecraft && \
    adduser -D -s /bin/bash -u 1000 -G minecraft minecraft

# Set working directory for initial setup
WORKDIR /tekkit-setup

# Download and extract Tekkit Classic server
RUN curl -L -o tekkit.zip "https://servers.technicpack.net/Technic/servers/tekkit/Tekkit_Server_3.1.2.zip" && \
    unzip tekkit.zip && \
    rm tekkit.zip && \
    chmod +x *.jar || true

# Create admin scripts (as root, then we'll set ownership later)
RUN mkdir -p /usr/local/bin

# Health check script
RUN echo '#!/bin/bash' > /usr/local/bin/mc-health && \
    echo 'if ! pgrep -f "java.*Tekkit.jar" > /dev/null; then exit 1; fi' >> /usr/local/bin/mc-health && \
    echo 'if ! nc -z localhost 25565; then exit 1; fi' >> /usr/local/bin/mc-health && \
    chmod +x /usr/local/bin/mc-health

# Console access script  
RUN echo '#!/bin/bash' > /usr/local/bin/mc-console && \
    echo 'echo "Console access: $*"' >> /usr/local/bin/mc-console && \
    chmod +x /usr/local/bin/mc-console

# Op player script
RUN echo '#!/bin/bash' > /usr/local/bin/mc-op && \
    echo 'echo "op $1" # Would send to server console"' >> /usr/local/bin/mc-op && \
    chmod +x /usr/local/bin/mc-op

# Configuration generator script
RUN echo '#!/bin/bash' > /usr/local/bin/generate-config && \
    echo 'cat > /server/server.properties << EOF' >> /usr/local/bin/generate-config && \
    echo 'server-port=${SERVER_PORT:-25565}' >> /usr/local/bin/generate-config && \
    echo 'level-name=world' >> /usr/local/bin/generate-config && \
    echo 'gamemode=${GAMEMODE:-0}' >> /usr/local/bin/generate-config && \
    echo 'difficulty=${DIFFICULTY:-1}' >> /usr/local/bin/generate-config && \
    echo 'level-type=DEFAULT' >> /usr/local/bin/generate-config && \
    echo 'max-players=${MAX_PLAYERS:-20}' >> /usr/local/bin/generate-config && \
    echo 'pvp=${PVP:-true}' >> /usr/local/bin/generate-config && \
    echo 'allow-flight=${ALLOW_FLIGHT:-true}' >> /usr/local/bin/generate-config && \
    echo 'spawn-monsters=true' >> /usr/local/bin/generate-config && \
    echo 'spawn-animals=true' >> /usr/local/bin/generate-config && \
    echo 'spawn-npcs=true' >> /usr/local/bin/generate-config && \
    echo 'generate-structures=true' >> /usr/local/bin/generate-config && \
    echo 'view-distance=${VIEW_DISTANCE:-10}' >> /usr/local/bin/generate-config && \
    echo 'motd=${MOTD:-Tekkit Classic Server}' >> /usr/local/bin/generate-config && \
    echo 'white-list=false' >> /usr/local/bin/generate-config && \
    echo 'online-mode=${ONLINE_MODE:-true}' >> /usr/local/bin/generate-config && \
    echo 'enable-command-block=true' >> /usr/local/bin/generate-config && \
    echo 'EOF' >> /usr/local/bin/generate-config && \
    chmod +x /usr/local/bin/generate-config

# Create EULA acceptance
RUN echo "eula=true" > eula.txt

# Create entrypoint script (keeping your working approach)
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Copy server files if they dont exist (first run)' >> /entrypoint.sh && \
    echo 'if [ ! -f /server/Tekkit.jar ]; then' >> /entrypoint.sh && \
    echo '    echo "First run: copying Tekkit server files..."' >> /entrypoint.sh && \
    echo '    cp -r /tekkit-setup/* /server/' >> /entrypoint.sh && \
    echo '    echo "Server files copied."' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Ensure subdirectories exist with proper permissions' >> /entrypoint.sh && \
    echo 'mkdir -p /server/{world,config,mods,logs,plugins}' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Generate server.properties from environment variables' >> /entrypoint.sh && \
    echo 'generate-config' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Ensure EULA is accepted' >> /entrypoint.sh && \
    echo 'echo "eula=true" > /server/eula.txt' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Change to server directory' >> /entrypoint.sh && \
    echo 'cd /server' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start the server' >> /entrypoint.sh && \
    echo 'exec java -Xmx${JAVA_MEMORY:-2G} -Xms${JAVA_MEMORY:-2G} -jar Tekkit.jar nogui' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set ownership of setup files
RUN chown -R minecraft:minecraft /tekkit-setup

# Create server directory and set ownership (this is key!)
RUN mkdir -p /server && chown -R minecraft:minecraft /server

# Switch to minecraft user
USER minecraft

# Set memory defaults (can be overridden)
ENV JAVA_MEMORY="2G"

# Expose the default Minecraft port
EXPOSE 25565

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
