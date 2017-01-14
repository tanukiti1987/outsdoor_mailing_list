FROM ruby:2.4
MAINTAINER Ryusuke Sekiguchi <tanukiti1987@gmail.com>

RUN gem install bundler

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
EXPOSE 4567
CMD ["bundle", "exec", "rackup", "-p", "4567", "-o", "0.0.0.0"]
