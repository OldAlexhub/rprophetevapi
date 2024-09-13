# Use the latest R base image from the rocker project
FROM rocker/r-ver:4.3.0

# Install system dependencies for R, MongoDB, and Prophet
RUN apt-get update && apt-get install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libgit2-dev \
  curl \
  g++ \
  libv8-dev \
  build-essential \
  libprotobuf-dev \
  protobuf-compiler \
  libgmp-dev \
  libudunits2-dev \
  libcairo2-dev \
  libxt-dev \
  && apt-get clean

# Install the R packages needed for your app
RUN R -e "install.packages(c('plumber', 'dplyr', 'mongolite', 'prophet'), repos='http://cran.rstudio.com/')"

# Copy your R API script into the Docker image
COPY app.R /app/app.R

# Set the working directory
WORKDIR /app

# Expose the port where the API will be accessible
EXPOSE 8000

# Run the Plumber API on container startup
CMD ["R", "-e", "pr <- plumber::plumb('app.R'); pr$run(host='0.0.0.0', port=8000)"]





