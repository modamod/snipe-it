FROM gitpod/workspace-mysql

USER gitpod

# Copy required files to /tmp
COPY --chown=gitpod:gitpod .gp/bash/update-composer.sh \
    starter.ini \
    .gp/config/nginx.conf \
    .gp/bash/php.sh \
    .gp/bash/install-core-packages.sh \
    .gp/bash/install-project-packages.sh \
    .gp/bash/update-composer.sh \
    .gp/bash/utils.sh \
    /tmp/

# Create log files and move required files to their proper locations
RUN sudo touch /var/log/workspace-image.log \
    && sudo chmod 666 /var/log/workspace-image.log \
    && sudo touch /var/log/workspace-init.log \
    && sudo chmod 666 /var/log/workspace-init.log \
    && sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf

# Install and configure php and php-fpm as specified in starter.ini
RUN sudo bash -c ". /tmp/php.sh" && rm /tmp/php.sh

# Install core packages for gitpod-laravel-starter
RUN sudo bash -c ". /tmp/install-core-packages.sh" && rm /tmp/install-core-packages.sh

# Install any user specified packages for the project
RUN sudo bash -c ". /tmp/install-project-packages.sh" && rm /tmp/install-project-packages.sh

# Update composer
RUN bash -c ". /tmp/update-composer.sh" && rm /tmp/update-composer.sh
# Force the docker image to build by incrementing this value
ENV INVALIDATE_CACHE=233
