FROM ruby:2.4
MAINTAINER Ryusuke Sekiguchi <tanukiti1987@gmail.com>

RUN gem install bundler
RUN apt-get update -qq && apt-get install -y npm

## Cache bundle install
COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

COPY . /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY app.rb /app/app.rb
COPY config.ru /app/config.ru
RUN bundle -j8
RUN npm install
ENV PATH $PATH:/app/node_modules/.bin
RUN rake assets:precompile

# EXPOSEE does not be recommended by heroku
#EXPOSE 4567
CMD bundle exec rackup -p $PORT -o 0.0.0.0
