FROM public.ecr.aws/lambda/provided:latest

WORKDIR /var/runtime/
COPY bootstrap bootstrap
RUN chmod 755 bootstrap

COPY st2/nix/ /nix/

WORKDIR /var/task/
COPY function.sh function.sh
RUN chmod 755 function.sh

ENTRYPOINT ["/lambda-entrypoint.sh"]
CMD [ "function.handler" ]
