FROM ruby:2.7-alpine
WORKDIR /visualizer_app
RUN apk add --no-cache build-base
RUN gem install sinatra puma
RUN gem install rerun
RUN gem install haml
EXPOSE 5000
#CMD ["puma", "-b", "tcp://0.0.0.0:5000", "-w", "1", "app.rb"]
CMD ["tail", "-f", "/dev/null"]