FROM debian:buster
RUN apt update && \
      apt install -y curl jq && \
      curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
      chmod +x ./kubectl && \
      mv ./kubectl /usr/local/bin/kubectl

ADD delete-pods.sh /usr/local/bin/delete-pods.sh
RUN chmod +x /usr/local/bin/delete-pods.sh

CMD ["delete-pods.sh"]
# CMD kubectl get pods