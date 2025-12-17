# Custom Mage AI Dockerfile with pre-installed requirements
FROM mageai/mageai:latest

# Set working directory
WORKDIR /home/mage

# Copy requirements file
COPY requirements.txt /home/mage/requirements.txt

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache \
    pip install -r requirements.txt
    
# Set timezone to Asia/Jakarta (as per user preference)
ENV TZ=Asia/Jakarta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create necessary directories
RUN mkdir -p /home/mage/data /home/mage/mage_ai/pipelines
