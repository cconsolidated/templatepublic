FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Make build script executable
RUN chmod +x build.sh

# Build the application
RUN ./build.sh

# Start the application
CMD ["npm", "start"]