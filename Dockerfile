FROM ruby:2.6.0-rc1-alpine3.8

RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "rackup", "-p", "2000", "-o", "0.0.0.0"]
