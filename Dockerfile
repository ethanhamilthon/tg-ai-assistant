# Dockerfile для Elixir 1.18 приложения

# Этап сборки
FROM elixir:1.18-alpine AS builder

ENV ERL_AFLAGS="+JMsingle true"

# Установка необходимых зависимостей для сборки
RUN apk add --no-cache build-base git

# Установка рабочей директории
WORKDIR /app

# Установка hex и rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Копирование файлов проекта
COPY mix.exs mix.lock ./
COPY config config

# Получение зависимостей
RUN mix deps.clean --all
RUN mix clean
RUN mix deps.get --only prod

# Копирование исходного кода
COPY lib lib

ENV MIX_ENV=prod

# Компиляция проекта
RUN mix compile
RUN mix release --overwrite

# Финальный этап
FROM alpine:3.18

# Установка необходимых пакетов для запуска
RUN apk add --no-cache openssl ncurses-libs libgcc libstdc++ ffmpeg


# Установка рабочей директории
WORKDIR /app

# Копирование релиза из этапа сборки
COPY --from=builder --chown=app:app /app/_build/prod/rel/exas ./

COPY .env.prod .

ENV MIX_ENV=prod
# Запуск приложения
CMD ["bin/exas", "start"]
