FROM maven AS build-env
COPY . /credentials-manager
WORKDIR /credentials-manager
RUN mvn clean install

FROM openjdk as customjre
RUN apk upgrade --available
RUN apk add --no-cache ca-certificates java-cacerts openssl binutils
RUN jlink \
     --module-path /opt/java/jmods \
     --compress=2 \
     --add-modules jdk.management.agent,java.base,java.logging,java.xml,jdk.unsupported,java.sql,java.naming,java.desktop,java.management,java.security.jgss,java.instrument,java.scripting,jdk.crypto.ec,java.rmi,jdk.httpserver,jdk.security.auth \
     --strip-debug \
     --no-header-files \
     --no-man-pages \
     --ignore-signing-information \
     --output /lib/runtime \
     && rm -rf /lib/apk \
     && rm -rf /lib/runtime/legal \
     && rm -rf /lib/runtime/security \
     && strip --strip-unneeded /lib/runtime/lib/server/libjvm.so \
     && cd /lib/runtime/lib;for i in `ls /lib/runtime/lib | grep -i so | awk '{print $1}'`;do strip --strip-unneeded $i;done \
     && rm -rf /tmp/*

FROM scratch
COPY --from=customjre /lib /lib
COPY --from=customjre /tmp /tmp
COPY --from=build-env /credentials-manager/target /credentials-manager
WORKDIR /credentials-manager
CMD ["/lib/runtime/bin/java", "-jar","/credentials-manager/credentials-manager.jar"]
