# Use a more recent official R base image
FROM rocker/r-ver:4.3.0

# Install system libraries, Node.js, and V8 dependencies
RUN apt-get update && apt-get install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libgit2-dev \
  libv8-dev \
  libnode-dev \
  curl \
  g++ \
  build-essential && \
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  apt-get install -y nodejs

# Ensure Node.js and NPM are installed correctly
RUN npm install -g npm@latest

# Install R packages
RUN R -e "install.packages(c('plumber', 'dplyr', 'mongolite', 'prophet', 'V8', 'Rcpp', 'rlang'))"

# Copy the app files into the Docker image
COPY app.R /app/app.R

# Set working directory
WORKDIR /app

# Expose the port that the API will run on
EXPOSE 8000

# Run the Plumber API
CMD ["R", "-e", "pr <- plumber::plumb('app.R'); pr$run(host='0.0.0.0', port=8000)"]



