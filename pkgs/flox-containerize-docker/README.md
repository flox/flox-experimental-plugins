# Build containers on MacOS
```
docker pull ghcr.io/flox/flox
flox init
flox install github:flox/flox-experimental-plugins#flox-containerize-docker
flox install hello
flox activate
flox [t2] ➜  t2 flox containerize-docker
...
on-scripts', '/nix/store/y5j92m9rdgrj4gc95rgi1klyvqbzssiq-flox-activation-scripts', '/nix/store/ix6kisswflpbw0flyfnvy2nxhg1jrqiw-flox-containerize-docker', '/nix/store/yrmqgw0mywci1jq4a73mikl77ghvks9i-hello-2.12.1', '/nix/store/v7mqhprxdmyxj5959wz3896ywdphs1rf-htop-3.3.0', '/nix/store/mbhvwq7cja5dzlxm8wpk0blm0g83f7bk-nss-cacert-3.95', '/nix/store/cqf56fnrl26mh2vkjv72qdsdi9kmk30c-ollama-0.3.8', '/nix/store/4h8ffy5pbhgdhiamkyp4bx2m6ikxzs5q-environment', '/nix/store/395q1d9ip5m6qsrzl3gd9v7xyz1p4ic0-bash-interactive-5.2-p15-man']
Creating layer 100 with customisation...
Adding manifests...
Done.
✨ Container written to 'stdout'
+ engine_output='Loaded image: flox-env-container:qnsq4y1gkm39s6ydj1h4jnwrx861sxmq'
+ docker stop -t 1 flox-builder-L1VzZXJzL3Rv
flox-builder-L1VzZXJzL3Rv
+ set +x
~/flox/t2

used 'docker' and container 'flox-builder-L1VzZXJzL3Rv' to containerize t2

Loaded image: flox-env-container:qnsq4y1gkm39s6ydj1h4jnwrx861sxmq
flox [t2] ➜  t2 docker run --rm -it  flox-env-container:qnsq4y1gkm39s6ydj1h4jnwrx861sxmq hello
```
