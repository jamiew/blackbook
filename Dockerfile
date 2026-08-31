# Production image for blackbook, following the layout Rails 8 generates.
#
# Build and run locally to check it before deploying:
#   docker build -t blackbook .
#   docker run --rm -it -e RAILS_MASTER_KEY=$(cat config/master.key) -p 3000:80 blackbook
#
# Deployment is handled by Kamal, see config/deploy.yml.
#
# The Ruby version is pinned to the same string as .ruby-version. There is no
# rbenv and nothing compiles Ruby from source, which is what made provisioning
# on a new Ubuntu release fragile.
ARG RUBY_VERSION=3.4.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Thruster serves assets and terminates HTTP inside the container, so no nginx
# is needed for static files.
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

# ---- build stage -------------------------------------------------------
# Compilers and headers live here only, so none of them reach the final image.
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git pkg-config \
      default-libmysqlclient-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# .ruby-version comes along because the Gemfile reads it while being parsed.
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# SECRET_KEY_BASE_DUMMY lets Propshaft run without the real credentials, which
# never get baked into the image.
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# ---- final stage -------------------------------------------------------
FROM base

# Runtime libraries only. imagemagick is here because kt-paperclip shells out
# to it for every uploaded image.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl imagemagick libvips42 default-mysql-client libjemalloc2 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Non-root, and it owns only what it needs to write at runtime. There is no
# storage/ because this app uses Paperclip rather than Active Storage; data/
# and public/system are bind mounts from the block volume at runtime, and are
# created here so their ownership is right before anything mounts over them.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log tmp data public/system && \
    chown -R rails:rails db log tmp data public/system
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
