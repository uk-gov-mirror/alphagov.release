FROM ruby:2.3.4-slim
MAINTAINER "govuk-role-platform-accounts-members@digital.cabinet-office.gov.uk"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      # base dependencies
      ruby-dev build-essential libgmp3-dev libmysqlclient-dev \
      # for bundle exec rake -T and assets commands to work
      nodejs \
      # for healthcheck
      curl

COPY . .

RUN bundle install

#HEALTHCHECK --interval=15s --timeout=3s\
#  CMD curl -f http://localhost:3036/ || exit 1

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3036"]

EXPOSE 3036
