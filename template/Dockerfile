FROM eclipse-temurin:21-jre-jammy

ARG NEOFORGE_VERSION
ENV NEOFORGE_VERSION=${NEOFORGE_VERSION}

WORKDIR /server

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
  && curl -o neoforge-installer.jar \
     "https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar" \
  && java -jar neoforge-installer.jar --installServer \
  && rm neoforge-installer.jar

RUN echo "eula=true" > eula.txt

EXPOSE 25565

CMD ["sh", "run.sh"]